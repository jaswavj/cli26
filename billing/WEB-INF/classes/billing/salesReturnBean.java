package billing;

import java.math.BigDecimal;
import java.sql.*;
import java.util.Vector;

public class salesReturnBean {

    public salesReturnBean() {
    }

    public Connection check() throws SQLException {
        return util.DBConnectionManager.getConnectionFromPool();
    }

    public void cancelBill(int billId, String cancelReason, int uid) throws Exception {
        Connection con = null;
        PreparedStatement psUpdate = null;
        PreparedStatement psInsert = null;

        try {
            con = util.DBConnectionManager.getConnectionFromPool();
            con.setAutoCommit(false);

            String updateSql = "UPDATE prod_bill SET is_cancelled = 1 WHERE id = ?";
            psUpdate = con.prepareStatement(updateSql);
            psUpdate.setInt(1, billId);
            psUpdate.executeUpdate();

            String insertSql =
                "INSERT INTO prod_bill_cancel (bill_id, reason, date, time, uid) " +
                "VALUES (?, ?, CURDATE(), CURTIME(), ?)";
            psInsert = con.prepareStatement(insertSql);
            psInsert.setInt(1, billId);
            psInsert.setString(2, cancelReason);
            psInsert.setInt(3, uid);
            psInsert.executeUpdate();

            con.commit();
        } catch (Exception e) {
            if (con != null) {
                try { con.rollback(); } catch (Exception ex) { ; }
            }
            throw e;
        } finally {
            if (psInsert != null) try { psInsert.close(); } catch (Exception e) { ; }
            if (psUpdate != null) try { psUpdate.close(); } catch (Exception e) { ; }
            if (con != null) try { con.close(); } catch (Exception e) { ; }
        }
    }

    public void updateStockAfterCancel(int prodId, BigDecimal qty, int uid) throws Exception {
        Connection con = null;
        PreparedStatement psUpdate = null;
        PreparedStatement psInsert = null;
        PreparedStatement psGetBatch = null;
        ResultSet rs = null;

        try {
            con = util.DBConnectionManager.getConnectionFromPool();
            con.setAutoCommit(false);

            String getBatchSql = "SELECT id, stock FROM prod_batch WHERE product_id = ? LIMIT 1";
            psGetBatch = con.prepareStatement(getBatchSql);
            psGetBatch.setInt(1, prodId);
            rs = psGetBatch.executeQuery();

            if (!rs.next()) {
                throw new Exception("No batch found for product id: " + prodId);
            }

            int batchId = rs.getInt("id");
            BigDecimal currentStock = rs.getBigDecimal("stock");
            BigDecimal newStock = currentStock.add(qty);

            String updateSql = "UPDATE prod_batch SET stock = ? WHERE id = ?";
            psUpdate = con.prepareStatement(updateSql);
            psUpdate.setBigDecimal(1, newStock);
            psUpdate.setInt(2, batchId);
            psUpdate.executeUpdate();

            String insertSql = "INSERT INTO prod_lifecycle " +
                    "(batch_id, product_id, stock_in, stock_out, stock_now, notes, date, time, uid, stock_type, stockAdjType) " +
                    "VALUES (?, ?, ?, 0, ?, ?, CURDATE(), CURTIME(), ?, 1, 1)";
            psInsert = con.prepareStatement(insertSql);
            psInsert.setInt(1, batchId);
            psInsert.setInt(2, prodId);
            psInsert.setBigDecimal(3, qty);
            psInsert.setBigDecimal(4, newStock);
            psInsert.setString(5, "Cancel bill - returned to stock");
            psInsert.setInt(6, uid);
            psInsert.executeUpdate();

            con.commit();
        } catch (Exception e) {
            if (con != null) {
                try { con.rollback(); } catch (Exception ex) { ; }
            }
            throw e;
        } finally {
            if (rs != null) try { rs.close(); } catch (Exception e) { ; }
            if (psInsert != null) try { psInsert.close(); } catch (Exception e) { ; }
            if (psUpdate != null) try { psUpdate.close(); } catch (Exception e) { ; }
            if (psGetBatch != null) try { psGetBatch.close(); } catch (Exception e) { ; }
            if (con != null) try { con.close(); } catch (Exception e) { ; }
        }
    }

    public Vector getBillDetails(int billId) throws Exception {
        Connection con = null;
        PreparedStatement ps = null;
        ResultSet rs = null;
        Vector vec = new Vector();
        try {
            con = util.DBConnectionManager.getConnectionFromPool();

            String sql = "SELECT bd.id, bd.bill_id, bd.prod_id, p.name AS product_name, " +
                         "bd.qty, bd.price, bd.disc, bd.total " +
                         "FROM prod_bill_details bd " +
                         "JOIN prod_product p ON bd.prod_id = p.id " +
                         "WHERE bd.bill_id = ?";

            ps = con.prepareStatement(sql);
            ps.setInt(1, billId);
            rs = ps.executeQuery();

            while (rs.next()) {
                Vector row = new Vector();
                row.addElement(rs.getInt("id"));
                row.addElement(rs.getInt("bill_id"));
                row.addElement(rs.getInt("prod_id"));
                row.addElement(rs.getString("product_name"));
                row.addElement(rs.getBigDecimal("qty"));
                row.addElement(rs.getDouble("price"));
                row.addElement(rs.getDouble("disc"));
                row.addElement(rs.getDouble("total"));
                vec.add(row);
            }
        } finally {
            if (rs != null) try { rs.close(); } catch (Exception e) { ; }
            if (ps != null) try { ps.close(); } catch (Exception e) { ; }
            if (con != null) try { con.close(); } catch (Exception e) { ; }
        }
        return vec;
    }

    public int getStatus(int billId, int prodId) throws Exception {
        Connection con = null;
        PreparedStatement pt = null;
        ResultSet rs = null;

        con = util.DBConnectionManager.getConnectionFromPool();
        try {
            int status = 0;

            pt = con.prepareStatement("SELECT CASE WHEN is_zero_stock_bill=1 THEN 1 ELSE 0 END AS STATUS FROM `prod_lifecycle` WHERE bill_id=? AND product_id=? AND is_zero_stock_bill=1;");
            pt.setInt(1, billId);
            pt.setInt(2, prodId);
            rs = pt.executeQuery();
            if (rs.next()) {
                status = rs.getInt(1);
            }

            return status;
        } finally {
            if (rs != null) {
                try { rs.close(); } catch (SQLException e) { ; }
                rs = null;
            }
            if (pt != null) {
                try { pt.close(); } catch (SQLException e) { ; }
                pt = null;
            }
            if (con != null) {
                try { con.close(); } catch (Exception e) { ; }
                con = null;
            }
        }
    }

    public Vector getCancelBill(String from, String to) throws Exception {
        Connection con = null;
        PreparedStatement ps = null;
        ResultSet rs = null;
        Vector vec = new Vector();
        try {
            con = util.DBConnectionManager.getConnectionFromPool();

            String sql = "SELECT b.`bill_display`,b.`payable`,b.`paid`,a.`reason`,a.`date`,a.`time`,c.user_name,b.id FROM `prod_bill_cancel` a,`prod_bill` b,users c WHERE a.`bill_id`=b.`id` AND a.`uid`=c.id AND a.`date` BETWEEN ? AND ? ;";

            ps = con.prepareStatement(sql);
            ps.setString(1, from);
            ps.setString(2, to);
            rs = ps.executeQuery();

            while (rs.next()) {
                Vector row = new Vector();
                row.addElement(rs.getString(1));
                row.addElement(rs.getString(2));
                row.addElement(rs.getString(3));
                row.addElement(rs.getString(4));
                row.addElement(rs.getString(5));
                row.addElement(rs.getString(6));
                row.addElement(rs.getString(7));
                row.addElement(rs.getString(8));
                vec.add(row);
            }
        } finally {
            if (rs != null) try { rs.close(); } catch (Exception e) { ; }
            if (ps != null) try { ps.close(); } catch (Exception e) { ; }
            if (con != null) try { con.close(); } catch (Exception e) { ; }
        }
        return vec;
    }

    public Vector getBillPaymentInfo(String billNo) throws Exception {
        Connection con = null;
        PreparedStatement ps = null;
        ResultSet rs = null;
        Vector vec = new Vector();
        try {
            con = util.DBConnectionManager.getConnectionFromPool();
            String sql =
                "SELECT a.id, a.bill_display, a.date, IFNULL(a.cusName,'') AS cusName, " +
                "       a.payable, a.paymentMode, a.paymentType, " +
                "       IFNULL(b.cash, 0) AS cash, IFNULL(b.bank, 0) AS bank " +
                "FROM prod_bill a " +
                "LEFT JOIN prod_bill_payment b ON b.bill_id = a.id " +
                "WHERE a.bill_display = ? AND a.is_cancelled = 0 " +
                "LIMIT 1";
            ps = con.prepareStatement(sql);
            ps.setString(1, billNo);
            rs = ps.executeQuery();
            if (rs.next()) {
                vec.addElement(rs.getInt("id"));
                vec.addElement(rs.getString("bill_display"));
                vec.addElement(rs.getString("date"));
                vec.addElement(rs.getString("cusName"));
                vec.addElement(rs.getDouble("payable"));
                vec.addElement(rs.getInt("paymentMode"));
                vec.addElement(rs.getInt("paymentType"));
                vec.addElement(rs.getDouble("cash"));
                vec.addElement(rs.getDouble("bank"));
            }
            return vec;
        } finally {
            if (rs != null) try { rs.close(); } catch (SQLException e) { ; }
            if (ps != null) try { ps.close(); } catch (SQLException e) { ; }
            if (con != null) try { con.close(); } catch (Exception e) { ; }
        }
    }

    public void updateBillPaymentType(int billId, double cash, double bank, int bankMode, int uid) throws Exception {
        Connection con = null;
        PreparedStatement ps = null;
        ResultSet rs = null;
        try {
            con = util.DBConnectionManager.getConnectionFromPool();
            con.setAutoCommit(false);

            ps = con.prepareStatement(
                "SELECT IFNULL(b.cash,0), IFNULL(b.bank,0) " +
                "FROM prod_bill a " +
                "LEFT JOIN prod_bill_payment b ON b.bill_id = a.id " +
                "WHERE a.id = ? AND a.is_cancelled = 0 LIMIT 1");
            ps.setInt(1, billId);
            rs = ps.executeQuery();
            if (!rs.next()) {
                throw new Exception("Bill not found or has been cancelled.");
            }
            double oldCash = rs.getDouble(1);
            double oldBank = rs.getDouble(2);
            rs.close(); ps.close();

            int paymentMode;
            if (cash > 0 && bank > 0) {
                paymentMode = 3;
            } else if (bank > 0) {
                paymentMode = 2;
            } else {
                paymentMode = 1;
            }
            int paymentType = (bank > 0) ? bankMode : 0;

            ps = con.prepareStatement(
                "UPDATE prod_bill_payment " +
                "SET cash = ?, bank = ?, paymentType = ? " +
                "WHERE bill_id = ?");
            ps.setDouble(1, cash);
            ps.setDouble(2, bank);
            ps.setInt(3, paymentType);
            ps.setInt(4, billId);
            ps.executeUpdate();
            ps.close();

            ps = con.prepareStatement(
                "UPDATE prod_bill " +
                "SET paymentMode = ?, paymentType = ?, paid = ? " +
                "WHERE id = ?");
            ps.setInt(1, paymentMode);
            ps.setInt(2, paymentType);
            ps.setDouble(3, cash + bank);
            ps.setInt(4, billId);
            ps.executeUpdate();
            ps.close();

            ps = con.prepareStatement(
                "INSERT INTO prod_bill_payment_type_change " +
                "(bill_id, old_cash_amount, cash_amount, old_bank_amount, bank_amount, bank_mode, uid, date_time) " +
                "VALUES (?, ?, ?, ?, ?, ?, ?, NOW())");
            ps.setInt(1, billId);
            ps.setDouble(2, oldCash);
            ps.setDouble(3, cash);
            ps.setDouble(4, oldBank);
            ps.setDouble(5, bank);
            if (bank > 0) {
                ps.setInt(6, bankMode);
            } else {
                ps.setNull(6, java.sql.Types.INTEGER);
            }
            ps.setInt(7, uid);
            ps.executeUpdate();
            ps.close();

            con.commit();
        } catch (Exception e) {
            if (con != null) try { con.rollback(); } catch (Exception ignored) { ; }
            throw e;
        } finally {
            if (rs != null) try { rs.close(); } catch (SQLException e) { ; }
            if (ps != null) try { ps.close(); } catch (SQLException e) { ; }
            if (con != null) try { con.close(); } catch (Exception e) { ; }
        }
    }

    public Vector getPaymentTypeChangeReport(String fromDate, String toDate) throws Exception {
        Connection con = null;
        PreparedStatement ps = null;
        ResultSet rs = null;
        Vector vec = new Vector();
        try {
            con = util.DBConnectionManager.getConnectionFromPool();
            String sql =
                "SELECT c.id, c.bill_id, b.bill_display, " +
                "       c.old_cash_amount, c.cash_amount, " +
                "       c.old_bank_amount, c.bank_amount, " +
                "       IFNULL(pt.type, 'Cash') AS bank_mode_name, " +
                "       IFNULL(u.user_name, '') AS user_name, " +
                "       c.date_time " +
                "FROM prod_bill_payment_type_change c " +
                "JOIN prod_bill b ON b.id = c.bill_id " +
                "LEFT JOIN prod_bill_payment_type pt ON pt.id = c.bank_mode " +
                "LEFT JOIN users u ON u.id = c.uid " +
                "WHERE DATE(c.date_time) BETWEEN ? AND ? " +
                "ORDER BY c.date_time DESC";
            ps = con.prepareStatement(sql);
            ps.setString(1, fromDate);
            ps.setString(2, toDate);
            rs = ps.executeQuery();
            while (rs.next()) {
                Vector row = new Vector();
                row.addElement(rs.getInt("id"));
                row.addElement(rs.getInt("bill_id"));
                row.addElement(rs.getString("bill_display"));
                row.addElement(rs.getDouble("old_cash_amount"));
                row.addElement(rs.getDouble("cash_amount"));
                row.addElement(rs.getDouble("old_bank_amount"));
                row.addElement(rs.getDouble("bank_amount"));
                row.addElement(rs.getString("bank_mode_name"));
                row.addElement(rs.getString("user_name"));
                row.addElement(rs.getString("date_time"));
                vec.add(row);
            }
            return vec;
        } finally {
            if (rs != null) try { rs.close(); } catch (SQLException e) { ; }
            if (ps != null) try { ps.close(); } catch (SQLException e) { ; }
            if (con != null) try { con.close(); } catch (Exception e) { ; }
        }
    }

    public Vector getBillHeaderForExchange(String billNo) throws Exception {
        Connection con = null;
        PreparedStatement ps = null;
        ResultSet rs = null;
        try {
            con = util.DBConnectionManager.getConnectionFromPool();
            String sql = "SELECT id, customerId, total, payable, paid, cusName, date "
                       + "FROM prod_bill WHERE bill_display = ? AND is_cancelled = 0";
            ps = con.prepareStatement(sql);
            ps.setString(1, billNo);
            rs = ps.executeQuery();
            Vector row = new Vector();
            if (rs.next()) {
                row.add(rs.getObject(1));
                row.add(rs.getObject(2));
                row.add(rs.getString(3));
                row.add(rs.getString(4));
                row.add(rs.getString(5));
                row.add(rs.getString(6) != null ? rs.getString(6) : "-");
                row.add(rs.getString(7) != null ? rs.getString(7) : "-");
            }
            return row;
        } finally {
            if (rs != null) try { rs.close(); } catch (Exception e) { ; }
            if (ps != null) try { ps.close(); } catch (Exception e) { ; }
            if (con != null) try { con.close(); } catch (Exception e) { ; }
        }
    }

    public Vector getBillItemsForExchange(String billNo) throws Exception {
        Connection con = null;
        PreparedStatement ps = null;
        ResultSet rs = null;
        Vector vec = new Vector();
        try {
            con = util.DBConnectionManager.getConnectionFromPool();
            String sql = "SELECT bd.id, bd.prod_id, p.name, bd.qty, bd.price, bd.disc, bd.total, "
                       + "IFNULL(bd.is_exchanged, 0) AS is_exchanged "
                       + "FROM prod_bill b "
                       + "JOIN prod_bill_details bd ON bd.bill_id = b.id "
                       + "JOIN prod_product p ON p.id = bd.prod_id "
                       + "WHERE b.bill_display = ? AND b.is_cancelled = 0 AND bd.is_cancelled = 0";
            ps = con.prepareStatement(sql);
            ps.setString(1, billNo);
            rs = ps.executeQuery();
            while (rs.next()) {
                Vector row = new Vector();
                row.add(rs.getString(1));
                row.add(rs.getString(2));
                row.add(rs.getString(3));
                row.add(rs.getString(4));
                row.add(rs.getString(5));
                row.add(rs.getString(6));
                row.add(rs.getString(7));
                row.add(rs.getString(8));
                vec.add(row);
            }
            return vec;
        } finally {
            if (rs != null) try { rs.close(); } catch (Exception e) { ; }
            if (ps != null) try { ps.close(); } catch (Exception e) { ; }
            if (con != null) try { con.close(); } catch (Exception e) { ; }
        }
    }

    public Vector searchProductsForExchange(String term) throws Exception {
        Connection con = null;
        PreparedStatement ps = null;
        ResultSet rs = null;
        Vector vec = new Vector();
        try {
            con = util.DBConnectionManager.getConnectionFromPool();
            String sql = "SELECT p.id, p.name, IFNULL(b.mrp, 0) AS mrp, COALESCE(p.code,'') AS code "
                       + "FROM prod_product p "
                       + "LEFT JOIN prod_batch b ON b.product_id = p.id "
                       + "WHERE p.is_active = 1 AND (p.name LIKE ? OR p.code LIKE ?) "
                       + "GROUP BY p.id, p.name, b.mrp, p.code "
                       + "ORDER BY p.name LIMIT 20";
            ps = con.prepareStatement(sql);
            ps.setString(1, "%" + term + "%");
            ps.setString(2, "%" + term + "%");
            rs = ps.executeQuery();
            while (rs.next()) {
                Vector row = new Vector();
                row.add(rs.getString(1));
                row.add(rs.getString(2));
                row.add(rs.getString(3));
                row.add(rs.getString(4));
                vec.add(row);
            }
            return vec;
        } finally {
            if (rs != null) try { rs.close(); } catch (Exception e) { ; }
            if (ps != null) try { ps.close(); } catch (Exception e) { ; }
            if (con != null) try { con.close(); } catch (Exception e) { ; }
        }
    }

    public String saveExchange(String billNo, int detailId, int newProdId, double newPrice, int uid) throws Exception {
        Connection con = null;
        PreparedStatement ps = null;
        ResultSet rs = null;

        try {
            con = util.DBConnectionManager.getConnectionFromPool();
            con.setAutoCommit(false);

            ps = con.prepareStatement(
                "SELECT bd.id, bd.bill_id, bd.prod_id, bd.qty, bd.price, bd.total, "
              + "IFNULL(bd.is_exchanged, 0) "
              + "FROM prod_bill_details bd "
              + "WHERE bd.id = ? AND bd.is_cancelled = 0");
            ps.setInt(1, detailId);
            rs = ps.executeQuery();
            if (!rs.next()) {
                throw new Exception("Bill detail not found or already cancelled.");
            }
            int fetchedBillId = rs.getInt(2);
            int oldProdId = rs.getInt(3);
            BigDecimal qty = rs.getBigDecimal(4);
            double oldItemTotal = rs.getDouble(6);
            int alreadyExchanged = rs.getInt(7);
            rs.close(); ps.close();

            if (alreadyExchanged == 1) {
                throw new Exception("This item has already been exchanged.");
            }

            ps = con.prepareStatement(
                "SELECT id, customerId, total, payable, paid FROM prod_bill "
              + "WHERE bill_display = ? AND is_cancelled = 0");
            ps.setString(1, billNo);
            rs = ps.executeQuery();
            if (!rs.next()) {
                throw new Exception("Bill not found: " + billNo);
            }
            int billId = rs.getInt(1);
            int customerId = rs.getInt(2);
            boolean hasCustomer = !rs.wasNull() && customerId > 0;
            double billTotal = rs.getDouble(3);
            double billPayable = rs.getDouble(4);
            rs.close(); ps.close();

            if (billId != fetchedBillId) {
                throw new Exception("Bill / detail mismatch.");
            }

            double newItemTotal = new BigDecimal(newPrice).multiply(qty)
                                       .setScale(3, java.math.RoundingMode.HALF_UP).doubleValue();
            double diff = new BigDecimal(newItemTotal - oldItemTotal)
                                       .setScale(3, java.math.RoundingMode.HALF_UP).doubleValue();
            double newBillTotal = new BigDecimal(billTotal + diff)
                                       .setScale(3, java.math.RoundingMode.HALF_UP).doubleValue();
            double newBillPayable = new BigDecimal(billPayable + diff)
                                       .setScale(3, java.math.RoundingMode.HALF_UP).doubleValue();

            int oldBatchId = 0;
            ps = con.prepareStatement(
                "SELECT id FROM prod_batch WHERE product_id = ? ORDER BY id DESC LIMIT 1");
            ps.setInt(1, oldProdId);
            rs = ps.executeQuery();
            if (rs.next()) oldBatchId = rs.getInt(1);
            rs.close(); ps.close();

            int newBatchId = 0;
            ps = con.prepareStatement(
                "SELECT id FROM prod_batch WHERE product_id = ? ORDER BY id DESC LIMIT 1");
            ps.setInt(1, newProdId);
            rs = ps.executeQuery();
            if (rs.next()) newBatchId = rs.getInt(1);
            rs.close(); ps.close();

            if (oldBatchId > 0) {
                ps = con.prepareStatement(
                    "UPDATE prod_batch SET stock = stock + ? WHERE id = ?");
                ps.setBigDecimal(1, qty);
                ps.setInt(2, oldBatchId);
                ps.executeUpdate();
                ps.close();

                BigDecimal oldProdLastStock = BigDecimal.ZERO;
                ps = con.prepareStatement(
                    "SELECT stock_now FROM prod_lifecycle WHERE product_id = ? ORDER BY id DESC LIMIT 1");
                ps.setInt(1, oldProdId);
                rs = ps.executeQuery();
                if (rs.next()) oldProdLastStock = rs.getBigDecimal(1);
                rs.close(); ps.close();

                BigDecimal oldProdStockNow = oldProdLastStock.add(qty);

                ps = con.prepareStatement(
                    "INSERT INTO prod_lifecycle "
                  + "(bill_id, batch_id, product_id, stock_in, stock_out, stock_now, "
                  + " notes, date, time, uid, stock_type, stockAdjType) "
                  + "VALUES (?, ?, ?, ?, 0, ?, 'PRODUCT EXCHANGE - RETURNED', NOW(), NOW(), ?, 1, 1)");
                ps.setInt(1, billId);
                ps.setInt(2, oldBatchId);
                ps.setInt(3, oldProdId);
                ps.setBigDecimal(4, qty);
                ps.setBigDecimal(5, oldProdStockNow);
                ps.setInt(6, uid);
                ps.executeUpdate();
                ps.close();
            }

            if (newBatchId > 0) {
                BigDecimal newProdCurrentStock = BigDecimal.ZERO;
                ps = con.prepareStatement(
                    "SELECT stock FROM prod_batch WHERE id = ?");
                ps.setInt(1, newBatchId);
                rs = ps.executeQuery();
                if (rs.next()) newProdCurrentStock = rs.getBigDecimal(1);
                rs.close(); ps.close();

                BigDecimal newProdLastStock = BigDecimal.ZERO;
                ps = con.prepareStatement(
                    "SELECT stock_now FROM prod_lifecycle WHERE product_id = ? ORDER BY id DESC LIMIT 1");
                ps.setInt(1, newProdId);
                rs = ps.executeQuery();
                if (rs.next()) newProdLastStock = rs.getBigDecimal(1);
                rs.close(); ps.close();

                if (newProdCurrentStock.compareTo(qty) >= 0) {
                    ps = con.prepareStatement(
                        "UPDATE prod_batch SET stock = stock - ? WHERE id = ?");
                    ps.setBigDecimal(1, qty);
                    ps.setInt(2, newBatchId);
                    ps.executeUpdate();
                    ps.close();

                    BigDecimal newProdStockNow = newProdLastStock.subtract(qty);
                    ps = con.prepareStatement(
                        "INSERT INTO prod_lifecycle "
                      + "(bill_id, batch_id, product_id, stock_in, stock_out, stock_now, "
                      + " notes, date, time, uid, stock_type, stockAdjType) "
                      + "VALUES (?, ?, ?, 0, ?, ?, 'PRODUCT EXCHANGE - GIVEN', NOW(), NOW(), ?, 1, 2)");
                    ps.setInt(1, billId);
                    ps.setInt(2, newBatchId);
                    ps.setInt(3, newProdId);
                    ps.setBigDecimal(4, qty);
                    ps.setBigDecimal(5, newProdStockNow);
                    ps.setInt(6, uid);
                    ps.executeUpdate();
                    ps.close();
                } else {
                    ps = con.prepareStatement(
                        "INSERT INTO prod_batch_zero_stock_bill "
                      + "(batch_id, product_id, qty, date, time, uid) "
                      + "VALUES (?, ?, ?, NOW(), NOW(), ?)");
                    ps.setInt(1, newBatchId);
                    ps.setInt(2, newProdId);
                    ps.setBigDecimal(3, qty);
                    ps.setInt(4, uid);
                    ps.executeUpdate();
                    ps.close();

                    ps = con.prepareStatement(
                        "INSERT INTO prod_lifecycle "
                      + "(bill_id, batch_id, product_id, stock_in, stock_out, stock_now, "
                      + " notes, date, time, uid, stock_type, is_zero_stock_bill, stockAdjType) "
                      + "VALUES (?, ?, ?, 0, ?, ?, 'PRODUCT EXCHANGE - GIVEN WITHOUT STOCK', NOW(), NOW(), ?, 1, 1, 2)");
                    ps.setInt(1, billId);
                    ps.setInt(2, newBatchId);
                    ps.setInt(3, newProdId);
                    ps.setBigDecimal(4, qty);
                    ps.setBigDecimal(5, newProdLastStock);
                    ps.setInt(6, uid);
                    ps.executeUpdate();
                    ps.close();
                }
            }

            ps = con.prepareStatement(
                "UPDATE prod_bill_details SET prod_id = ?, price = ?, disc = 0, total = ?, is_exchanged = 1 "
              + "WHERE id = ?");
            ps.setInt(1, newProdId);
            ps.setDouble(2, newPrice);
            ps.setDouble(3, newItemTotal);
            ps.setInt(4, detailId);
            ps.executeUpdate();
            ps.close();

            ps = con.prepareStatement(
                "UPDATE prod_bill SET total = ?, payable = ? WHERE id = ?");
            ps.setDouble(1, newBillTotal);
            ps.setDouble(2, newBillPayable);
            ps.setInt(3, billId);
            ps.executeUpdate();
            ps.close();

            ps = con.prepareStatement(
                "INSERT INTO pro_bill_exchange (bill_id, customer_id, old_prod_id, new_prod_id, uid, date_time) "
              + "VALUES (?, ?, ?, ?, ?, NOW())");
            ps.setInt(1, billId);
            if (hasCustomer) { ps.setInt(2, customerId); } else { ps.setNull(2, java.sql.Types.INTEGER); }
            ps.setInt(3, oldProdId);
            ps.setInt(4, newProdId);
            ps.setInt(5, uid);
            ps.executeUpdate();
            ps.close();

            String resultMsg;
            if (diff < 0 && hasCustomer) {
                double exchangePointAmount = Math.abs(diff);

                ps = con.prepareStatement("SELECT IFNULL(exchange_point, 0) FROM customers WHERE id = ?");
                ps.setInt(1, customerId);
                rs = ps.executeQuery();
                double oldPoint = rs.next() ? rs.getDouble(1) : 0;
                rs.close(); ps.close();

                double totalPoint = new BigDecimal(oldPoint + exchangePointAmount)
                                        .setScale(3, java.math.RoundingMode.HALF_UP).doubleValue();

                ps = con.prepareStatement("UPDATE customers SET exchange_point = ? WHERE id = ?");
                ps.setDouble(1, totalPoint);
                ps.setInt(2, customerId);
                ps.executeUpdate();
                ps.close();

                ps = con.prepareStatement(
                    "INSERT INTO customers_exchange_point "
                  + "(customer_id, bill_id, old_point, exchange_point, total_point, uid, date_time, notes) "
                  + "VALUES (?, ?, ?, ?, ?, ?, NOW(), ?)");
                ps.setInt(1, customerId);
                ps.setInt(2, billId);
                ps.setDouble(3, oldPoint);
                ps.setDouble(4, exchangePointAmount);
                ps.setDouble(5, totalPoint);
                ps.setInt(6, uid);
                ps.setString(7, "Points earned on product exchange (Bill: " + billNo + ")");
                ps.executeUpdate();
                ps.close();

                resultMsg = "Exchange completed. Customer earned Rs " + String.format("%.2f", exchangePointAmount)
                          + " exchange points. Total points: Rs " + String.format("%.2f", totalPoint);
            } else if (diff > 0) {
                resultMsg = "Exchange completed. Bill amount increased by Rs " + String.format("%.2f", diff);
            } else {
                resultMsg = "Exchange completed. Same amount - no change to bill or points.";
            }

            con.commit();
            return resultMsg;

        } catch (Exception e) {
            if (con != null) { try { con.rollback(); } catch (Exception ex) { ; } }
            throw e;
        } finally {
            if (rs != null) try { rs.close(); } catch (Exception e) { ; }
            if (ps != null) try { ps.close(); } catch (Exception e) { ; }
            if (con != null) try { con.close(); } catch (Exception e) { ; }
        }
    }

    public String saveReturn(String billNo, int detailId, double returnQty, int uid) throws Exception {
        Connection con = null;
        PreparedStatement ps = null;
        ResultSet rs = null;

        try {
            con = util.DBConnectionManager.getConnectionFromPool();
            con.setAutoCommit(false);

            ps = con.prepareStatement(
                "SELECT bd.id, bd.bill_id, bd.prod_id, bd.qty, bd.total, "
              + "IFNULL(bd.is_exchanged, 0) "
              + "FROM prod_bill_details bd "
              + "WHERE bd.id = ? AND bd.is_cancelled = 0");
            ps.setInt(1, detailId);
            rs = ps.executeQuery();
            if (!rs.next()) {
                throw new Exception("Bill detail not found or already cancelled.");
            }
            int fetchedBillId = rs.getInt(2);
            int prodId = rs.getInt(3);
            BigDecimal totalQty = rs.getBigDecimal(4);
            double itemTotal = rs.getDouble(5);
            int currentStatus = rs.getInt(6);
            rs.close(); ps.close();

            if (currentStatus == 1) throw new Exception("This item has already been exchanged.");
            if (currentStatus == 2) throw new Exception("This item has already been returned.");

            BigDecimal retQty = new BigDecimal(returnQty).setScale(3, java.math.RoundingMode.HALF_UP);
            if (retQty.compareTo(BigDecimal.ZERO) <= 0)
                throw new Exception("Return quantity must be greater than zero.");
            if (retQty.compareTo(totalQty) > 0)
                throw new Exception("Return quantity (" + retQty + ") exceeds bill quantity (" + totalQty + ").");

            double retAmount = new BigDecimal(itemTotal)
                .multiply(retQty)
                .divide(totalQty, 3, java.math.RoundingMode.HALF_UP)
                .doubleValue();

            boolean isFullReturn = retQty.compareTo(totalQty) == 0;

            ps = con.prepareStatement(
                "SELECT id, customerId, total, payable FROM prod_bill "
              + "WHERE bill_display = ? AND is_cancelled = 0");
            ps.setString(1, billNo);
            rs = ps.executeQuery();
            if (!rs.next()) throw new Exception("Bill not found: " + billNo);
            int billId = rs.getInt(1);
            int customerId = rs.getInt(2);
            boolean hasCustomer = !rs.wasNull() && customerId > 0;
            double billTotal = rs.getDouble(3);
            double billPayable = rs.getDouble(4);
            rs.close(); ps.close();

            if (billId != fetchedBillId) throw new Exception("Bill / detail mismatch.");

            int batchId = 0;
            ps = con.prepareStatement(
                "SELECT id FROM prod_batch WHERE product_id = ? ORDER BY id DESC LIMIT 1");
            ps.setInt(1, prodId);
            rs = ps.executeQuery();
            if (rs.next()) batchId = rs.getInt(1);
            rs.close(); ps.close();

            if (batchId > 0) {
                ps = con.prepareStatement(
                    "UPDATE prod_batch SET stock = stock + ? WHERE id = ?");
                ps.setBigDecimal(1, retQty);
                ps.setInt(2, batchId);
                ps.executeUpdate(); ps.close();

                BigDecimal lastStockNow = BigDecimal.ZERO;
                ps = con.prepareStatement(
                    "SELECT stock_now FROM prod_lifecycle WHERE product_id = ? ORDER BY id DESC LIMIT 1");
                ps.setInt(1, prodId);
                rs = ps.executeQuery();
                if (rs.next()) lastStockNow = rs.getBigDecimal(1);
                rs.close(); ps.close();

                ps = con.prepareStatement(
                    "INSERT INTO prod_lifecycle "
                  + "(bill_id, batch_id, product_id, stock_in, stock_out, stock_now, "
                  + " notes, date, time, uid, stock_type, stockAdjType) "
                  + "VALUES (?, ?, ?, ?, 0, ?, 'PRODUCT RETURN', NOW(), NOW(), ?, 1, 1)");
                ps.setInt(1, billId);
                ps.setInt(2, batchId);
                ps.setInt(3, prodId);
                ps.setBigDecimal(4, retQty);
                ps.setBigDecimal(5, lastStockNow.add(retQty));
                ps.setInt(6, uid);
                ps.executeUpdate(); ps.close();
            }

            double newBillTotal = new BigDecimal(billTotal - retAmount)
                                        .setScale(3, java.math.RoundingMode.HALF_UP).doubleValue();
            double newBillPayable = new BigDecimal(billPayable - retAmount)
                                        .setScale(3, java.math.RoundingMode.HALF_UP).doubleValue();
            ps = con.prepareStatement(
                "UPDATE prod_bill SET total = ?, payable = ? WHERE id = ?");
            ps.setDouble(1, newBillTotal < 0 ? 0 : newBillTotal);
            ps.setDouble(2, newBillPayable < 0 ? 0 : newBillPayable);
            ps.setInt(3, billId);
            ps.executeUpdate(); ps.close();

            if (isFullReturn) {
                ps = con.prepareStatement(
                    "UPDATE prod_bill_details SET is_exchanged = 2 WHERE id = ?");
                ps.setInt(1, detailId);
            } else {
                BigDecimal newQty = totalQty.subtract(retQty).setScale(3, java.math.RoundingMode.HALF_UP);
                double newItemTotal = new BigDecimal(itemTotal - retAmount)
                                            .setScale(3, java.math.RoundingMode.HALF_UP).doubleValue();
                ps = con.prepareStatement(
                    "UPDATE prod_bill_details SET qty = ?, total = ? WHERE id = ?");
                ps.setBigDecimal(1, newQty);
                ps.setDouble(2, newItemTotal < 0 ? 0 : newItemTotal);
                ps.setInt(3, detailId);
            }
            ps.executeUpdate(); ps.close();

            ps = con.prepareStatement(
                "INSERT INTO pro_bill_exchange (bill_id, customer_id, old_prod_id, new_prod_id, uid, date_time) "
              + "VALUES (?, ?, ?, ?, ?, NOW())");
            ps.setInt(1, billId);
            if (hasCustomer) { ps.setInt(2, customerId); } else { ps.setNull(2, java.sql.Types.INTEGER); }
            ps.setInt(3, prodId);
            ps.setInt(4, prodId);
            ps.setInt(5, uid);
            ps.executeUpdate(); ps.close();

            String resultMsg;
            if (hasCustomer) {
                ps = con.prepareStatement(
                    "SELECT IFNULL(exchange_point, 0) FROM customers WHERE id = ?");
                ps.setInt(1, customerId);
                rs = ps.executeQuery();
                double oldPoint = rs.next() ? rs.getDouble(1) : 0;
                rs.close(); ps.close();

                double totalPoint = new BigDecimal(oldPoint + retAmount)
                                        .setScale(3, java.math.RoundingMode.HALF_UP).doubleValue();
                ps = con.prepareStatement(
                    "UPDATE customers SET exchange_point = ? WHERE id = ?");
                ps.setDouble(1, totalPoint);
                ps.setInt(2, customerId);
                ps.executeUpdate(); ps.close();

                ps = con.prepareStatement(
                    "INSERT INTO customers_exchange_point "
                  + "(customer_id, bill_id, old_point, exchange_point, total_point, uid, date_time, notes) "
                  + "VALUES (?, ?, ?, ?, ?, ?, NOW(), ?)");
                ps.setInt(1, customerId);
                ps.setInt(2, billId);
                ps.setDouble(3, oldPoint);
                ps.setDouble(4, retAmount);
                ps.setDouble(5, totalPoint);
                ps.setInt(6, uid);
                ps.setString(7, "Points earned on product return (Bill: " + billNo + ", Qty: " + returnQty + ")");
                ps.executeUpdate(); ps.close();

                resultMsg = "Return completed for qty " + returnQty + ". Bill reduced by Rs "
                          + String.format("%.2f", retAmount)
                          + ". Customer earned Rs " + String.format("%.2f", retAmount)
                          + " exchange points. Total points: Rs " + String.format("%.2f", totalPoint);
            } else {
                resultMsg = "Return completed for qty " + returnQty + ". Bill reduced by Rs "
                          + String.format("%.2f", retAmount)
                          + ". No customer linked - exchange points not credited.";
            }

            con.commit();
            return resultMsg;

        } catch (Exception e) {
            if (con != null) { try { con.rollback(); } catch (Exception ex) { ; } }
            throw e;
        } finally {
            if (rs != null) try { rs.close(); } catch (Exception e) { ; }
            if (ps != null) try { ps.close(); } catch (Exception e) { ; }
            if (con != null) try { con.close(); } catch (Exception e) { ; }
        }
    }

    public String saveReturn(String billNo, int detailId, int uid) throws Exception {
        Connection con = null;
        PreparedStatement ps = null;
        ResultSet rs = null;

        try {
            con = util.DBConnectionManager.getConnectionFromPool();
            con.setAutoCommit(false);

            ps = con.prepareStatement(
                "SELECT bd.id, bd.bill_id, bd.prod_id, bd.qty, bd.total, "
              + "IFNULL(bd.is_exchanged, 0) "
              + "FROM prod_bill_details bd "
              + "WHERE bd.id = ? AND bd.is_cancelled = 0");
            ps.setInt(1, detailId);
            rs = ps.executeQuery();
            if (!rs.next()) {
                throw new Exception("Bill detail not found or already cancelled.");
            }
            int fetchedBillId = rs.getInt(2);
            int prodId = rs.getInt(3);
            BigDecimal qty = rs.getBigDecimal(4);
            double itemTotal = rs.getDouble(5);
            int currentStatus = rs.getInt(6);
            rs.close(); ps.close();

            if (currentStatus == 1) throw new Exception("This item has already been exchanged.");
            if (currentStatus == 2) throw new Exception("This item has already been returned.");

            ps = con.prepareStatement(
                "SELECT id, customerId, total, payable FROM prod_bill "
              + "WHERE bill_display = ? AND is_cancelled = 0");
            ps.setString(1, billNo);
            rs = ps.executeQuery();
            if (!rs.next()) {
                throw new Exception("Bill not found: " + billNo);
            }
            int billId = rs.getInt(1);
            int customerId = rs.getInt(2);
            boolean hasCustomer = !rs.wasNull() && customerId > 0;
            double billTotal = rs.getDouble(3);
            double billPayable = rs.getDouble(4);
            rs.close(); ps.close();

            if (billId != fetchedBillId) {
                throw new Exception("Bill / detail mismatch.");
            }

            int batchId = 0;
            ps = con.prepareStatement(
                "SELECT id FROM prod_batch WHERE product_id = ? ORDER BY id DESC LIMIT 1");
            ps.setInt(1, prodId);
            rs = ps.executeQuery();
            if (rs.next()) batchId = rs.getInt(1);
            rs.close(); ps.close();

            if (batchId > 0) {
                ps = con.prepareStatement(
                    "UPDATE prod_batch SET stock = stock + ? WHERE id = ?");
                ps.setBigDecimal(1, qty);
                ps.setInt(2, batchId);
                ps.executeUpdate();
                ps.close();

                BigDecimal lastStockNow = BigDecimal.ZERO;
                ps = con.prepareStatement(
                    "SELECT stock_now FROM prod_lifecycle WHERE product_id = ? ORDER BY id DESC LIMIT 1");
                ps.setInt(1, prodId);
                rs = ps.executeQuery();
                if (rs.next()) lastStockNow = rs.getBigDecimal(1);
                rs.close(); ps.close();

                BigDecimal stockNow = lastStockNow.add(qty);
                ps = con.prepareStatement(
                    "INSERT INTO prod_lifecycle "
                  + "(bill_id, batch_id, product_id, stock_in, stock_out, stock_now, "
                  + " notes, date, time, uid, stock_type, stockAdjType) "
                  + "VALUES (?, ?, ?, ?, 0, ?, 'PRODUCT RETURN', NOW(), NOW(), ?, 1, 1)");
                ps.setInt(1, billId);
                ps.setInt(2, batchId);
                ps.setInt(3, prodId);
                ps.setBigDecimal(4, qty);
                ps.setBigDecimal(5, stockNow);
                ps.setInt(6, uid);
                ps.executeUpdate();
                ps.close();
            }

            double newBillTotal = new BigDecimal(billTotal - itemTotal)
                                        .setScale(3, java.math.RoundingMode.HALF_UP).doubleValue();
            double newBillPayable = new BigDecimal(billPayable - itemTotal)
                                        .setScale(3, java.math.RoundingMode.HALF_UP).doubleValue();

            ps = con.prepareStatement(
                "UPDATE prod_bill SET total = ?, payable = ? WHERE id = ?");
            ps.setDouble(1, newBillTotal < 0 ? 0 : newBillTotal);
            ps.setDouble(2, newBillPayable < 0 ? 0 : newBillPayable);
            ps.setInt(3, billId);
            ps.executeUpdate();
            ps.close();

            ps = con.prepareStatement(
                "UPDATE prod_bill_details SET is_exchanged = 2 WHERE id = ?");
            ps.setInt(1, detailId);
            ps.executeUpdate();
            ps.close();

            ps = con.prepareStatement(
                "INSERT INTO pro_bill_exchange (bill_id, customer_id, old_prod_id, new_prod_id, uid, date_time) "
              + "VALUES (?, ?, ?, ?, ?, NOW())");
            ps.setInt(1, billId);
            if (hasCustomer) { ps.setInt(2, customerId); } else { ps.setNull(2, java.sql.Types.INTEGER); }
            ps.setInt(3, prodId);
            ps.setInt(4, prodId);
            ps.setInt(5, uid);
            ps.executeUpdate();
            ps.close();

            String resultMsg;
            if (hasCustomer) {
                ps = con.prepareStatement(
                    "SELECT IFNULL(exchange_point, 0) FROM customers WHERE id = ?");
                ps.setInt(1, customerId);
                rs = ps.executeQuery();
                double oldPoint = rs.next() ? rs.getDouble(1) : 0;
                rs.close(); ps.close();

                double totalPoint = new BigDecimal(oldPoint + itemTotal)
                                        .setScale(3, java.math.RoundingMode.HALF_UP).doubleValue();

                ps = con.prepareStatement(
                    "UPDATE customers SET exchange_point = ? WHERE id = ?");
                ps.setDouble(1, totalPoint);
                ps.setInt(2, customerId);
                ps.executeUpdate();
                ps.close();

                ps = con.prepareStatement(
                    "INSERT INTO customers_exchange_point "
                  + "(customer_id, bill_id, old_point, exchange_point, total_point, uid, date_time, notes) "
                  + "VALUES (?, ?, ?, ?, ?, ?, NOW(), ?)");
                ps.setInt(1, customerId);
                ps.setInt(2, billId);
                ps.setDouble(3, oldPoint);
                ps.setDouble(4, itemTotal);
                ps.setDouble(5, totalPoint);
                ps.setInt(6, uid);
                ps.setString(7, "Points earned on product return (Bill: " + billNo + ")");
                ps.executeUpdate();
                ps.close();

                resultMsg = "Return completed. Bill reduced by Rs " + String.format("%.2f", itemTotal)
                          + ". Customer earned Rs " + String.format("%.2f", itemTotal)
                          + " exchange points. Total points: Rs " + String.format("%.2f", totalPoint);
            } else {
                resultMsg = "Return completed. Bill reduced by Rs " + String.format("%.2f", itemTotal)
                          + ". No customer linked - exchange points not credited.";
            }

            con.commit();
            return resultMsg;

        } catch (Exception e) {
            if (con != null) { try { con.rollback(); } catch (Exception ex) { ; } }
            throw e;
        } finally {
            if (rs != null) try { rs.close(); } catch (Exception e) { ; }
            if (ps != null) try { ps.close(); } catch (Exception e) { ; }
            if (con != null) try { con.close(); } catch (Exception e) { ; }
        }
    }

    public Vector getExchangeReturnReport(String fromDate, String toDate, int typeFilter) throws Exception {
        Connection con = null;
        PreparedStatement ps = null;
        ResultSet rs = null;
        Vector result = new Vector();
        try {
            con = util.DBConnectionManager.getConnectionFromPool();

            String typeClause = "";
            if (typeFilter == 1) {
                typeClause = " AND pbe.old_prod_id <> pbe.new_prod_id ";
            } else if (typeFilter == 2) {
                typeClause = " AND pbe.old_prod_id = pbe.new_prod_id ";
            }

            String sql =
                "SELECT pbe.id, "
              + "       DATE_FORMAT(pbe.date_time,'%d-%m-%Y %H:%i') AS dt, "
              + "       pb.bill_display AS bill_no, "
              + "       IFNULL(c.name, 'Walk-in') AS customer_name, "
              + "       op.name AS old_prod_name, "
              + "       np.name AS new_prod_name, "
              + "       CASE WHEN pbe.old_prod_id = pbe.new_prod_id THEN 2 ELSE 1 END AS type, "
              + "       IFNULL((SELECT cep.exchange_point "
              + "                FROM customers_exchange_point cep "
              + "               WHERE cep.bill_id = pbe.bill_id "
              + "                 AND cep.customer_id = pbe.customer_id "
              + "               ORDER BY cep.id DESC LIMIT 1), 0) AS points_earned, "
              + "       IFNULL(u.user_name, '-') AS staff_name "
              + "FROM pro_bill_exchange pbe "
              + "JOIN prod_bill pb ON pb.id = pbe.bill_id "
              + "LEFT JOIN customers c ON c.id = pbe.customer_id "
              + "JOIN prod_product op ON op.id = pbe.old_prod_id "
              + "JOIN prod_product np ON np.id = pbe.new_prod_id "
              + "LEFT JOIN users u ON u.id = pbe.uid "
              + "WHERE DATE(pbe.date_time) BETWEEN ? AND ? "
              + typeClause
              + "ORDER BY pbe.date_time DESC";

            ps = con.prepareStatement(sql);
            ps.setString(1, fromDate);
            ps.setString(2, toDate);
            rs = ps.executeQuery();

            while (rs.next()) {
                Vector row = new Vector();
                row.add(rs.getInt("id"));
                row.add(rs.getString("dt"));
                row.add(rs.getString("bill_no"));
                row.add(rs.getString("customer_name"));
                row.add(rs.getString("old_prod_name"));
                row.add(rs.getString("new_prod_name"));
                row.add(rs.getInt("type"));
                row.add(rs.getDouble("points_earned"));
                row.add(rs.getString("staff_name"));
                result.add(row);
            }
            return result;
        } finally {
            if (rs != null) try { rs.close(); } catch (Exception e) { ; }
            if (ps != null) try { ps.close(); } catch (Exception e) { ; }
            if (con != null) try { con.close(); } catch (Exception e) { ; }
        }
    }

    public void useExchangePoint(int customerId, int billId, double pointsUsed, int uid) throws Exception {
        Connection con = null;
        PreparedStatement ps = null;
        ResultSet rs = null;
        try {
            con = util.DBConnectionManager.getConnectionFromPool();
            con.setAutoCommit(false);

            ps = con.prepareStatement(
                "SELECT IFNULL(exchange_point, 0) FROM customers WHERE id = ?");
            ps.setInt(1, customerId);
            rs = ps.executeQuery();
            double oldPoint = rs.next() ? rs.getDouble(1) : 0;
            rs.close(); ps.close();

            double actualDeduct = Math.min(pointsUsed, oldPoint);
            double newPoint = new BigDecimal(oldPoint - actualDeduct)
                                  .setScale(3, java.math.RoundingMode.HALF_UP).doubleValue();
            if (newPoint < 0) newPoint = 0;

            ps = con.prepareStatement(
                "UPDATE customers SET exchange_point = ? WHERE id = ?");
            ps.setDouble(1, newPoint);
            ps.setInt(2, customerId);
            ps.executeUpdate();
            ps.close();

            ps = con.prepareStatement(
                "INSERT INTO customers_exchange_point "
              + "(customer_id, bill_id, old_point, exchange_point, total_point, uid, date_time, notes) "
              + "VALUES (?, ?, ?, ?, ?, ?, NOW(), ?)");
            ps.setInt(1, customerId);
            ps.setInt(2, billId);
            ps.setDouble(3, oldPoint);
            ps.setDouble(4, -actualDeduct);
            ps.setDouble(5, newPoint);
            ps.setInt(6, uid);
            ps.setString(7, "Points used as bill discount (Bill ID: " + billId + ", Used: " + String.format("%.2f", actualDeduct) + ")");
            ps.executeUpdate();
            ps.close();

            con.commit();
        } catch (Exception e) {
            if (con != null) { try { con.rollback(); } catch (Exception ex) { ; } }
            throw e;
        } finally {
            if (rs != null) try { rs.close(); } catch (Exception e) { ; }
            if (ps != null) try { ps.close(); } catch (Exception e) { ; }
            if (con != null) try { con.close(); } catch (Exception e) { ; }
        }
    }
}
