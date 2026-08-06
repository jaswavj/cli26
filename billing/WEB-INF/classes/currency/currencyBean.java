package currency;

import java.math.BigDecimal;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.Vector;

public class currencyBean {

    public currencyBean() {
    }

    public int addCurrency(String code, String name, boolean isBase) throws Exception {
        Connection con = null;
        PreparedStatement pt = null;
        ResultSet rs = null;
        try {
            con = util.DBConnectionManager.getConnectionFromPool();
            con.setAutoCommit(false);

            if (isBase) {
                clearBaseCurrencyFlag(con);
            }

            pt = con.prepareStatement(
                "INSERT INTO ce_currency (currency_code, currency_name, is_active, is_base) VALUES (?, ?, 1, ?)",
                Statement.RETURN_GENERATED_KEYS
            );
            pt.setString(1, code.trim().toUpperCase());
            pt.setString(2, name.trim());
            pt.setInt(3, isBase ? 1 : 0);
            pt.executeUpdate();
            rs = pt.getGeneratedKeys();
            if (!rs.next()) {
                throw new Exception("Failed to create currency");
            }
            int newId = rs.getInt(1);
            con.commit();
            return newId;
        } catch (Exception e) {
            if (con != null) con.rollback();
            throw e;
        } finally {
            if (rs != null) try { rs.close(); } catch (Exception e) {}
            if (pt != null) try { pt.close(); } catch (Exception e) {}
            if (con != null) try { con.close(); } catch (Exception e) {}
        }
    }

    public int addCurrency(String code, String name) throws Exception {
        return addCurrency(code, name, false);
    }

    private void clearBaseCurrencyFlag(Connection con) throws Exception {
        PreparedStatement pt = null;
        try {
            pt = con.prepareStatement("UPDATE ce_currency SET is_base = 0 WHERE is_base = 1");
            pt.executeUpdate();
        } finally {
            if (pt != null) try { pt.close(); } catch (Exception e) {}
        }
    }

    public int getBaseCurrencyId() throws Exception {
        Connection con = null;
        PreparedStatement pt = null;
        ResultSet rs = null;
        try {
            con = util.DBConnectionManager.getConnectionFromPool();
            pt = con.prepareStatement(
                "SELECT id FROM ce_currency WHERE is_base = 1 AND is_active = 1 LIMIT 1"
            );
            rs = pt.executeQuery();
            if (rs.next()) {
                return rs.getInt("id");
            }
            return 0;
        } finally {
            if (rs != null) try { rs.close(); } catch (Exception e) {}
            if (pt != null) try { pt.close(); } catch (Exception e) {}
            if (con != null) try { con.close(); } catch (Exception e) {}
        }
    }

    public boolean hasBaseCurrency() throws Exception {
        return getBaseCurrencyId() > 0;
    }

    public void saveCurrencyLimits(int currencyId, int[] refCurrencyIds, BigDecimal[] minValues, BigDecimal[] maxValues) throws Exception {
        if (refCurrencyIds == null || refCurrencyIds.length == 0) {
            return;
        }

        Connection con = null;
        PreparedStatement pt = null;
        try {
            con = util.DBConnectionManager.getConnectionFromPool();
            con.setAutoCommit(false);
            pt = con.prepareStatement(
                "INSERT INTO ce_currency_limit (currency_id, ref_currency_id, min_value, max_value) VALUES (?, ?, ?, ?) " +
                "ON DUPLICATE KEY UPDATE min_value = VALUES(min_value), max_value = VALUES(max_value)"
            );

            for (int i = 0; i < refCurrencyIds.length; i++) {
                pt.setInt(1, currencyId);
                pt.setInt(2, refCurrencyIds[i]);
                pt.setBigDecimal(3, minValues[i] != null ? minValues[i] : BigDecimal.ZERO);
                pt.setBigDecimal(4, maxValues[i] != null ? maxValues[i] : BigDecimal.ZERO);
                pt.addBatch();
            }
            pt.executeBatch();
            con.commit();
        } catch (Exception e) {
            if (con != null) con.rollback();
            throw e;
        } finally {
            if (pt != null) try { pt.close(); } catch (Exception e) {}
            if (con != null) try { con.close(); } catch (Exception e) {}
        }
    }

    public void saveReverseCurrencyLimits(int refCurrencyId, int[] currencyIds, BigDecimal[] minValues, BigDecimal[] maxValues) throws Exception {
        if (currencyIds == null || currencyIds.length == 0) {
            return;
        }

        Connection con = null;
        PreparedStatement pt = null;
        try {
            con = util.DBConnectionManager.getConnectionFromPool();
            con.setAutoCommit(false);
            pt = con.prepareStatement(
                "INSERT INTO ce_currency_limit (currency_id, ref_currency_id, min_value, max_value) VALUES (?, ?, ?, ?) " +
                "ON DUPLICATE KEY UPDATE min_value = VALUES(min_value), max_value = VALUES(max_value)"
            );

            for (int i = 0; i < currencyIds.length; i++) {
                pt.setInt(1, currencyIds[i]);
                pt.setInt(2, refCurrencyId);
                pt.setBigDecimal(3, minValues[i] != null ? minValues[i] : BigDecimal.ZERO);
                pt.setBigDecimal(4, maxValues[i] != null ? maxValues[i] : BigDecimal.ZERO);
                pt.addBatch();
            }
            pt.executeBatch();
            con.commit();
        } catch (Exception e) {
            if (con != null) con.rollback();
            throw e;
        } finally {
            if (pt != null) try { pt.close(); } catch (Exception e) {}
            if (con != null) try { con.close(); } catch (Exception e) {}
        }
    }

    public Vector getCurrencyList() throws Exception {
        Connection con = null;
        PreparedStatement pt = null;
        ResultSet rs = null;
        Vector list = new Vector();
        try {
            con = util.DBConnectionManager.getConnectionFromPool();
            pt = con.prepareStatement(
                "SELECT id, currency_code, currency_name, is_active, is_base FROM ce_currency ORDER BY currency_code"
            );
            rs = pt.executeQuery();
            while (rs.next()) {
                Vector row = new Vector();
                row.addElement(rs.getInt("id"));
                row.addElement(rs.getString("currency_code"));
                row.addElement(rs.getString("currency_name"));
                row.addElement(rs.getInt("is_active"));
                row.addElement(rs.getInt("is_base"));
                list.addElement(row);
            }
            return list;
        } finally {
            if (rs != null) try { rs.close(); } catch (Exception e) {}
            if (pt != null) try { pt.close(); } catch (Exception e) {}
            if (con != null) try { con.close(); } catch (Exception e) {}
        }
    }

    public Vector getActiveCurrencyList() throws Exception {
        Connection con = null;
        PreparedStatement pt = null;
        ResultSet rs = null;
        Vector list = new Vector();
        try {
            con = util.DBConnectionManager.getConnectionFromPool();
            pt = con.prepareStatement(
                "SELECT id, currency_code, currency_name FROM ce_currency WHERE is_active = 1 ORDER BY currency_code"
            );
            rs = pt.executeQuery();
            while (rs.next()) {
                Vector row = new Vector();
                row.addElement(rs.getInt("id"));
                row.addElement(rs.getString("currency_code"));
                row.addElement(rs.getString("currency_name"));
                list.addElement(row);
            }
            return list;
        } finally {
            if (rs != null) try { rs.close(); } catch (Exception e) {}
            if (pt != null) try { pt.close(); } catch (Exception e) {}
            if (con != null) try { con.close(); } catch (Exception e) {}
        }
    }

    public Vector getCurrencyById(int id) throws Exception {
        Connection con = null;
        PreparedStatement pt = null;
        ResultSet rs = null;
        Vector row = new Vector();
        try {
            con = util.DBConnectionManager.getConnectionFromPool();
            pt = con.prepareStatement(
                "SELECT id, currency_code, currency_name, is_active, is_base FROM ce_currency WHERE id = ?"
            );
            pt.setInt(1, id);
            rs = pt.executeQuery();
            if (rs.next()) {
                row.addElement(rs.getInt("id"));
                row.addElement(rs.getString("currency_code"));
                row.addElement(rs.getString("currency_name"));
                row.addElement(rs.getInt("is_active"));
                row.addElement(rs.getInt("is_base"));
            }
            return row;
        } finally {
            if (rs != null) try { rs.close(); } catch (Exception e) {}
            if (pt != null) try { pt.close(); } catch (Exception e) {}
            if (con != null) try { con.close(); } catch (Exception e) {}
        }
    }

    public Vector getCurrencyLimits(int currencyId) throws Exception {
        Connection con = null;
        PreparedStatement pt = null;
        ResultSet rs = null;
        Vector list = new Vector();
        try {
            con = util.DBConnectionManager.getConnectionFromPool();
            pt = con.prepareStatement(
                "SELECT l.ref_currency_id, c.currency_code, c.currency_name, l.min_value, l.max_value " +
                "FROM ce_currency_limit l " +
                "INNER JOIN ce_currency c ON c.id = l.ref_currency_id " +
                "WHERE l.currency_id = ? " +
                "ORDER BY c.currency_code"
            );
            pt.setInt(1, currencyId);
            rs = pt.executeQuery();
            while (rs.next()) {
                Vector row = new Vector();
                row.addElement(rs.getInt("ref_currency_id"));
                row.addElement(rs.getString("currency_code"));
                row.addElement(rs.getString("currency_name"));
                row.addElement(rs.getBigDecimal("min_value"));
                row.addElement(rs.getBigDecimal("max_value"));
                list.addElement(row);
            }
            return list;
        } finally {
            if (rs != null) try { rs.close(); } catch (Exception e) {}
            if (pt != null) try { pt.close(); } catch (Exception e) {}
            if (con != null) try { con.close(); } catch (Exception e) {}
        }
    }

    public Vector getReverseCurrencyLimits(int refCurrencyId) throws Exception {
        Connection con = null;
        PreparedStatement pt = null;
        ResultSet rs = null;
        Vector list = new Vector();
        try {
            con = util.DBConnectionManager.getConnectionFromPool();
            pt = con.prepareStatement(
                "SELECT l.currency_id, c.currency_code, c.currency_name, l.min_value, l.max_value " +
                "FROM ce_currency_limit l " +
                "INNER JOIN ce_currency c ON c.id = l.currency_id " +
                "WHERE l.ref_currency_id = ? " +
                "ORDER BY c.currency_code"
            );
            pt.setInt(1, refCurrencyId);
            rs = pt.executeQuery();
            while (rs.next()) {
                Vector row = new Vector();
                row.addElement(rs.getInt("currency_id"));
                row.addElement(rs.getString("currency_code"));
                row.addElement(rs.getString("currency_name"));
                row.addElement(rs.getBigDecimal("min_value"));
                row.addElement(rs.getBigDecimal("max_value"));
                list.addElement(row);
            }
            return list;
        } finally {
            if (rs != null) try { rs.close(); } catch (Exception e) {}
            if (pt != null) try { pt.close(); } catch (Exception e) {}
            if (con != null) try { con.close(); } catch (Exception e) {}
        }
    }

    public String getCurrencyLimitsSummary(int currencyId) throws Exception {
        Vector limits = getCurrencyLimits(currencyId);
        if (limits == null || limits.isEmpty()) {
            return "-";
        }

        int baseId = 0;
        try {
            baseId = getBaseCurrencyId();
        } catch (Exception e) {
            baseId = 0;
        }

        StringBuilder sb = new StringBuilder();
        int shown = 0;
        for (int i = 0; i < limits.size(); i++) {
            Vector row = (Vector) limits.get(i);
            int refId = Integer.parseInt(row.elementAt(0).toString());
            if (baseId > 0 && refId != baseId) {
                continue;
            }
            String refCode = row.elementAt(1).toString();
            BigDecimal minValue = (BigDecimal) row.elementAt(3);
            BigDecimal maxValue = (BigDecimal) row.elementAt(4);
            if (shown > 0) {
                sb.append("<br>");
            }
            sb.append(refCode).append(": ")
              .append(minValue != null ? minValue.toPlainString() : "0")
              .append(" - ")
              .append(maxValue != null ? maxValue.toPlainString() : "0");
            shown++;
        }
        return shown > 0 ? sb.toString() : "-";
    }

    public int checkCurrencyCodeExists(String code, int excludeId) throws Exception {
        Connection con = null;
        PreparedStatement pt = null;
        ResultSet rs = null;
        try {
            con = util.DBConnectionManager.getConnectionFromPool();
            pt = con.prepareStatement(
                "SELECT id FROM ce_currency WHERE currency_code = ? AND id <> ?"
            );
            pt.setString(1, code.trim().toUpperCase());
            pt.setInt(2, excludeId);
            rs = pt.executeQuery();
            if (rs.next()) {
                return rs.getInt("id");
            }
            return 0;
        } finally {
            if (rs != null) try { rs.close(); } catch (Exception e) {}
            if (pt != null) try { pt.close(); } catch (Exception e) {}
            if (con != null) try { con.close(); } catch (Exception e) {}
        }
    }

    public void updateCurrency(int id, String code, String name, boolean isBase) throws Exception {
        Connection con = null;
        PreparedStatement pt = null;
        try {
            con = util.DBConnectionManager.getConnectionFromPool();
            con.setAutoCommit(false);

            if (isBase) {
                clearBaseCurrencyFlag(con);
            }

            pt = con.prepareStatement(
                "UPDATE ce_currency SET currency_code = ?, currency_name = ?, is_base = ? WHERE id = ?"
            );
            pt.setString(1, code.trim().toUpperCase());
            pt.setString(2, name.trim());
            pt.setInt(3, isBase ? 1 : 0);
            pt.setInt(4, id);
            pt.executeUpdate();
            con.commit();
        } catch (Exception e) {
            if (con != null) con.rollback();
            throw e;
        } finally {
            if (pt != null) try { pt.close(); } catch (Exception e) {}
            if (con != null) try { con.close(); } catch (Exception e) {}
        }
    }

    public void updateCurrency(int id, String code, String name) throws Exception {
        updateCurrency(id, code, name, false);
    }

    public void replaceCurrencyLimits(int currencyId, int[] refCurrencyIds, BigDecimal[] minValues, BigDecimal[] maxValues) throws Exception {
        Connection con = null;
        PreparedStatement deletePt = null;
        try {
            con = util.DBConnectionManager.getConnectionFromPool();
            con.setAutoCommit(false);
            deletePt = con.prepareStatement("DELETE FROM ce_currency_limit WHERE currency_id = ?");
            deletePt.setInt(1, currencyId);
            deletePt.executeUpdate();
            deletePt.close();
            deletePt = null;
            con.commit();
        } catch (Exception e) {
            if (con != null) con.rollback();
            throw e;
        } finally {
            if (deletePt != null) try { deletePt.close(); } catch (Exception e) {}
            if (con != null) try { con.close(); } catch (Exception e) {}
        }

        saveCurrencyLimits(currencyId, refCurrencyIds, minValues, maxValues);
    }

    public void replaceReverseCurrencyLimits(int refCurrencyId, int[] currencyIds, BigDecimal[] minValues, BigDecimal[] maxValues) throws Exception {
        Connection con = null;
        PreparedStatement deletePt = null;
        try {
            con = util.DBConnectionManager.getConnectionFromPool();
            con.setAutoCommit(false);
            deletePt = con.prepareStatement("DELETE FROM ce_currency_limit WHERE ref_currency_id = ?");
            deletePt.setInt(1, refCurrencyId);
            deletePt.executeUpdate();
            deletePt.close();
            deletePt = null;
            con.commit();
        } catch (Exception e) {
            if (con != null) con.rollback();
            throw e;
        } finally {
            if (deletePt != null) try { deletePt.close(); } catch (Exception e) {}
            if (con != null) try { con.close(); } catch (Exception e) {}
        }

        saveReverseCurrencyLimits(refCurrencyId, currencyIds, minValues, maxValues);
    }

    public void updateCurrencyStatus(int id, int isActive) throws Exception {
        Connection con = null;
        PreparedStatement pt = null;
        try {
            con = util.DBConnectionManager.getConnectionFromPool();
            con.setAutoCommit(false);
            pt = con.prepareStatement("UPDATE ce_currency SET is_active = ? WHERE id = ?");
            pt.setInt(1, isActive);
            pt.setInt(2, id);
            pt.executeUpdate();
            con.commit();
        } catch (Exception e) {
            if (con != null) con.rollback();
            throw e;
        } finally {
            if (pt != null) try { pt.close(); } catch (Exception e) {}
            if (con != null) try { con.close(); } catch (Exception e) {}
        }
    }

    public int addCustomer(String name, String phoneNumber, String address, String notes) throws Exception {
        Connection con = null;
        PreparedStatement pt = null;
        PreparedStatement accPt = null;
        ResultSet rs = null;
        try {
            con = util.DBConnectionManager.getConnectionFromPool();
            con.setAutoCommit(false);

            pt = con.prepareStatement(
                "INSERT INTO ce_customer (name, phone_number, address, notes, is_active) VALUES (?, ?, ?, ?, 1)",
                Statement.RETURN_GENERATED_KEYS
            );
            pt.setString(1, name.trim());
            if (phoneNumber != null && phoneNumber.trim().length() > 0) {
                pt.setString(2, phoneNumber.trim());
            } else {
                pt.setNull(2, java.sql.Types.VARCHAR);
            }
            if (address != null && address.trim().length() > 0) {
                pt.setString(3, address.trim());
            } else {
                pt.setNull(3, java.sql.Types.LONGVARCHAR);
            }
            if (notes != null && notes.trim().length() > 0) {
                pt.setString(4, notes.trim());
            } else {
                pt.setNull(4, java.sql.Types.LONGVARCHAR);
            }
            pt.executeUpdate();

            rs = pt.getGeneratedKeys();
            if (!rs.next()) {
                throw new Exception("Failed to create customer");
            }
            int customerId = rs.getInt(1);
            rs.close();
            rs = null;

            accPt = con.prepareStatement(
                "INSERT INTO ce_customer_account (customer_id, advance, due) VALUES (?, 0, 0)"
            );
            accPt.setInt(1, customerId);
            accPt.executeUpdate();

            con.commit();
            return customerId;
        } catch (Exception e) {
            if (con != null) con.rollback();
            throw e;
        } finally {
            if (rs != null) try { rs.close(); } catch (Exception e) {}
            if (accPt != null) try { accPt.close(); } catch (Exception e) {}
            if (pt != null) try { pt.close(); } catch (Exception e) {}
            if (con != null) try { con.close(); } catch (Exception e) {}
        }
    }

    public Vector getCustomerList() throws Exception {
        Connection con = null;
        PreparedStatement pt = null;
        ResultSet rs = null;
        Vector list = new Vector();
        try {
            con = util.DBConnectionManager.getConnectionFromPool();
            pt = con.prepareStatement(
                "SELECT id, name, phone_number, address, notes, is_active FROM ce_customer ORDER BY name"
            );
            rs = pt.executeQuery();
            while (rs.next()) {
                Vector row = new Vector();
                row.addElement(rs.getInt("id"));
                row.addElement(rs.getString("name"));
                row.addElement(rs.getString("phone_number"));
                row.addElement(rs.getString("address"));
                row.addElement(rs.getString("notes"));
                row.addElement(rs.getInt("is_active"));
                list.addElement(row);
            }
            return list;
        } finally {
            if (rs != null) try { rs.close(); } catch (Exception e) {}
            if (pt != null) try { pt.close(); } catch (Exception e) {}
            if (con != null) try { con.close(); } catch (Exception e) {}
        }
    }

    /**
     * Customers with outstanding advance and/or due.
     * filterType: all | advance | due
     * keyword: optional name/phone filter
     * Returns: id, name, phone, advance, due
     */
    public Vector getCustomersWithBalance(String filterType, String keyword) throws Exception {
        Connection con = null;
        PreparedStatement pt = null;
        ResultSet rs = null;
        Vector list = new Vector();
        try {
            con = util.DBConnectionManager.getConnectionFromPool();
            String type = filterType != null ? filterType.trim().toLowerCase() : "all";
            StringBuilder sql = new StringBuilder(
                "SELECT c.id, c.name, c.phone_number, a.advance, a.due " +
                "FROM ce_customer_account a " +
                "INNER JOIN ce_customer c ON c.id = a.customer_id " +
                "WHERE c.is_active = 1 "
            );

            if ("advance".equals(type)) {
                sql.append("AND a.advance > 0 ");
            } else if ("due".equals(type)) {
                sql.append("AND a.due > 0 ");
            } else {
                sql.append("AND (a.advance > 0 OR a.due > 0) ");
            }

            boolean hasKeyword = keyword != null && keyword.trim().length() > 0;
            if (hasKeyword) {
                sql.append("AND (c.name LIKE ? OR c.phone_number LIKE ?) ");
            }
            sql.append("ORDER BY c.name");

            pt = con.prepareStatement(sql.toString());
            if (hasKeyword) {
                String like = "%" + keyword.trim() + "%";
                pt.setString(1, like);
                pt.setString(2, like);
            }

            rs = pt.executeQuery();
            while (rs.next()) {
                Vector row = new Vector();
                row.addElement(rs.getInt("id"));
                row.addElement(rs.getString("name"));
                row.addElement(rs.getString("phone_number"));
                row.addElement(safeAmount(rs.getBigDecimal("advance")));
                row.addElement(safeAmount(rs.getBigDecimal("due")));
                list.addElement(row);
            }
            return list;
        } finally {
            if (rs != null) try { rs.close(); } catch (Exception e) {}
            if (pt != null) try { pt.close(); } catch (Exception e) {}
            if (con != null) try { con.close(); } catch (Exception e) {}
        }
    }

    public Vector getCustomerById(int id) throws Exception {
        Connection con = null;
        PreparedStatement pt = null;
        ResultSet rs = null;
        Vector row = new Vector();
        try {
            con = util.DBConnectionManager.getConnectionFromPool();
            pt = con.prepareStatement(
                "SELECT id, name, phone_number, address, notes, is_active FROM ce_customer WHERE id = ?"
            );
            pt.setInt(1, id);
            rs = pt.executeQuery();
            if (rs.next()) {
                row.addElement(rs.getInt("id"));
                row.addElement(rs.getString("name"));
                row.addElement(rs.getString("phone_number"));
                row.addElement(rs.getString("address"));
                row.addElement(rs.getString("notes"));
                row.addElement(rs.getInt("is_active"));
            }
            return row;
        } finally {
            if (rs != null) try { rs.close(); } catch (Exception e) {}
            if (pt != null) try { pt.close(); } catch (Exception e) {}
            if (con != null) try { con.close(); } catch (Exception e) {}
        }
    }

    public void updateCustomer(int id, String name, String phoneNumber, String address, String notes) throws Exception {
        Connection con = null;
        PreparedStatement pt = null;
        try {
            con = util.DBConnectionManager.getConnectionFromPool();
            con.setAutoCommit(false);
            pt = con.prepareStatement(
                "UPDATE ce_customer SET name = ?, phone_number = ?, address = ?, notes = ? WHERE id = ?"
            );
            pt.setString(1, name.trim());
            if (phoneNumber != null && phoneNumber.trim().length() > 0) {
                pt.setString(2, phoneNumber.trim());
            } else {
                pt.setNull(2, java.sql.Types.VARCHAR);
            }
            if (address != null && address.trim().length() > 0) {
                pt.setString(3, address.trim());
            } else {
                pt.setNull(3, java.sql.Types.LONGVARCHAR);
            }
            if (notes != null && notes.trim().length() > 0) {
                pt.setString(4, notes.trim());
            } else {
                pt.setNull(4, java.sql.Types.LONGVARCHAR);
            }
            pt.setInt(5, id);
            pt.executeUpdate();
            con.commit();
        } catch (Exception e) {
            if (con != null) con.rollback();
            throw e;
        } finally {
            if (pt != null) try { pt.close(); } catch (Exception e) {}
            if (con != null) try { con.close(); } catch (Exception e) {}
        }
    }

    public void updateCustomerStatus(int id, int isActive) throws Exception {
        Connection con = null;
        PreparedStatement pt = null;
        try {
            con = util.DBConnectionManager.getConnectionFromPool();
            con.setAutoCommit(false);
            pt = con.prepareStatement("UPDATE ce_customer SET is_active = ? WHERE id = ?");
            pt.setInt(1, isActive);
            pt.setInt(2, id);
            pt.executeUpdate();
            con.commit();
        } catch (Exception e) {
            if (con != null) con.rollback();
            throw e;
        } finally {
            if (pt != null) try { pt.close(); } catch (Exception e) {}
            if (con != null) try { con.close(); } catch (Exception e) {}
        }
    }

    public Vector searchCustomers(String keyword) throws Exception {
        Connection con = null;
        PreparedStatement pt = null;
        ResultSet rs = null;
        Vector list = new Vector();
        try {
            con = util.DBConnectionManager.getConnectionFromPool();
            pt = con.prepareStatement(
                "SELECT id, name, phone_number, address, notes " +
                "FROM ce_customer " +
                "WHERE is_active = 1 AND (name LIKE ? OR phone_number LIKE ?) " +
                "ORDER BY name LIMIT 20"
            );
            String like = "%" + keyword.trim() + "%";
            pt.setString(1, like);
            pt.setString(2, like);
            rs = pt.executeQuery();
            while (rs.next()) {
                Vector row = new Vector();
                row.addElement(rs.getInt("id"));
                row.addElement(rs.getString("name"));
                row.addElement(rs.getString("phone_number"));
                row.addElement(rs.getString("address"));
                row.addElement(rs.getString("notes"));
                list.addElement(row);
            }
            return list;
        } finally {
            if (rs != null) try { rs.close(); } catch (Exception e) {}
            if (pt != null) try { pt.close(); } catch (Exception e) {}
            if (con != null) try { con.close(); } catch (Exception e) {}
        }
    }

    public Vector getCustomerAccount(int customerId) throws Exception {
        Connection con = null;
        PreparedStatement pt = null;
        ResultSet rs = null;
        Vector row = new Vector();
        try {
            con = util.DBConnectionManager.getConnectionFromPool();
            pt = con.prepareStatement(
                "SELECT customer_id, advance, due FROM ce_customer_account WHERE customer_id = ?"
            );
            pt.setInt(1, customerId);
            rs = pt.executeQuery();
            if (rs.next()) {
                row.addElement(rs.getInt("customer_id"));
                row.addElement(rs.getBigDecimal("advance"));
                row.addElement(rs.getBigDecimal("due"));
            } else {
                row.addElement(customerId);
                row.addElement(BigDecimal.ZERO);
                row.addElement(BigDecimal.ZERO);
            }
            return row;
        } finally {
            if (rs != null) try { rs.close(); } catch (Exception e) {}
            if (pt != null) try { pt.close(); } catch (Exception e) {}
            if (con != null) try { con.close(); } catch (Exception e) {}
        }
    }

    private static final int BILL_TYPE_ADVANCE = 1;
    private static final int BILL_TYPE_DUE = 2;
    private static final int BILL_TYPE_DUE_COLLECTION = 3;
    private static final int BILL_TYPE_ADVANCE_PAYMENT = 6;
    private static final int BILL_TYPE_ADDITIONAL_INCOME = 7;

    private BigDecimal safeAmount(BigDecimal value) {
        return value != null ? value : BigDecimal.ZERO;
    }

    public Vector getPaymentMethods() throws Exception {
        Connection con = null;
        PreparedStatement pt = null;
        ResultSet rs = null;
        Vector list = new Vector();
        try {
            con = util.DBConnectionManager.getConnectionFromPool();
            pt = con.prepareStatement(
                "SELECT id, name, is_cash FROM ce_payment_method WHERE is_active = 1 ORDER BY id"
            );
            rs = pt.executeQuery();
            while (rs.next()) {
                Vector row = new Vector();
                row.addElement(rs.getInt("id"));
                row.addElement(rs.getString("name"));
                row.addElement(rs.getInt("is_cash"));
                list.addElement(row);
            }
            return list;
        } finally {
            if (rs != null) try { rs.close(); } catch (Exception e) {}
            if (pt != null) try { pt.close(); } catch (Exception e) {}
            if (con != null) try { con.close(); } catch (Exception e) {}
        }
    }

    private int getPaymentMethodIsCash(Connection con, int paymentId) throws Exception {
        PreparedStatement pt = null;
        ResultSet rs = null;
        try {
            pt = con.prepareStatement(
                "SELECT is_cash FROM ce_payment_method WHERE id = ? AND is_active = 1"
            );
            pt.setInt(1, paymentId);
            rs = pt.executeQuery();
            if (!rs.next()) {
                throw new Exception("Invalid payment method selected");
            }
            return rs.getInt("is_cash");
        } finally {
            if (rs != null) try { rs.close(); } catch (Exception e) {}
            if (pt != null) try { pt.close(); } catch (Exception e) {}
        }
    }

    private BigDecimal[] resolveCashBankAmounts(Connection con, int paymentId, BigDecimal amount) throws Exception {
        int isCash = getPaymentMethodIsCash(con, paymentId);
        BigDecimal[] cashBank = new BigDecimal[2];
        if (isCash == 1) {
            cashBank[0] = amount;
            cashBank[1] = BigDecimal.ZERO;
        } else {
            cashBank[0] = BigDecimal.ZERO;
            cashBank[1] = amount;
        }
        return cashBank;
    }

    private int getBaseCurrencyId(Connection con) throws Exception {
        PreparedStatement pt = null;
        ResultSet rs = null;
        try {
            pt = con.prepareStatement(
                "SELECT id FROM ce_currency WHERE is_base = 1 AND is_active = 1 LIMIT 1"
            );
            rs = pt.executeQuery();
            if (rs.next()) {
                return rs.getInt("id");
            }
            return 0;
        } finally {
            if (rs != null) try { rs.close(); } catch (Exception e) {}
            if (pt != null) try { pt.close(); } catch (Exception e) {}
        }
    }

    private String getCurrencyCode(Connection con, int currencyId) throws Exception {
        PreparedStatement pt = null;
        ResultSet rs = null;
        try {
            pt = con.prepareStatement(
                "SELECT currency_code FROM ce_currency WHERE id = ?"
            );
            pt.setInt(1, currencyId);
            rs = pt.executeQuery();
            if (rs.next()) {
                return rs.getString("currency_code");
            }
            return "BASE";
        } finally {
            if (rs != null) try { rs.close(); } catch (Exception e) {}
            if (pt != null) try { pt.close(); } catch (Exception e) {}
        }
    }

    private BigDecimal loadStockForUpdate(Connection con, int currencyId) throws Exception {
        PreparedStatement pt = null;
        ResultSet rs = null;
        try {
            pt = con.prepareStatement(
                "SELECT quantity FROM ce_currency_stock WHERE currency_id = ? FOR UPDATE"
            );
            pt.setInt(1, currencyId);
            rs = pt.executeQuery();
            if (rs.next()) {
                return safeAmount(rs.getBigDecimal("quantity"));
            }
            return BigDecimal.ZERO;
        } finally {
            if (rs != null) try { rs.close(); } catch (Exception e) {}
            if (pt != null) try { pt.close(); } catch (Exception e) {}
        }
    }

    private void upsertStock(Connection con, int currencyId, BigDecimal newQty) throws Exception {
        PreparedStatement pt = null;
        try {
            pt = con.prepareStatement(
                "INSERT INTO ce_currency_stock (currency_id, quantity) VALUES (?, ?) " +
                "ON DUPLICATE KEY UPDATE quantity = VALUES(quantity)"
            );
            pt.setInt(1, currencyId);
            pt.setBigDecimal(2, newQty);
            pt.executeUpdate();
        } finally {
            if (pt != null) try { pt.close(); } catch (Exception e) {}
        }
    }

    private void insertStockTransaction(Connection con, int currencyId, int txnType,
            BigDecimal quantity, BigDecimal beforeQty, BigDecimal afterQty) throws Exception {
        PreparedStatement pt = null;
        try {
            pt = con.prepareStatement(
                "INSERT INTO ce_currency_stock_transaction " +
                "(exchange_id, adjustment_id, currency_id, txn_type, quantity, before_qty, after_qty) " +
                "VALUES (NULL, NULL, ?, ?, ?, ?, ?)"
            );
            pt.setInt(1, currencyId);
            pt.setInt(2, txnType);
            pt.setBigDecimal(3, quantity);
            pt.setBigDecimal(4, beforeQty);
            pt.setBigDecimal(5, afterQty);
            pt.executeUpdate();
        } finally {
            if (pt != null) try { pt.close(); } catch (Exception e) {}
        }
    }

    /**
     * Adjust base currency stock when payment method is cash.
     * increase=true  → cash in  (Collect Due)
     * increase=false → cash out (Pay Purchase Balance)
     */
    private void applyBaseCashStockIfNeeded(Connection con, int paymentId, BigDecimal amount,
            boolean increase) throws Exception {
        if (amount == null || amount.compareTo(BigDecimal.ZERO) <= 0) {
            return;
        }
        if (getPaymentMethodIsCash(con, paymentId) != 1) {
            return;
        }

        int baseCurrencyId = getBaseCurrencyId(con);
        if (baseCurrencyId <= 0) {
            throw new Exception("Base currency is not configured in Currency Master");
        }

        BigDecimal beforeQty = loadStockForUpdate(con, baseCurrencyId);
        BigDecimal afterQty;
        int stockTxnType;

        if (increase) {
            afterQty = beforeQty.add(amount);
            stockTxnType = 1; // stock in
        } else {
            if (beforeQty.compareTo(amount) < 0) {
                String code = getCurrencyCode(con, baseCurrencyId);
                throw new Exception("Insufficient " + code + " stock. Available: " + beforeQty.toPlainString());
            }
            afterQty = beforeQty.subtract(amount);
            stockTxnType = 2; // stock out
        }

        upsertStock(con, baseCurrencyId, afterQty);
        insertStockTransaction(con, baseCurrencyId, stockTxnType, amount, beforeQty, afterQty);
    }

    /** Always increases base currency stock (additional income). */
    private void applyBaseStockIncrease(Connection con, BigDecimal amount) throws Exception {
        if (amount == null || amount.compareTo(BigDecimal.ZERO) <= 0) {
            return;
        }
        int baseCurrencyId = getBaseCurrencyId(con);
        if (baseCurrencyId <= 0) {
            throw new Exception("Base currency is not configured in Currency Master");
        }
        BigDecimal beforeQty = loadStockForUpdate(con, baseCurrencyId);
        BigDecimal afterQty = beforeQty.add(amount);
        upsertStock(con, baseCurrencyId, afterQty);
        insertStockTransaction(con, baseCurrencyId, 3, amount, beforeQty, afterQty);
    }

    public void addAdditionalIncome(String particular, BigDecimal amount, String description, int userId) throws Exception {
        if (particular == null || particular.trim().isEmpty()) {
            throw new Exception("Particular is required");
        }
        if (amount == null || amount.compareTo(BigDecimal.ZERO) <= 0) {
            throw new Exception("Income amount must be greater than zero");
        }

        Connection con = null;
        PreparedStatement pt = null;
        PreparedStatement ledgerPt = null;
        try {
            con = util.DBConnectionManager.getConnectionFromPool();
            con.setAutoCommit(false);

            pt = con.prepareStatement(
                "INSERT INTO ce_additional_income (particular, amount, description, income_date, uid, is_active) " +
                "VALUES (?, ?, ?, NOW(), ?, 1)",
                Statement.RETURN_GENERATED_KEYS
            );
            pt.setString(1, particular.trim());
            pt.setBigDecimal(2, amount);
            if (description != null && description.trim().length() > 0) {
                pt.setString(3, description.trim());
            } else {
                pt.setNull(3, java.sql.Types.LONGVARCHAR);
            }
            pt.setInt(4, userId);
            pt.executeUpdate();
            int incomeId = insertGeneratedId(pt);
            pt.close();
            pt = null;

            applyBaseStockIncrease(con, amount);

            ledgerPt = con.prepareStatement(
                "INSERT INTO ce_bill_ledger (bill_type, bill_id, advance, final_advance, due, final_due, is_cash, is_bank, payment_id) " +
                "VALUES (?, ?, 0, 0, 0, 0, ?, 0, NULL)"
            );
            ledgerPt.setInt(1, BILL_TYPE_ADDITIONAL_INCOME);
            ledgerPt.setInt(2, incomeId);
            ledgerPt.setBigDecimal(3, amount);
            ledgerPt.executeUpdate();

            con.commit();
        } catch (Exception e) {
            if (con != null) con.rollback();
            throw e;
        } finally {
            if (ledgerPt != null) try { ledgerPt.close(); } catch (Exception e) {}
            if (pt != null) try { pt.close(); } catch (Exception e) {}
            if (con != null) try { con.close(); } catch (Exception e) {}
        }
    }

    public Vector getAdditionalIncomeReport(String fromDate, String toDate) throws Exception {
        Connection con = null;
        PreparedStatement pt = null;
        ResultSet rs = null;
        Vector list = new Vector();
        try {
            con = util.DBConnectionManager.getConnectionFromPool();
            pt = con.prepareStatement(
                "SELECT ai.income_date, ai.particular, ai.description, ai.amount, COALESCE(u.user_name, '-') AS user_name " +
                "FROM ce_additional_income ai " +
                "LEFT JOIN users u ON u.id = ai.uid " +
                "WHERE ai.is_active = 1 AND DATE(ai.income_date) BETWEEN ? AND ? " +
                "ORDER BY ai.income_date DESC, ai.id DESC"
            );
            pt.setString(1, fromDate);
            pt.setString(2, toDate);
            rs = pt.executeQuery();
            while (rs.next()) {
                Vector row = new Vector();
                row.addElement(rs.getTimestamp("income_date"));
                row.addElement(rs.getString("particular"));
                row.addElement(rs.getString("description"));
                row.addElement(rs.getBigDecimal("amount"));
                row.addElement(rs.getString("user_name"));
                list.addElement(row);
            }
            return list;
        } finally {
            if (rs != null) try { rs.close(); } catch (Exception e) {}
            if (pt != null) try { pt.close(); } catch (Exception e) {}
            if (con != null) try { con.close(); } catch (Exception e) {}
        }
    }

    private void loadAccountBalances(Connection con, int customerId, BigDecimal[] balances) throws Exception {
        PreparedStatement pt = null;
        ResultSet rs = null;
        try {
            pt = con.prepareStatement(
                "SELECT advance, due FROM ce_customer_account WHERE customer_id = ? FOR UPDATE"
            );
            pt.setInt(1, customerId);
            rs = pt.executeQuery();
            if (rs.next()) {
                balances[0] = safeAmount(rs.getBigDecimal("advance"));
                balances[1] = safeAmount(rs.getBigDecimal("due"));
            } else {
                balances[0] = BigDecimal.ZERO;
                balances[1] = BigDecimal.ZERO;
            }
        } finally {
            if (rs != null) try { rs.close(); } catch (Exception e) {}
            if (pt != null) try { pt.close(); } catch (Exception e) {}
        }
    }

    private int insertGeneratedId(PreparedStatement pt) throws Exception {
        ResultSet rs = null;
        try {
            rs = pt.getGeneratedKeys();
            if (!rs.next()) {
                throw new Exception("Failed to generate transaction id");
            }
            return rs.getInt(1);
        } finally {
            if (rs != null) try { rs.close(); } catch (Exception e) {}
        }
    }

    private void insertBillLedger(Connection con, int customerId, int billType, int billId,
            BigDecimal advance, BigDecimal finalAdvance, BigDecimal due, BigDecimal finalDue,
            BigDecimal isCash, BigDecimal isBank, int paymentId) throws Exception {
        PreparedStatement pt = null;
        try {
            pt = con.prepareStatement(
                "INSERT INTO ce_bill_ledger (customer_id, bill_type, bill_id, advance, final_advance, due, final_due, is_cash, is_bank, payment_id) " +
                "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)"
            );
            pt.setInt(1, customerId);
            pt.setInt(2, billType);
            pt.setInt(3, billId);
            pt.setBigDecimal(4, advance);
            pt.setBigDecimal(5, finalAdvance);
            pt.setBigDecimal(6, due);
            pt.setBigDecimal(7, finalDue);
            pt.setBigDecimal(8, isCash);
            pt.setBigDecimal(9, isBank);
            pt.setInt(10, paymentId);
            pt.executeUpdate();
        } finally {
            if (pt != null) try { pt.close(); } catch (Exception e) {}
        }
    }

    public void addAdvance(int customerId, BigDecimal amount, String notes, int paymentId) throws Exception {
        if (amount == null || amount.compareTo(BigDecimal.ZERO) <= 0) {
            throw new Exception("Advance amount must be greater than zero");
        }
        if (paymentId <= 0) {
            throw new Exception("Payment method is required");
        }

        Connection con = null;
        PreparedStatement histPt = null;
        PreparedStatement accPt = null;
        try {
            con = util.DBConnectionManager.getConnectionFromPool();
            con.setAutoCommit(false);

            BigDecimal[] cashBank = resolveCashBankAmounts(con, paymentId, amount);

            BigDecimal[] balances = new BigDecimal[2];
            loadAccountBalances(con, customerId, balances);
            BigDecimal beforeAdvance = balances[0];
            BigDecimal beforeDue = balances[1];
            BigDecimal afterAdvance = beforeAdvance.add(amount);

            histPt = con.prepareStatement(
                "INSERT INTO ce_cus_advance (customer_id, amount, notes, payment_id) VALUES (?, ?, ?, ?)",
                Statement.RETURN_GENERATED_KEYS
            );
            histPt.setInt(1, customerId);
            histPt.setBigDecimal(2, amount);
            if (notes != null && notes.trim().length() > 0) {
                histPt.setString(3, notes.trim());
            } else {
                histPt.setNull(3, java.sql.Types.LONGVARCHAR);
            }
            histPt.setInt(4, paymentId);
            histPt.executeUpdate();
            int billId = insertGeneratedId(histPt);
            histPt.close();
            histPt = null;

            accPt = con.prepareStatement(
                "UPDATE ce_customer_account SET advance = advance + ? WHERE customer_id = ?"
            );
            accPt.setBigDecimal(1, amount);
            accPt.setInt(2, customerId);
            int updated = accPt.executeUpdate();
            if (updated == 0) {
                accPt.close();
                accPt = con.prepareStatement(
                    "INSERT INTO ce_customer_account (customer_id, advance, due) VALUES (?, ?, 0)"
                );
                accPt.setInt(1, customerId);
                accPt.setBigDecimal(2, amount);
                accPt.executeUpdate();
            }
            accPt.close();
            accPt = null;

            insertBillLedger(con, customerId, BILL_TYPE_ADVANCE, billId,
                beforeAdvance, afterAdvance, beforeDue, beforeDue, cashBank[0], cashBank[1], paymentId);

            con.commit();
        } catch (Exception e) {
            if (con != null) con.rollback();
            throw e;
        } finally {
            if (histPt != null) try { histPt.close(); } catch (Exception e) {}
            if (accPt != null) try { accPt.close(); } catch (Exception e) {}
            if (con != null) try { con.close(); } catch (Exception e) {}
        }
    }

    public void addDue(int customerId, BigDecimal amount, String notes, int paymentId) throws Exception {
        if (amount == null || amount.compareTo(BigDecimal.ZERO) <= 0) {
            throw new Exception("Due amount must be greater than zero");
        }
        if (paymentId <= 0) {
            throw new Exception("Payment method is required");
        }

        Connection con = null;
        PreparedStatement histPt = null;
        PreparedStatement accPt = null;
        try {
            con = util.DBConnectionManager.getConnectionFromPool();
            con.setAutoCommit(false);

            BigDecimal[] cashBank = resolveCashBankAmounts(con, paymentId, amount);

            BigDecimal[] balances = new BigDecimal[2];
            loadAccountBalances(con, customerId, balances);
            BigDecimal beforeAdvance = balances[0];
            BigDecimal beforeDue = balances[1];
            BigDecimal afterDue = beforeDue.add(amount);

            histPt = con.prepareStatement(
                "INSERT INTO ce_cus_due (customer_id, amount, notes, payment_id) VALUES (?, ?, ?, ?)",
                Statement.RETURN_GENERATED_KEYS
            );
            histPt.setInt(1, customerId);
            histPt.setBigDecimal(2, amount);
            if (notes != null && notes.trim().length() > 0) {
                histPt.setString(3, notes.trim());
            } else {
                histPt.setNull(3, java.sql.Types.LONGVARCHAR);
            }
            histPt.setInt(4, paymentId);
            histPt.executeUpdate();
            int billId = insertGeneratedId(histPt);
            histPt.close();
            histPt = null;

            accPt = con.prepareStatement(
                "UPDATE ce_customer_account SET due = due + ? WHERE customer_id = ?"
            );
            accPt.setBigDecimal(1, amount);
            accPt.setInt(2, customerId);
            int updated = accPt.executeUpdate();
            if (updated == 0) {
                accPt.close();
                accPt = con.prepareStatement(
                    "INSERT INTO ce_customer_account (customer_id, advance, due) VALUES (?, 0, ?)"
                );
                accPt.setInt(1, customerId);
                accPt.setBigDecimal(2, amount);
                accPt.executeUpdate();
            }
            accPt.close();
            accPt = null;

            insertBillLedger(con, customerId, BILL_TYPE_DUE, billId,
                beforeAdvance, beforeAdvance, beforeDue, afterDue, cashBank[0], cashBank[1], paymentId);

            con.commit();
        } catch (Exception e) {
            if (con != null) con.rollback();
            throw e;
        } finally {
            if (histPt != null) try { histPt.close(); } catch (Exception e) {}
            if (accPt != null) try { accPt.close(); } catch (Exception e) {}
            if (con != null) try { con.close(); } catch (Exception e) {}
        }
    }

    public void collectDue(int customerId, BigDecimal amount, String notes, int paymentId) throws Exception {
        if (amount == null || amount.compareTo(BigDecimal.ZERO) <= 0) {
            throw new Exception("Collection amount must be greater than zero");
        }
        if (paymentId <= 0) {
            throw new Exception("Payment method is required");
        }

        Connection con = null;
        PreparedStatement histPt = null;
        PreparedStatement accPt = null;
        try {
            con = util.DBConnectionManager.getConnectionFromPool();
            con.setAutoCommit(false);

            BigDecimal[] cashBank = resolveCashBankAmounts(con, paymentId, amount);

            BigDecimal[] balances = new BigDecimal[2];
            loadAccountBalances(con, customerId, balances);
            BigDecimal beforeAdvance = balances[0];
            BigDecimal beforeDue = balances[1];

            if (amount.compareTo(beforeDue) > 0) {
                throw new Exception("Collection amount cannot exceed current due balance");
            }

            BigDecimal afterDue = beforeDue.subtract(amount);

            histPt = con.prepareStatement(
                "INSERT INTO ce_cus_due_collection (customer_id, amount, notes, payment_id) VALUES (?, ?, ?, ?)",
                Statement.RETURN_GENERATED_KEYS
            );
            histPt.setInt(1, customerId);
            histPt.setBigDecimal(2, amount);
            if (notes != null && notes.trim().length() > 0) {
                histPt.setString(3, notes.trim());
            } else {
                histPt.setNull(3, java.sql.Types.LONGVARCHAR);
            }
            histPt.setInt(4, paymentId);
            histPt.executeUpdate();
            int billId = insertGeneratedId(histPt);
            histPt.close();
            histPt = null;

            accPt = con.prepareStatement(
                "UPDATE ce_customer_account SET due = due - ? WHERE customer_id = ?"
            );
            accPt.setBigDecimal(1, amount);
            accPt.setInt(2, customerId);
            accPt.executeUpdate();
            accPt.close();
            accPt = null;

            // Cash due collection → base currency stock increases
            applyBaseCashStockIfNeeded(con, paymentId, amount, true);

            insertBillLedger(con, customerId, BILL_TYPE_DUE_COLLECTION, billId,
                beforeAdvance, beforeAdvance, beforeDue, afterDue, cashBank[0], cashBank[1], paymentId);

            con.commit();
        } catch (Exception e) {
            if (con != null) con.rollback();
            throw e;
        } finally {
            if (histPt != null) try { histPt.close(); } catch (Exception e) {}
            if (accPt != null) try { accPt.close(); } catch (Exception e) {}
            if (con != null) try { con.close(); } catch (Exception e) {}
        }
    }

    public void payAdvance(int customerId, BigDecimal amount, String notes, int paymentId) throws Exception {
        if (amount == null || amount.compareTo(BigDecimal.ZERO) <= 0) {
            throw new Exception("Pay amount must be greater than zero");
        }
        if (paymentId <= 0) {
            throw new Exception("Payment method is required");
        }

        Connection con = null;
        PreparedStatement histPt = null;
        PreparedStatement accPt = null;
        try {
            con = util.DBConnectionManager.getConnectionFromPool();
            con.setAutoCommit(false);

            BigDecimal[] cashBank = resolveCashBankAmounts(con, paymentId, amount);

            BigDecimal[] balances = new BigDecimal[2];
            loadAccountBalances(con, customerId, balances);
            BigDecimal beforeAdvance = balances[0];
            BigDecimal beforeDue = balances[1];

            if (amount.compareTo(beforeAdvance) > 0) {
                throw new Exception("Pay amount cannot exceed current purchase balance");
            }

            BigDecimal afterAdvance = beforeAdvance.subtract(amount);

            histPt = con.prepareStatement(
                "INSERT INTO ce_cus_advance_payment (customer_id, amount, notes, payment_id) VALUES (?, ?, ?, ?)",
                Statement.RETURN_GENERATED_KEYS
            );
            histPt.setInt(1, customerId);
            histPt.setBigDecimal(2, amount);
            if (notes != null && notes.trim().length() > 0) {
                histPt.setString(3, notes.trim());
            } else {
                histPt.setNull(3, java.sql.Types.LONGVARCHAR);
            }
            histPt.setInt(4, paymentId);
            histPt.executeUpdate();
            int billId = insertGeneratedId(histPt);
            histPt.close();
            histPt = null;

            accPt = con.prepareStatement(
                "UPDATE ce_customer_account SET advance = advance - ? WHERE customer_id = ?"
            );
            accPt.setBigDecimal(1, amount);
            accPt.setInt(2, customerId);
            accPt.executeUpdate();
            accPt.close();
            accPt = null;

            // Cash purchase-balance pay → base currency stock decreases
            applyBaseCashStockIfNeeded(con, paymentId, amount, false);

            insertBillLedger(con, customerId, BILL_TYPE_ADVANCE_PAYMENT, billId,
                beforeAdvance, afterAdvance, beforeDue, beforeDue, cashBank[0], cashBank[1], paymentId);

            con.commit();
        } catch (Exception e) {
            if (con != null) con.rollback();
            throw e;
        } finally {
            if (histPt != null) try { histPt.close(); } catch (Exception e) {}
            if (accPt != null) try { accPt.close(); } catch (Exception e) {}
            if (con != null) try { con.close(); } catch (Exception e) {}
        }
    }

    public Vector getCustomerTransactions(int customerId) throws Exception {
        return getCustomerTransactions(customerId, null, null);
    }

    private String buildCustomerTransactionsSql(boolean includeAdjustColumns) {
        String adjustCols = includeAdjustColumns
            ? "e.due_adjusted AS due_adjusted_amount, e.advance_adjusted AS advance_adjusted_amount, "
            : "0 AS due_adjusted_amount, 0 AS advance_adjusted_amount, ";
        return "SELECT " +
            "CASE l.bill_type " +
            "  WHEN 1 THEN 'Advance' " +
            "  WHEN 2 THEN 'Due' " +
            "  WHEN 3 THEN 'Due Collection' " +
            "  WHEN 4 AND e.exchange_type = 1 THEN 'Exchange - Purchase' " +
            "  WHEN 4 AND e.exchange_type = 2 THEN 'Exchange - Sale' " +
            "  WHEN 6 THEN 'Purchase Balance Pay' " +
            "  ELSE bt.name END AS entry_type, " +
            "COALESCE(a.amount, d.amount, c.amount, ap.amount, e.counter_amount) AS amount, " +
            "e.counter_amount AS bill_amount, " +
            "e.paid AS paid_amount, " +
            "e.balance AS balance_amount, " +
            adjustCols +
            "COALESCE(a.notes, d.notes, c.notes, ap.notes, e.notes) AS notes, " +
            "l.created_at, l.advance, l.final_advance, l.due, l.final_due, " +
            "COALESCE(pm.name, '-') AS payment_method, l.is_cash, l.is_bank, l.bill_type " +
            "FROM ce_bill_ledger l " +
            "INNER JOIN ce_bill_type bt ON bt.id = l.bill_type " +
            "LEFT JOIN ce_cus_advance a ON l.bill_type = 1 AND a.id = l.bill_id " +
            "LEFT JOIN ce_cus_due d ON l.bill_type = 2 AND d.id = l.bill_id " +
            "LEFT JOIN ce_cus_due_collection c ON l.bill_type = 3 AND c.id = l.bill_id " +
            "LEFT JOIN ce_cus_advance_payment ap ON l.bill_type = 6 AND ap.id = l.bill_id " +
            "LEFT JOIN ce_currency_exchange e ON l.bill_type = 4 AND e.id = l.bill_id AND e.is_cancelled = 0 " +
            "LEFT JOIN ce_payment_method pm ON pm.id = COALESCE(l.payment_id, a.payment_id, d.payment_id, c.payment_id, ap.payment_id, e.payment_id) " +
            "WHERE l.customer_id = ? ";
    }

    private Vector readCustomerTransactionRows(ResultSet rs) throws Exception {
        Vector list = new Vector();
        while (rs.next()) {
            Vector row = new Vector();
            row.addElement(rs.getString("entry_type"));
            row.addElement(rs.getBigDecimal("amount"));
            row.addElement(rs.getString("notes"));
            row.addElement(rs.getTimestamp("created_at"));
            row.addElement(rs.getBigDecimal("advance"));
            row.addElement(rs.getBigDecimal("final_advance"));
            row.addElement(rs.getBigDecimal("due"));
            row.addElement(rs.getBigDecimal("final_due"));
            row.addElement(rs.getString("payment_method"));
            row.addElement(rs.getBigDecimal("is_cash"));
            row.addElement(rs.getBigDecimal("is_bank"));
            row.addElement(rs.getBigDecimal("bill_amount"));
            row.addElement(rs.getBigDecimal("paid_amount"));
            row.addElement(rs.getBigDecimal("balance_amount"));
            row.addElement(rs.getBigDecimal("due_adjusted_amount"));
            row.addElement(rs.getBigDecimal("advance_adjusted_amount"));
            row.addElement(Integer.valueOf(rs.getInt("bill_type")));
            list.addElement(row);
        }
        return list;
    }

    private Vector queryCustomerTransactions(Connection con, int customerId, String fromDate, String toDate,
            boolean includeAdjustColumns) throws Exception {
        PreparedStatement pt = null;
        ResultSet rs = null;
        try {
            StringBuilder sql = new StringBuilder(buildCustomerTransactionsSql(includeAdjustColumns));
            boolean hasFrom = fromDate != null && fromDate.trim().length() > 0;
            boolean hasTo = toDate != null && toDate.trim().length() > 0;
            if (hasFrom) {
                sql.append("AND DATE(l.created_at) >= ? ");
            }
            if (hasTo) {
                sql.append("AND DATE(l.created_at) <= ? ");
            }
            sql.append("ORDER BY l.created_at DESC, l.id DESC");

            pt = con.prepareStatement(sql.toString());
            int param = 1;
            pt.setInt(param++, customerId);
            if (hasFrom) {
                pt.setString(param++, fromDate.trim());
            }
            if (hasTo) {
                pt.setString(param++, toDate.trim());
            }
            rs = pt.executeQuery();
            return readCustomerTransactionRows(rs);
        } finally {
            if (rs != null) try { rs.close(); } catch (Exception e) {}
            if (pt != null) try { pt.close(); } catch (Exception e) {}
        }
    }

    public Vector getCustomerTransactions(int customerId, String fromDate, String toDate) throws Exception {
        Connection con = null;
        try {
            con = util.DBConnectionManager.getConnectionFromPool();
            try {
                return queryCustomerTransactions(con, customerId, fromDate, toDate, true);
            } catch (SQLException ex) {
                String msg = ex.getMessage() != null ? ex.getMessage().toLowerCase() : "";
                if (msg.indexOf("due_adjusted") >= 0 || msg.indexOf("advance_adjusted") >= 0) {
                    return queryCustomerTransactions(con, customerId, fromDate, toDate, false);
                }
                throw ex;
            }
        } finally {
            if (con != null) try { con.close(); } catch (Exception e) {}
        }
    }
}
