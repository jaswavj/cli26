package cheque;

import java.sql.*;
import java.util.*;
import java.text.*;

public class chequeBean {
    
    public chequeBean() {}
    
    // Add new cheque to customer's stock
    public void addCheque(int customerId, String chequeNumber, String bankName, int uid) throws Exception {
        Connection con = null;
        PreparedStatement ps = null;
        
        try {
            con = util.DBConnectionManager.getConnectionFromPool();
            con.setAutoCommit(false); // Start transaction
            
            System.out.println("Adding cheque - CustomerId: " + customerId + ", ChequeNumber: " + chequeNumber);
            
            String sql = "INSERT INTO prod_cheque_stock " +
                        "(customer_id, cheque_number, bank_name, " +
                        "status, entry_date, entry_time, uid) " +
                        "VALUES (?, ?, ?, 'AVAILABLE', CURDATE(), CURTIME(), ?)";
            
            ps = con.prepareStatement(sql);
            ps.setInt(1, customerId);
            ps.setString(2, chequeNumber);
            ps.setString(3, bankName);
            ps.setInt(4, uid);
            
            int rowsAffected = ps.executeUpdate();
            
            if (rowsAffected > 0) {
                con.commit(); // Commit transaction
                System.out.println("Cheque inserted successfully - Rows affected: " + rowsAffected);
            } else {
                con.rollback();
                throw new Exception("No rows inserted - operation failed");
            }
            
        } catch (SQLException e) {
            if (con != null) {
                try {
                    con.rollback();
                    System.err.println("Transaction rolled back due to SQL error");
                } catch (SQLException rollbackEx) {
                    System.err.println("Rollback failed: " + rollbackEx.getMessage());
                }
            }
            System.err.println("SQL Error in addCheque: " + e.getMessage());
            e.printStackTrace();
            throw new Exception("Database error: " + e.getMessage(), e);
        } catch (Exception e) {
            if (con != null) {
                try {
                    con.rollback();
                    System.err.println("Transaction rolled back due to error");
                } catch (SQLException rollbackEx) {
                    System.err.println("Rollback failed: " + rollbackEx.getMessage());
                }
            }
            throw e;
        } finally {
            if (ps != null) try { ps.close(); } catch (SQLException e) { ; }
            if (con != null) {
                try {
                    con.setAutoCommit(true); // Restore default
                } catch (SQLException e) { ; }
                try { 
                    con.close(); 
                } catch (SQLException e) { ; }
            }
        }
    }
    
    // Get available cheques for a customer
    public Vector getAvailableCheques(int customerId) throws Exception {
        Connection con = null;
        PreparedStatement ps = null;
        ResultSet rs = null;
        
        try {
            con = util.DBConnectionManager.getConnectionFromPool();
            Vector cheques = new Vector();
            
            String sql = "SELECT id, cheque_number, status, entry_date " +
                        "FROM prod_cheque_stock " +
                        "WHERE customer_id = ? AND status IN ('AVAILABLE', 'PARTIAL') " +
                        "AND is_active = 1 " +
                        "ORDER BY entry_date ASC, id ASC";
            
            ps = con.prepareStatement(sql);
            ps.setInt(1, customerId);
            rs = ps.executeQuery();
            
            while (rs.next()) {
                Vector row = new Vector();
                row.add(rs.getInt("id"));                      // 0
                row.add(rs.getString("cheque_number"));         // 1
                row.add(rs.getString("status"));                // 2
                row.add(rs.getString("entry_date"));            // 3
                cheques.add(row);
            }
            
            return cheques;
            
        } finally {
            if (rs != null) try { rs.close(); } catch (SQLException e) { ; }
            if (ps != null) try { ps.close(); } catch (SQLException e) { ; }
            if (con != null) try { con.close(); } catch (SQLException e) { ; }
        }
    }
    
    // Allocate available cheques to a credit bill
    public void allocatePendingChequesToBill(int customerId, int billId, double billBalance) throws Exception {
        Connection con = null;
        PreparedStatement selectPS = null;
        PreparedStatement insertPS = null;
        PreparedStatement updatePS = null;
        ResultSet rs = null;
        
        try {
            con = util.DBConnectionManager.getConnectionFromPool();
            con.setAutoCommit(false);
            
            
            // Get available cheques
            String selectSql = "SELECT id FROM prod_cheque_stock " +
                              "WHERE customer_id = ? AND status = 'AVAILABLE' " +
                              "AND is_active = 1 " +
                              "ORDER BY entry_date ASC, id ASC";
            
            selectPS = con.prepareStatement(selectSql);
            selectPS.setInt(1, customerId);
            rs = selectPS.executeQuery();
            
            int uid = 1; // Default user ID
            int allocatedCount = 0;
            
            // Allocate one cheque per credit bill
            if (rs.next()) {
                int chequeId = rs.getInt("id");
                
                
                try {
                    // Insert allocation record with allocated_amount
                    String insertSql = "INSERT INTO prod_cheque_allocation " +
                                      "(cheque_id, bill_id, allocated_amount, allocated_date, allocated_time, " +
                                      "due_date, credit_days, status, uid) " +
                                      "VALUES (?, ?, ?, CURDATE(), CURTIME(), " +
                                      "DATE_ADD(CURDATE(), INTERVAL 10 DAY), 10, 'ALLOCATED', ?)";
                    
                    insertPS = con.prepareStatement(insertSql);
                    insertPS.setInt(1, chequeId);
                    insertPS.setInt(2, billId);
                    insertPS.setDouble(3, billBalance);
                    insertPS.setInt(4, uid);
                    int insertRows = insertPS.executeUpdate();
                    
                    if (insertRows == 0) {
                        System.err.println("ERROR: INSERT failed - no rows inserted!");
                        con.rollback();
                        throw new Exception("Failed to insert allocation record - no rows affected");
                    }
                    
                    insertPS.close();
                    
                    // Update cheque stock status to FULLY_USED
                    String updateSql = "UPDATE prod_cheque_stock " +
                                      "SET status = 'FULLY_USED' " +
                                      "WHERE id = ?";
                    
                    updatePS = con.prepareStatement(updateSql);
                    updatePS.setInt(1, chequeId);
                    int updateRows = updatePS.executeUpdate();
                    
                    if (updateRows == 0) {
                        System.err.println("ERROR: UPDATE failed - no rows updated!");
                        con.rollback();
                        throw new Exception("Failed to update cheque status - no rows affected");
                    }
                    
                    updatePS.close();
                    
                    allocatedCount++;
                } catch (SQLException sqle) {
                    System.err.println("SQL Error during allocation: " + sqle.getMessage());
                    System.err.println("SQL State: " + sqle.getSQLState());
                    System.err.println("Error Code: " + sqle.getErrorCode());
                    con.rollback();
                    throw sqle;
                }
            } else {
                System.out.println("No available cheques found for customer " + customerId);
            }
            
            con.commit();
            System.out.println("Transaction committed - Allocated " + allocatedCount + " cheque(s) for bill " + billId);
            
        } catch (Exception e) {
            if (con != null) try { con.rollback(); } catch (Exception ignore) {}
            System.err.println("Error allocating cheques: " + e.getMessage());
            e.printStackTrace();
            throw e;
        } finally {
            if (rs != null) try { rs.close(); } catch (SQLException e) { ; }
            if (selectPS != null) try { selectPS.close(); } catch (SQLException e) { ; }
            if (insertPS != null) try { insertPS.close(); } catch (SQLException e) { ; }
            if (updatePS != null) try { updatePS.close(); } catch (SQLException e) { ; }
            if (con != null) try { con.close(); } catch (SQLException e) { ; }
        }
    }
    
    // Reverse cheque allocation when payment is made
    public void reverseChequeAllocation(int billId, double paidAmount) throws Exception {
        Connection con = null;
        PreparedStatement selectPS = null;
        PreparedStatement updateAllocPS = null;
        PreparedStatement updateChequePS = null;
        ResultSet rs = null;
        
        try {
            con = util.DBConnectionManager.getConnectionFromPool();
            con.setAutoCommit(false);
            
            // Get allocated cheques for this bill
            String selectSql = "SELECT id, cheque_id " +
                              "FROM prod_cheque_allocation " +
                              "WHERE bill_id = ? AND status = 'ALLOCATED' " +
                              "ORDER BY allocated_date ASC";
            
            selectPS = con.prepareStatement(selectSql);
            selectPS.setInt(1, billId);
            rs = selectPS.executeQuery();
            
            double remainingPaid = paidAmount;
            
            while (rs.next() && remainingPaid > 0) {
                int allocationId = rs.getInt("id");
                int chequeId = rs.getInt("cheque_id");
                
                // Update allocation record
                String updateAllocSql = "UPDATE prod_cheque_allocation " +
                                       "SET status = 'REVERSED', " +
                                       "is_reversed = 1, " +
                                       "reversed_date = CURDATE(), " +
                                       "reversed_time = CURTIME() " +
                                       "WHERE id = ?";
                
                updateAllocPS = con.prepareStatement(updateAllocSql);
                updateAllocPS.setInt(1, allocationId);
                updateAllocPS.executeUpdate();
                updateAllocPS.close();
                
                // Update cheque stock status to AVAILABLE
                String updateChequeSql = "UPDATE prod_cheque_stock " +
                                        "SET status = 'AVAILABLE' " +
                                        "WHERE id = ?";
                
                updateChequePS = con.prepareStatement(updateChequeSql);
                updateChequePS.setInt(1, chequeId);
                updateChequePS.executeUpdate();
                updateChequePS.close();
                
                remainingPaid -= paidAmount;
            }
            
            con.commit();
            
        } catch (Exception e) {
            if (con != null) try { con.rollback(); } catch (Exception ignore) {}
            throw e;
        } finally {
            if (rs != null) try { rs.close(); } catch (SQLException e) { ; }
            if (selectPS != null) try { selectPS.close(); } catch (SQLException e) { ; }
            if (updateAllocPS != null) try { updateAllocPS.close(); } catch (SQLException e) { ; }
            if (updateChequePS != null) try { updateChequePS.close(); } catch (SQLException e) { ; }
            if (con != null) try { con.close(); } catch (SQLException e) { ; }
        }
    }
    
    // Check and auto-clear cheques after 10 days
    public void checkAndAutoClearCheques() throws Exception {
        Connection con = null;
        PreparedStatement updateAllocPS = null;
        PreparedStatement selectChequePS = null;
        PreparedStatement updateChequePS = null;
        ResultSet rs = null;
        
        try {
            con = util.DBConnectionManager.getConnectionFromPool();
            con.setAutoCommit(false);
            
            // Update allocations that have passed due date
            String updateAllocSql = "UPDATE prod_cheque_allocation " +
                                   "SET status = 'CLEARED', " +
                                   "cleared_date = CURDATE(), " +
                                   "cleared_time = CURTIME() " +
                                   "WHERE status = 'ALLOCATED' " +
                                   "AND CURDATE() >= due_date";
            
            updateAllocPS = con.prepareStatement(updateAllocSql);
            updateAllocPS.executeUpdate();
            
            // Update cheque stock status where all allocations are cleared
            String updateChequeSql = "UPDATE prod_cheque_stock " +
                                    "SET status = 'CLEARED' " +
                                    "WHERE status IN ('PARTIAL', 'FULLY_USED') " +
                                    "AND id NOT IN ( " +
                                    "  SELECT DISTINCT cheque_id FROM prod_cheque_allocation " +
                                    "  WHERE status = 'ALLOCATED' " +
                                    ")";
            
            updateChequePS = con.prepareStatement(updateChequeSql);
            updateChequePS.executeUpdate();
            
            con.commit();
            
        } catch (Exception e) {
            if (con != null) try { con.rollback(); } catch (Exception ignore) {}
            throw e;
        } finally {
            if (rs != null) try { rs.close(); } catch (SQLException e) { ; }
            if (updateAllocPS != null) try { updateAllocPS.close(); } catch (SQLException e) { ; }
            if (selectChequePS != null) try { selectChequePS.close(); } catch (SQLException e) { ; }
            if (updateChequePS != null) try { updateChequePS.close(); } catch (SQLException e) { ; }
            if (con != null) try { con.close(); } catch (SQLException e) { ; }
        }
    }
    
    // Mark cheque as bounced
    public void markChequeBounced(int chequeId, String reason, int uid) throws Exception {
        Connection con = null;
        PreparedStatement selectAllocPS = null;
        PreparedStatement updateBillPS = null;
        PreparedStatement updateChequePS = null;
        PreparedStatement insertEventPS = null;
        PreparedStatement updateAllocPS = null;
        ResultSet rs = null;
        
        try {
            con = util.DBConnectionManager.getConnectionFromPool();
            con.setAutoCommit(false);
            
            // Get all allocations for this cheque
            String selectSql = "SELECT id, bill_id " +
                              "FROM prod_cheque_allocation " +
                              "WHERE cheque_id = ? AND status IN ('ALLOCATED', 'CLEARED')";
            
            selectAllocPS = con.prepareStatement(selectSql);
            selectAllocPS.setInt(1, chequeId);
            rs = selectAllocPS.executeQuery();
            
            // Restore bill balances
            while (rs.next()) {
                int billId = rs.getInt("bill_id");
                int allocationId = rs.getInt("id");
                
                // Mark allocation as bounced
                String updateAllocSql = "UPDATE prod_cheque_allocation " +
                                       "SET status = 'BOUNCED' " +
                                       "WHERE id = ?";
                
                updateAllocPS = con.prepareStatement(updateAllocSql);
                updateAllocPS.setInt(1, allocationId);
                updateAllocPS.executeUpdate();
                updateAllocPS.close();
            }
            
            // Update cheque status
            String updateChequeSql = "UPDATE prod_cheque_stock " +
                                    "SET status = 'BOUNCED' " +
                                    "WHERE id = ?";
            
            updateChequePS = con.prepareStatement(updateChequeSql);
            updateChequePS.setInt(1, chequeId);
            updateChequePS.executeUpdate();
            
            // Insert bounce event
            String insertEventSql = "INSERT INTO prod_cheque_events " +
                                   "(cheque_id, event_type, event_date, event_time, reason, uid) " +
                                   "VALUES (?, 'BOUNCE', CURDATE(), CURTIME(), ?, ?)";
            
            insertEventPS = con.prepareStatement(insertEventSql);
            insertEventPS.setInt(1, chequeId);
            insertEventPS.setString(2, reason);
            insertEventPS.setInt(3, uid);
            insertEventPS.executeUpdate();
            
            con.commit();
            
        } catch (Exception e) {
            if (con != null) try { con.rollback(); } catch (Exception ignore) {}
            throw e;
        } finally {
            if (rs != null) try { rs.close(); } catch (SQLException e) { ; }
            if (selectAllocPS != null) try { selectAllocPS.close(); } catch (SQLException e) { ; }
            if (updateBillPS != null) try { updateBillPS.close(); } catch (SQLException e) { ; }
            if (updateChequePS != null) try { updateChequePS.close(); } catch (SQLException e) { ; }
            if (insertEventPS != null) try { insertEventPS.close(); } catch (SQLException e) { ; }
            if (updateAllocPS != null) try { updateAllocPS.close(); } catch (SQLException e) { ; }
            if (con != null) try { con.close(); } catch (SQLException e) { ; }
        }
    }
    
    // Mark cheque as expired
    public void markChequeExpired(int chequeId, String reason, int uid) throws Exception {
        Connection con = null;
        PreparedStatement selectAllocPS = null;
        PreparedStatement updateBillPS = null;
        PreparedStatement updateChequePS = null;
        PreparedStatement insertEventPS = null;
        PreparedStatement updateAllocPS = null;
        ResultSet rs = null;
        
        try {
            con = util.DBConnectionManager.getConnectionFromPool();
            con.setAutoCommit(false);
            
            // Get all allocations for this cheque
            String selectSql = "SELECT id, bill_id " +
                              "FROM prod_cheque_allocation " +
                              "WHERE cheque_id = ? AND status IN ('ALLOCATED', 'CLEARED')";
            
            selectAllocPS = con.prepareStatement(selectSql);
            selectAllocPS.setInt(1, chequeId);
            rs = selectAllocPS.executeQuery();
            
            // Restore bill balances
            while (rs.next()) {
                int billId = rs.getInt("bill_id");
                int allocationId = rs.getInt("id");
                
                // Mark allocation status
                String updateAllocSql = "UPDATE prod_cheque_allocation " +
                                       "SET status = 'BOUNCED' " +
                                       "WHERE id = ?";
                
                updateAllocPS = con.prepareStatement(updateAllocSql);
                updateAllocPS.setInt(1, allocationId);
                updateAllocPS.executeUpdate();
                updateAllocPS.close();
            }
            
            // Update cheque status
            String updateChequeSql = "UPDATE prod_cheque_stock " +
                                    "SET status = 'EXPIRED' " +
                                    "WHERE id = ?";
            
            updateChequePS = con.prepareStatement(updateChequeSql);
            updateChequePS.setInt(1, chequeId);
            updateChequePS.executeUpdate();
            
            // Insert expiry event
            String insertEventSql = "INSERT INTO prod_cheque_events " +
                                   "(cheque_id, event_type, event_date, event_time, reason, uid) " +
                                   "VALUES (?, 'EXPIRY', CURDATE(), CURTIME(), ?, ?)";
            
            insertEventPS = con.prepareStatement(insertEventSql);
            insertEventPS.setInt(1, chequeId);
            insertEventPS.setString(2, reason);
            insertEventPS.setInt(3, uid);
            insertEventPS.executeUpdate();
            
            con.commit();
            
        } catch (Exception e) {
            if (con != null) try { con.rollback(); } catch (Exception ignore) {}
            throw e;
        } finally {
            if (rs != null) try { rs.close(); } catch (SQLException e) { ; }
            if (selectAllocPS != null) try { selectAllocPS.close(); } catch (SQLException e) { ; }
            if (updateBillPS != null) try { updateBillPS.close(); } catch (SQLException e) { ; }
            if (updateChequePS != null) try { updateChequePS.close(); } catch (SQLException e) { ; }
            if (insertEventPS != null) try { insertEventPS.close(); } catch (SQLException e) { ; }
            if (updateAllocPS != null) try { updateAllocPS.close(); } catch (SQLException e) { ; }
            if (con != null) try { con.close(); } catch (SQLException e) { ; }
        }
    }
    
    // Clear cheque allocation when paid by cheque (bankOption = 6)
    public void clearChequeAllocationForBill(int billId, double paidAmount) throws Exception {
        Connection con = null;
        PreparedStatement selectPS = null;
        PreparedStatement updateAllocPS = null;
        PreparedStatement updateChequePS = null;
        ResultSet rs = null;
        
        try {
            con = util.DBConnectionManager.getConnectionFromPool();
            con.setAutoCommit(false);
            
            System.out.println("Clearing cheques for bill " + billId + ", amount: " + paidAmount);
            
            // Get allocated cheques for this bill that are still ALLOCATED
            String selectSql = "SELECT id, cheque_id " +
                              "FROM prod_cheque_allocation " +
                              "WHERE bill_id = ? AND status = 'ALLOCATED' " +
                              "ORDER BY allocated_date ASC";
            
            selectPS = con.prepareStatement(selectSql);
            selectPS.setInt(1, billId);
            rs = selectPS.executeQuery();
            
            double remainingAmount = paidAmount;
            
            while (rs.next() && remainingAmount > 0) {
                int allocationId = rs.getInt("id");
                int chequeId = rs.getInt("cheque_id");
                
                // Mark allocation as CLEARED
                String updateAllocSql = "UPDATE prod_cheque_allocation " +
                                       "SET status = 'CLEARED', " +
                                       "cleared_date = CURDATE(), " +
                                       "cleared_time = CURTIME() " +
                                       "WHERE id = ?";
                
                updateAllocPS = con.prepareStatement(updateAllocSql);
                updateAllocPS.setInt(1, allocationId);
                updateAllocPS.executeUpdate();
                updateAllocPS.close();
                
                System.out.println("Cleared allocation ID " + allocationId + " for cheque " + chequeId);
                
                remainingAmount -= paidAmount;
            }
            
            // Update cheque stock status to CLEARED if all allocations are cleared
            String updateChequeSql = "UPDATE prod_cheque_stock " +
                                    "SET status = 'CLEARED' " +
                                    "WHERE status IN ('PARTIAL', 'FULLY_USED') " +
                                    "AND id NOT IN ( " +
                                    "  SELECT DISTINCT cheque_id FROM prod_cheque_allocation " +
                                    "  WHERE status = 'ALLOCATED' " +
                                    ")";
            
            updateChequePS = con.prepareStatement(updateChequeSql);
            updateChequePS.executeUpdate();
            
            con.commit();
            System.out.println("Cheque clearing completed for bill " + billId);
            
        } catch (Exception e) {
            if (con != null) try { con.rollback(); } catch (Exception ignore) {}
            System.err.println("Error clearing cheque allocation: " + e.getMessage());
            throw e;
        } finally {
            if (rs != null) try { rs.close(); } catch (SQLException e) { ; }
            if (selectPS != null) try { selectPS.close(); } catch (SQLException e) { ; }
            if (updateAllocPS != null) try { updateAllocPS.close(); } catch (SQLException e) { ; }
            if (updateChequePS != null) try { updateChequePS.close(); } catch (SQLException e) { ; }
            if (con != null) try { con.close(); } catch (SQLException e) { ; }
        }
    }
    
    // Get all cheques with customer details
    public Vector getAllCheques() throws Exception {
        Connection con = null;
        PreparedStatement ps = null;
        ResultSet rs = null;
        
        try {
            con = util.DBConnectionManager.getConnectionFromPool();
            Vector cheques = new Vector();
            
            String sql = "SELECT c.id, c.cheque_number, c.bank_name, " +
                        "c.status, c.entry_date, cu.name AS customer_name, cu.phone_number " +
                        "FROM prod_cheque_stock c " +
                        "LEFT JOIN customers cu ON c.customer_id = cu.id " +
                        "WHERE c.is_active = 1 " +
                        "ORDER BY c.entry_date DESC, c.id DESC";
            
            ps = con.prepareStatement(sql);
            rs = ps.executeQuery();
            
            while (rs.next()) {
                Vector row = new Vector();
                row.add(rs.getInt("id"));                      // 0
                row.add(rs.getString("cheque_number"));         // 1
                row.add(rs.getString("bank_name"));             // 2
                row.add(rs.getString("status"));                // 3
                row.add(rs.getString("entry_date"));            // 4
                row.add(rs.getString("customer_name"));         // 5
                row.add(rs.getString("phone_number"));          // 6
                cheques.add(row);
            }
            
            return cheques;
            
        } finally {
            if (rs != null) try { rs.close(); } catch (SQLException e) { ; }
            if (ps != null) try { ps.close(); } catch (SQLException e) { ; }
            if (con != null) try { con.close(); } catch (SQLException e) { ; }
        }
    }
    
    // Get allocations for a cheque
    public Vector getChequeAllocations(int chequeId) throws Exception {
        Connection con = null;
        PreparedStatement ps = null;
        ResultSet rs = null;
        
        try {
            con = util.DBConnectionManager.getConnectionFromPool();
            Vector allocations = new Vector();
            
            String sql = "SELECT a.id, a.bill_id, b.bill_display, " +
                        "a.allocated_date, a.due_date, a.status, a.cleared_date, " +
                        "a.allocated_amount, b.cusName, b.currentBalance " +
                        "FROM prod_cheque_allocation a " +
                        "JOIN prod_bill b ON a.bill_id = b.id " +
                        "WHERE a.cheque_id = ? " +
                        "ORDER BY a.allocated_date DESC";
            
            ps = con.prepareStatement(sql);
            ps.setInt(1, chequeId);
            rs = ps.executeQuery();
            
            while (rs.next()) {
                Vector row = new Vector();
                row.add(rs.getInt("id"));                      // 0
                row.add(rs.getInt("bill_id"));                 // 1
                row.add(rs.getString("bill_display"));          // 2
                row.add(rs.getString("allocated_date"));        // 3
                row.add(rs.getString("due_date"));              // 4
                row.add(rs.getString("status"));                // 5
                row.add(rs.getString("cleared_date"));          // 6
                row.add(rs.getDouble("allocated_amount"));      // 7
                row.add(rs.getString("cusName"));               // 8
                row.add(rs.getDouble("currentBalance"));        // 9
                allocations.add(row);
            }
            
            return allocations;
            
        } finally {
            if (rs != null) try { rs.close(); } catch (SQLException e) { ; }
            if (ps != null) try { ps.close(); } catch (SQLException e) { ; }
            if (con != null) try { con.close(); } catch (SQLException e) { ; }
        }
    }
}
