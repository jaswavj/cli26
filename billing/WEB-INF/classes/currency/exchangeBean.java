package currency;

import java.math.BigDecimal;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.Statement;
import java.util.Vector;

public class exchangeBean {

    private static final int EXCHANGE_TYPE_PURCHASE = 1;
    private static final int EXCHANGE_TYPE_SALE = 2;
    private static final int STOCK_TXN_IN = 1;
    private static final int STOCK_TXN_OUT = 2;
    private static final int STOCK_TXN_ADJUST_IN = 3;
    private static final int STOCK_TXN_ADJUST_OUT = 4;
    private static final int ADJUST_TYPE_ADD = 1;
    private static final int ADJUST_TYPE_REMOVE = 2;
    private static final int BILL_TYPE_EXCHANGE = 4;

    public exchangeBean() {
    }

    public int findOrCreateCustomer(String name, String phone) throws Exception {
        if (name == null || name.trim().isEmpty()) {
            throw new Exception("Customer name is required");
        }

        Connection con = null;
        PreparedStatement pt = null;
        ResultSet rs = null;
        try {
            con = util.DBConnectionManager.getConnectionFromPool();

            if (phone != null && phone.trim().length() > 0) {
                pt = con.prepareStatement(
                    "SELECT id FROM ce_customer WHERE is_active = 1 AND phone_number = ? LIMIT 1"
                );
                pt.setString(1, phone.trim());
                rs = pt.executeQuery();
                if (rs.next()) {
                    return rs.getInt("id");
                }
                rs.close();
                pt.close();
            }

            pt = con.prepareStatement(
                "SELECT id FROM ce_customer WHERE is_active = 1 AND name = ? LIMIT 1"
            );
            pt.setString(1, name.trim());
            rs = pt.executeQuery();
            if (rs.next()) {
                return rs.getInt("id");
            }
            rs.close();
            pt.close();

            currencyBean customerBean = new currencyBean();
            return customerBean.addCustomer(name.trim(), phone, null, null);
        } finally {
            if (rs != null) try { rs.close(); } catch (Exception e) {}
            if (pt != null) try { pt.close(); } catch (Exception e) {}
            if (con != null) try { con.close(); } catch (Exception e) {}
        }
    }

    public Vector getCurrenciesWithLimits() throws Exception {
        Connection con = null;
        PreparedStatement pt = null;
        ResultSet rs = null;
        Vector list = new Vector();
        try {
            con = util.DBConnectionManager.getConnectionFromPool();
            pt = con.prepareStatement(
                "SELECT c.id, c.currency_code, c.currency_name, " +
                "COALESCE(MIN(l.min_value), 0) AS min_value, COALESCE(MAX(l.max_value), 0) AS max_value, " +
                "COALESCE(s.quantity, 0) AS stock_qty " +
                "FROM ce_currency c " +
                "LEFT JOIN ce_currency_limit l ON l.currency_id = c.id " +
                "LEFT JOIN ce_currency_stock s ON s.currency_id = c.id " +
                "WHERE c.is_active = 1 " +
                "GROUP BY c.id, c.currency_code, c.currency_name, s.quantity " +
                "ORDER BY c.currency_code"
            );
            rs = pt.executeQuery();
            while (rs.next()) {
                Vector row = new Vector();
                row.addElement(rs.getInt("id"));
                row.addElement(rs.getString("currency_code"));
                row.addElement(rs.getString("currency_name"));
                row.addElement(rs.getBigDecimal("min_value"));
                row.addElement(rs.getBigDecimal("max_value"));
                row.addElement(rs.getBigDecimal("stock_qty"));
                list.addElement(row);
            }
            return list;
        } finally {
            if (rs != null) try { rs.close(); } catch (Exception e) {}
            if (pt != null) try { pt.close(); } catch (Exception e) {}
            if (con != null) try { con.close(); } catch (Exception e) {}
        }
    }

    private BigDecimal safeAmount(BigDecimal value) {
        return value != null ? value : BigDecimal.ZERO;
    }

    private int insertGeneratedId(PreparedStatement pt) throws Exception {
        ResultSet rs = null;
        try {
            rs = pt.getGeneratedKeys();
            if (!rs.next()) {
                throw new Exception("Failed to generate id");
            }
            return rs.getInt(1);
        } finally {
            if (rs != null) try { rs.close(); } catch (Exception e) {}
        }
    }

    private void loadAccountBalances(Connection con, int customerId, BigDecimal[] balances) throws Exception {
        PreparedStatement pt = null;
        ResultSet rs = null;
        try {
            pt = con.prepareStatement(
                "SELECT advance, due FROM ce_customer_account WHERE customer_id = ?"
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

    public Vector getCurrencyPairLimits(int currencyId, int counterCurrencyId) throws Exception {
        Connection con = null;
        PreparedStatement pt = null;
        ResultSet rs = null;
        Vector row = new Vector();
        try {
            con = util.DBConnectionManager.getConnectionFromPool();
            pt = con.prepareStatement(
                "SELECT min_value, max_value FROM ce_currency_limit " +
                "WHERE currency_id = ? AND ref_currency_id = ?"
            );
            pt.setInt(1, currencyId);
            pt.setInt(2, counterCurrencyId);
            rs = pt.executeQuery();
            if (rs.next()) {
                row.addElement(safeAmount(rs.getBigDecimal("min_value")));
                row.addElement(safeAmount(rs.getBigDecimal("max_value")));
            } else {
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

    private void validateExchangeRate(Connection con, int currencyId, int counterCurrencyId,
            BigDecimal exchangeRate, String mainCode, String counterCode) throws Exception {
        PreparedStatement pt = null;
        ResultSet rs = null;
        try {
            pt = con.prepareStatement(
                "SELECT min_value, max_value FROM ce_currency_limit " +
                "WHERE currency_id = ? AND ref_currency_id = ?"
            );
            pt.setInt(1, currencyId);
            pt.setInt(2, counterCurrencyId);
            rs = pt.executeQuery();
            if (rs.next()) {
                BigDecimal minValue = safeAmount(rs.getBigDecimal("min_value"));
                BigDecimal maxValue = safeAmount(rs.getBigDecimal("max_value"));
                if (maxValue.compareTo(BigDecimal.ZERO) > 0) {
                    if (exchangeRate.compareTo(minValue) < 0 || exchangeRate.compareTo(maxValue) > 0) {
                        throw new Exception("Exchange rate must be between " + minValue.toPlainString()
                            + " and " + maxValue.toPlainString() + " " + counterCode + " per 1 " + mainCode);
                    }
                }
            }
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

    public int getCurrencyIdByCode(String code) throws Exception {
        Connection con = null;
        PreparedStatement pt = null;
        ResultSet rs = null;
        try {
            con = util.DBConnectionManager.getConnectionFromPool();
            pt = con.prepareStatement(
                "SELECT id FROM ce_currency WHERE currency_code = ? AND is_active = 1 LIMIT 1"
            );
            pt.setString(1, code.trim().toUpperCase());
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
            pt = con.prepareStatement("SELECT currency_code FROM ce_currency WHERE id = ?");
            pt.setInt(1, currencyId);
            rs = pt.executeQuery();
            if (rs.next()) {
                return rs.getString("currency_code");
            }
            return "Currency";
        } finally {
            if (rs != null) try { rs.close(); } catch (Exception e) {}
            if (pt != null) try { pt.close(); } catch (Exception e) {}
        }
    }

    private void applyStockMovement(Connection con, int exchangeId, int currencyId,
            boolean increase, BigDecimal quantity) throws Exception {
        BigDecimal beforeQty = loadStockForUpdate(con, currencyId);
        BigDecimal afterQty;
        int stockTxnType;

        if (increase) {
            afterQty = beforeQty.add(quantity);
            stockTxnType = STOCK_TXN_IN;
        } else {
            if (beforeQty.compareTo(quantity) < 0) {
                String code = getCurrencyCode(con, currencyId);
                throw new Exception("Insufficient " + code + " stock. Available: " + beforeQty.toPlainString());
            }
            afterQty = beforeQty.subtract(quantity);
            stockTxnType = STOCK_TXN_OUT;
        }

        upsertStock(con, currencyId, afterQty);
        insertStockTransaction(con, Integer.valueOf(exchangeId), null, currencyId, stockTxnType,
            quantity, beforeQty, afterQty);
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

    private void insertStockTransaction(Connection con, Integer exchangeId, Integer adjustmentId,
            int currencyId, int txnType, BigDecimal quantity, BigDecimal beforeQty, BigDecimal afterQty) throws Exception {
        PreparedStatement pt = null;
        try {
            pt = con.prepareStatement(
                "INSERT INTO ce_currency_stock_transaction " +
                "(exchange_id, adjustment_id, currency_id, txn_type, quantity, before_qty, after_qty) " +
                "VALUES (?, ?, ?, ?, ?, ?, ?)"
            );
            if (exchangeId != null) {
                pt.setInt(1, exchangeId.intValue());
            } else {
                pt.setNull(1, java.sql.Types.INTEGER);
            }
            if (adjustmentId != null) {
                pt.setInt(2, adjustmentId.intValue());
            } else {
                pt.setNull(2, java.sql.Types.INTEGER);
            }
            pt.setInt(3, currencyId);
            pt.setInt(4, txnType);
            pt.setBigDecimal(5, quantity);
            pt.setBigDecimal(6, beforeQty);
            pt.setBigDecimal(7, afterQty);
            pt.executeUpdate();
        } finally {
            if (pt != null) try { pt.close(); } catch (Exception e) {}
        }
    }

    private void insertBillLedger(Connection con, int customerId, int billId, BigDecimal advance,
            BigDecimal finalAdvance, BigDecimal due, BigDecimal finalDue,
            BigDecimal isCash, BigDecimal isBank, int paymentId) throws Exception {
        PreparedStatement pt = null;
        try {
            pt = con.prepareStatement(
                "INSERT INTO ce_bill_ledger " +
                "(customer_id, bill_type, bill_id, advance, final_advance, due, final_due, is_cash, is_bank, payment_id) " +
                "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)"
            );
            pt.setInt(1, customerId);
            pt.setInt(2, BILL_TYPE_EXCHANGE);
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

    public int saveExchange(int customerId, int exchangeType, String exchangeDate, int currencyId,
            BigDecimal amount, int counterCurrencyId, BigDecimal counterAmount,
            int paymentId, String notes, int userId) throws Exception {
        if (customerId <= 0) {
            throw new Exception("Customer is required");
        }
        if (exchangeType != EXCHANGE_TYPE_PURCHASE && exchangeType != EXCHANGE_TYPE_SALE) {
            throw new Exception("Invalid exchange type");
        }
        if (exchangeDate == null || exchangeDate.trim().isEmpty()) {
            throw new Exception("Date is required");
        }
        if (currencyId <= 0) {
            throw new Exception("Currency is required");
        }
        if (amount == null || amount.compareTo(BigDecimal.ZERO) <= 0) {
            throw new Exception("Amount must be greater than zero");
        }
        if (counterAmount == null || counterAmount.compareTo(BigDecimal.ZERO) <= 0) {
            throw new Exception("Counter amount must be greater than zero");
        }
        if (paymentId <= 0) {
            throw new Exception("Payment method is required");
        }

        Connection con = null;
        PreparedStatement pt = null;
        try {
            con = util.DBConnectionManager.getConnectionFromPool();
            con.setAutoCommit(false);

            int baseCurrencyId = getBaseCurrencyId(con);
            if (baseCurrencyId <= 0) {
                throw new Exception("Base currency is not configured in Currency Master");
            }
            if (currencyId == baseCurrencyId) {
                throw new Exception("Main currency cannot be the base currency");
            }
            counterCurrencyId = baseCurrencyId;

            int isCash = getPaymentMethodIsCash(con, paymentId);
            String counterCode = getCurrencyCode(con, counterCurrencyId);

            validateExchangeRate(con, currencyId, counterCurrencyId,
                counterAmount.divide(amount, 4, java.math.RoundingMode.HALF_UP),
                getCurrencyCode(con, currencyId), counterCode);
            BigDecimal[] cashBank = resolveCashBankAmounts(con, paymentId, counterAmount);

            pt = con.prepareStatement(
                "INSERT INTO ce_currency_exchange " +
                "(customer_id, exchange_type, exchange_date, currency_id, amount, counter_currency_id, counter_amount, payment_id, notes, uid, is_cancelled) " +
                "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 0)",
                Statement.RETURN_GENERATED_KEYS
            );
            pt.setInt(1, customerId);
            pt.setInt(2, exchangeType);
            pt.setString(3, exchangeDate.trim());
            pt.setInt(4, currencyId);
            pt.setBigDecimal(5, amount);
            pt.setInt(6, counterCurrencyId);
            pt.setBigDecimal(7, counterAmount);
            pt.setInt(8, paymentId);
            if (notes != null && notes.trim().length() > 0) {
                pt.setString(9, notes.trim());
            } else {
                pt.setNull(9, java.sql.Types.LONGVARCHAR);
            }
            pt.setInt(10, userId);
            pt.executeUpdate();
            int exchangeId = insertGeneratedId(pt);
            pt.close();
            pt = null;

            if (exchangeType == EXCHANGE_TYPE_PURCHASE) {
                applyStockMovement(con, exchangeId, currencyId, true, amount);
                if (isCash == 1) {
                    applyStockMovement(con, exchangeId, counterCurrencyId, false, counterAmount);
                }
            } else {
                applyStockMovement(con, exchangeId, currencyId, false, amount);
                if (isCash == 1) {
                    applyStockMovement(con, exchangeId, counterCurrencyId, true, counterAmount);
                }
            }

            BigDecimal[] balances = new BigDecimal[2];
            loadAccountBalances(con, customerId, balances);
            insertBillLedger(con, customerId, exchangeId, balances[0], balances[0],
                balances[1], balances[1], cashBank[0], cashBank[1], paymentId);

            con.commit();
            return exchangeId;
        } catch (Exception e) {
            if (con != null) con.rollback();
            throw e;
        } finally {
            if (pt != null) try { pt.close(); } catch (Exception e) {}
            if (con != null) try { con.close(); } catch (Exception e) {}
        }
    }

    public int adjustStock(int currencyId, int adjustmentType, BigDecimal quantity, String reason, int userId) throws Exception {
        if (currencyId <= 0) {
            throw new Exception("Currency is required");
        }
        if (adjustmentType != ADJUST_TYPE_ADD && adjustmentType != ADJUST_TYPE_REMOVE) {
            throw new Exception("Invalid adjustment type");
        }
        if (quantity == null || quantity.compareTo(BigDecimal.ZERO) <= 0) {
            throw new Exception("Quantity must be greater than zero");
        }
        if (reason == null || reason.trim().isEmpty()) {
            throw new Exception("Reason is required");
        }

        Connection con = null;
        PreparedStatement pt = null;
        try {
            con = util.DBConnectionManager.getConnectionFromPool();
            con.setAutoCommit(false);

            BigDecimal beforeQty = loadStockForUpdate(con, currencyId);
            BigDecimal afterQty;
            int stockTxnType;

            if (adjustmentType == ADJUST_TYPE_ADD) {
                afterQty = beforeQty.add(quantity);
                stockTxnType = STOCK_TXN_ADJUST_IN;
            } else {
                if (beforeQty.compareTo(quantity) < 0) {
                    throw new Exception("Insufficient stock to remove. Available: " + beforeQty.toPlainString());
                }
                afterQty = beforeQty.subtract(quantity);
                stockTxnType = STOCK_TXN_ADJUST_OUT;
            }

            pt = con.prepareStatement(
                "INSERT INTO ce_currency_stock_adjustment (currency_id, adjustment_type, quantity, reason, uid) " +
                "VALUES (?, ?, ?, ?, ?)",
                Statement.RETURN_GENERATED_KEYS
            );
            pt.setInt(1, currencyId);
            pt.setInt(2, adjustmentType);
            pt.setBigDecimal(3, quantity);
            pt.setString(4, reason.trim());
            pt.setInt(5, userId);
            pt.executeUpdate();
            int adjustmentId = insertGeneratedId(pt);
            pt.close();
            pt = null;

            upsertStock(con, currencyId, afterQty);
            insertStockTransaction(con, null, Integer.valueOf(adjustmentId), currencyId, stockTxnType,
                quantity, beforeQty, afterQty);

            con.commit();
            return adjustmentId;
        } catch (Exception e) {
            if (con != null) con.rollback();
            throw e;
        } finally {
            if (pt != null) try { pt.close(); } catch (Exception e) {}
            if (con != null) try { con.close(); } catch (Exception e) {}
        }
    }

    public Vector getCurrentStockReport() throws Exception {
        Connection con = null;
        PreparedStatement pt = null;
        ResultSet rs = null;
        Vector list = new Vector();
        try {
            con = util.DBConnectionManager.getConnectionFromPool();
            pt = con.prepareStatement(
                "SELECT c.id, c.currency_code, c.currency_name, COALESCE(s.quantity, 0) AS quantity, s.updated_at " +
                "FROM ce_currency c " +
                "LEFT JOIN ce_currency_stock s ON s.currency_id = c.id " +
                "WHERE c.is_active = 1 " +
                "ORDER BY c.currency_code"
            );
            rs = pt.executeQuery();
            while (rs.next()) {
                Vector row = new Vector();
                row.addElement(rs.getInt("id"));
                row.addElement(rs.getString("currency_code"));
                row.addElement(rs.getString("currency_name"));
                row.addElement(rs.getBigDecimal("quantity"));
                row.addElement(rs.getTimestamp("updated_at"));
                list.addElement(row);
            }
            return list;
        } finally {
            if (rs != null) try { rs.close(); } catch (Exception e) {}
            if (pt != null) try { pt.close(); } catch (Exception e) {}
            if (con != null) try { con.close(); } catch (Exception e) {}
        }
    }

    public Vector getStockTransactionReport(String fromDate, String toDate, int currencyId) throws Exception {
        Connection con = null;
        PreparedStatement pt = null;
        ResultSet rs = null;
        Vector list = new Vector();
        try {
            con = util.DBConnectionManager.getConnectionFromPool();
            StringBuilder sql = new StringBuilder(
                "SELECT COALESCE(e.exchange_date, DATE(t.created_at)) AS txn_date, c.currency_code, " +
                "CASE t.txn_type WHEN 1 THEN 'Purchase In' WHEN 2 THEN 'Sale Out' " +
                "WHEN 3 THEN 'Stock Add' WHEN 4 THEN 'Stock Remove' END AS txn_type, " +
                "t.quantity, t.before_qty, t.after_qty, " +
                "COALESCE(cu.name, '-') AS party_name, " +
                "CASE WHEN e.id IS NOT NULL THEN CONCAT('Exch #', e.id) " +
                "WHEN a.id IS NOT NULL THEN CONCAT('Adj #', a.id) ELSE '-' END AS ref_no, " +
                "COALESCE(a.reason, '-') AS reason, t.created_at " +
                "FROM ce_currency_stock_transaction t " +
                "INNER JOIN ce_currency c ON c.id = t.currency_id " +
                "LEFT JOIN ce_currency_exchange e ON e.id = t.exchange_id AND e.is_cancelled = 0 " +
                "LEFT JOIN ce_customer cu ON cu.id = e.customer_id " +
                "LEFT JOIN ce_currency_stock_adjustment a ON a.id = t.adjustment_id " +
                "WHERE DATE(t.created_at) BETWEEN ? AND ? "
            );
            if (currencyId > 0) {
                sql.append("AND t.currency_id = ? ");
            }
            sql.append("ORDER BY t.created_at DESC, t.id DESC");

            pt = con.prepareStatement(sql.toString());
            pt.setString(1, fromDate);
            pt.setString(2, toDate);
            if (currencyId > 0) {
                pt.setInt(3, currencyId);
            }
            rs = pt.executeQuery();
            while (rs.next()) {
                Vector row = new Vector();
                row.addElement(rs.getDate("txn_date"));
                row.addElement(rs.getString("currency_code"));
                row.addElement(rs.getString("txn_type"));
                row.addElement(rs.getBigDecimal("quantity"));
                row.addElement(rs.getBigDecimal("before_qty"));
                row.addElement(rs.getBigDecimal("after_qty"));
                row.addElement(rs.getString("party_name"));
                row.addElement(rs.getString("ref_no"));
                row.addElement(rs.getString("reason"));
                row.addElement(rs.getTimestamp("created_at"));
                list.addElement(row);
            }
            return list;
        } finally {
            if (rs != null) try { rs.close(); } catch (Exception e) {}
            if (pt != null) try { pt.close(); } catch (Exception e) {}
            if (con != null) try { con.close(); } catch (Exception e) {}
        }
    }

    public BigDecimal getLedgerOpeningBalance(String fromDate, boolean cashColumn) throws Exception {
        Connection con = null;
        PreparedStatement pt = null;
        ResultSet rs = null;
        try {
            con = util.DBConnectionManager.getConnectionFromPool();
            String column = cashColumn ? "is_cash" : "is_bank";
            pt = con.prepareStatement(
                "SELECT COALESCE(SUM(" + column + "), 0) AS opening_balance " +
                "FROM ce_bill_ledger WHERE DATE(created_at) < ? AND " + column + " > 0"
            );
            pt.setString(1, fromDate);
            rs = pt.executeQuery();
            if (rs.next()) {
                return safeAmount(rs.getBigDecimal("opening_balance"));
            }
            return BigDecimal.ZERO;
        } finally {
            if (rs != null) try { rs.close(); } catch (Exception e) {}
            if (pt != null) try { pt.close(); } catch (Exception e) {}
            if (con != null) try { con.close(); } catch (Exception e) {}
        }
    }

    public BigDecimal getLedgerPeriodTotal(String fromDate, String toDate, boolean cashColumn) throws Exception {
        Connection con = null;
        PreparedStatement pt = null;
        ResultSet rs = null;
        try {
            con = util.DBConnectionManager.getConnectionFromPool();
            String column = cashColumn ? "is_cash" : "is_bank";
            pt = con.prepareStatement(
                "SELECT COALESCE(SUM(" + column + "), 0) AS period_total " +
                "FROM ce_bill_ledger WHERE DATE(created_at) BETWEEN ? AND ? AND " + column + " > 0"
            );
            pt.setString(1, fromDate);
            pt.setString(2, toDate);
            rs = pt.executeQuery();
            if (rs.next()) {
                return safeAmount(rs.getBigDecimal("period_total"));
            }
            return BigDecimal.ZERO;
        } finally {
            if (rs != null) try { rs.close(); } catch (Exception e) {}
            if (pt != null) try { pt.close(); } catch (Exception e) {}
            if (con != null) try { con.close(); } catch (Exception e) {}
        }
    }

    public BigDecimal getLedgerClosingBalance(String fromDate, String toDate, boolean cashColumn) throws Exception {
        BigDecimal opening = getLedgerOpeningBalance(fromDate, cashColumn);
        BigDecimal periodTotal = getLedgerPeriodTotal(fromDate, toDate, cashColumn);
        return opening.add(periodTotal);
    }

    public Vector getCashBookReport(String fromDate, String toDate) throws Exception {
        return getLedgerBookReport(fromDate, toDate, true);
    }

    public Vector getBankBookReport(String fromDate, String toDate) throws Exception {
        return getLedgerBookReport(fromDate, toDate, false);
    }

    public Vector getCashBookSummary(String fromDate, String toDate) throws Exception {
        return getLedgerBookSummary(fromDate, toDate, true);
    }

    public Vector getBankBookSummary(String fromDate, String toDate) throws Exception {
        return getLedgerBookSummary(fromDate, toDate, false);
    }

    public Vector getDayBookSummary(String fromDate, String toDate) throws Exception {
        return getDayBookSummaryInternal(fromDate, toDate);
    }

    private Vector getDayBookSummaryInternal(String fromDate, String toDate) throws Exception {
        Connection con = null;
        PreparedStatement pt = null;
        ResultSet rs = null;
        Vector list = new Vector();
        try {
            con = util.DBConnectionManager.getConnectionFromPool();
            pt = con.prepareStatement(
                "SELECT description, SUM(cash_in) AS cash_in, SUM(cash_out) AS cash_out FROM (" +
                "  SELECT " +
                "    CASE " +
                "      WHEN l.bill_type = 1 THEN 'Advance' " +
                "      WHEN l.bill_type = 2 THEN 'Due' " +
                "      WHEN l.bill_type = 3 THEN 'Due Collection' " +
                "      WHEN l.bill_type = 4 AND e.exchange_type = 1 THEN 'Exchange - Purchase' " +
                "      WHEN l.bill_type = 4 AND e.exchange_type = 2 THEN 'Exchange - Sale' " +
                "      WHEN l.bill_type = 4 THEN 'Exchange Bill' " +
                "      WHEN l.bill_type = 5 THEN 'Expense' " +
                "      ELSE bt.name " +
                "    END AS description, " +
                "    CASE " +
                "      WHEN l.bill_type IN (1, 3) OR l.bill_type = 2 OR (l.bill_type = 4 AND e.exchange_type = 2) THEN (l.is_cash + l.is_bank) " +
                "      ELSE 0 " +
                "    END AS cash_in, " +
                "    CASE " +
                "      WHEN l.bill_type = 4 AND e.exchange_type = 1 THEN (l.is_cash + l.is_bank) " +
                "      WHEN l.bill_type = 5 THEN (l.is_cash + l.is_bank) " +
                "      ELSE 0 " +
                "    END AS cash_out " +
                "  FROM ce_bill_ledger l " +
                "  INNER JOIN ce_bill_type bt ON bt.id = l.bill_type " +
                "  LEFT JOIN ce_currency_exchange e ON l.bill_type = 4 AND e.id = l.bill_id AND e.is_cancelled = 0 " +
                "  WHERE DATE(l.created_at) BETWEEN ? AND ? AND (l.is_cash > 0 OR l.is_bank > 0) " +
                ") t GROUP BY description " +
                "ORDER BY FIELD(description, 'Advance', 'Due', 'Due Collection', 'Exchange - Purchase', 'Exchange - Sale', 'Exchange Bill', 'Expense')"
            );
            pt.setString(1, fromDate);
            pt.setString(2, toDate);
            rs = pt.executeQuery();
            while (rs.next()) {
                Vector row = new Vector();
                row.addElement(rs.getString("description"));
                row.addElement(safeAmount(rs.getBigDecimal("cash_in")));
                row.addElement(safeAmount(rs.getBigDecimal("cash_out")));
                list.addElement(row);
            }
            return list;
        } finally {
            if (rs != null) try { rs.close(); } catch (Exception e) {}
            if (pt != null) try { pt.close(); } catch (Exception e) {}
            if (con != null) try { con.close(); } catch (Exception e) {}
        }
    }

    private Vector getLedgerBookSummary(String fromDate, String toDate, boolean cashColumn) throws Exception {
        Connection con = null;
        PreparedStatement pt = null;
        ResultSet rs = null;
        Vector list = new Vector();
        try {
            con = util.DBConnectionManager.getConnectionFromPool();
            String column = cashColumn ? "is_cash" : "is_bank";
            pt = con.prepareStatement(
                "SELECT description, SUM(cash_in) AS cash_in, SUM(cash_out) AS cash_out FROM (" +
                "  SELECT " +
                "    CASE " +
                "      WHEN l.bill_type = 1 THEN 'Advance' " +
                "      WHEN l.bill_type = 2 THEN 'Due' " +
                "      WHEN l.bill_type = 3 THEN 'Due Collection' " +
                "      WHEN l.bill_type = 4 AND e.exchange_type = 1 THEN 'Exchange - Purchase' " +
                "      WHEN l.bill_type = 4 AND e.exchange_type = 2 THEN 'Exchange - Sale' " +
                "      WHEN l.bill_type = 4 THEN 'Exchange Bill' " +
                "      WHEN l.bill_type = 5 THEN 'Expense' " +
                "      ELSE bt.name " +
                "    END AS description, " +
                "    CASE " +
                "      WHEN l.bill_type IN (1, 3) OR l.bill_type = 2 OR (l.bill_type = 4 AND e.exchange_type = 2) THEN l." + column + " " +
                "      ELSE 0 " +
                "    END AS cash_in, " +
                "    CASE " +
                "      WHEN l.bill_type = 4 AND e.exchange_type = 1 THEN l." + column + " " +
                "      WHEN l.bill_type = 5 THEN l." + column + " " +
                "      ELSE 0 " +
                "    END AS cash_out " +
                "  FROM ce_bill_ledger l " +
                "  INNER JOIN ce_bill_type bt ON bt.id = l.bill_type " +
                "  LEFT JOIN ce_currency_exchange e ON l.bill_type = 4 AND e.id = l.bill_id AND e.is_cancelled = 0 " +
                "  WHERE DATE(l.created_at) BETWEEN ? AND ? AND l." + column + " > 0 " +
                ") t GROUP BY description " +
                "ORDER BY FIELD(description, 'Advance', 'Due', 'Due Collection', 'Exchange - Purchase', 'Exchange - Sale', 'Exchange Bill', 'Expense')"
            );
            pt.setString(1, fromDate);
            pt.setString(2, toDate);
            rs = pt.executeQuery();
            while (rs.next()) {
                Vector row = new Vector();
                row.addElement(rs.getString("description"));
                row.addElement(safeAmount(rs.getBigDecimal("cash_in")));
                row.addElement(safeAmount(rs.getBigDecimal("cash_out")));
                list.addElement(row);
            }
            return list;
        } finally {
            if (rs != null) try { rs.close(); } catch (Exception e) {}
            if (pt != null) try { pt.close(); } catch (Exception e) {}
            if (con != null) try { con.close(); } catch (Exception e) {}
        }
    }

    private Vector getLedgerBookReport(String fromDate, String toDate, boolean cashColumn) throws Exception {
        Connection con = null;
        PreparedStatement pt = null;
        ResultSet rs = null;
        Vector list = new Vector();
        try {
            con = util.DBConnectionManager.getConnectionFromPool();
            String column = cashColumn ? "is_cash" : "is_bank";
            pt = con.prepareStatement(
                "SELECT l.created_at, COALESCE(cu.name, '-') AS customer_name, l.bill_type AS bill_type_id, " +
                "CASE l.bill_type WHEN 1 THEN 'Advance' WHEN 2 THEN 'Due' WHEN 3 THEN 'Due Collection' WHEN 4 THEN 'Exchange Bill' WHEN 5 THEN 'Expense' ELSE bt.name END AS bill_type, " +
                "l." + column + " AS amount, pm.name AS payment_method, l.bill_id " +
                "FROM ce_bill_ledger l " +
                "LEFT JOIN ce_customer cu ON cu.id = l.customer_id " +
                "INNER JOIN ce_bill_type bt ON bt.id = l.bill_type " +
                "LEFT JOIN ce_payment_method pm ON pm.id = l.payment_id " +
                "WHERE DATE(l.created_at) BETWEEN ? AND ? AND l." + column + " > 0 " +
                "ORDER BY l.bill_type ASC, l.created_at ASC, l.id ASC"
            );
            pt.setString(1, fromDate);
            pt.setString(2, toDate);
            rs = pt.executeQuery();
            while (rs.next()) {
                Vector row = new Vector();
                row.addElement(rs.getTimestamp("created_at"));
                row.addElement(rs.getString("customer_name"));
                row.addElement(rs.getString("bill_type"));
                row.addElement(safeAmount(rs.getBigDecimal("amount")));
                row.addElement(rs.getString("payment_method"));
                row.addElement(rs.getInt("bill_id"));
                row.addElement(rs.getInt("bill_type_id"));
                list.addElement(row);
            }
            return list;
        } finally {
            if (rs != null) try { rs.close(); } catch (Exception e) {}
            if (pt != null) try { pt.close(); } catch (Exception e) {}
            if (con != null) try { con.close(); } catch (Exception e) {}
        }
    }

    public Vector getDayBookReport(String fromDate, String toDate) throws Exception {
        Connection con = null;
        PreparedStatement pt = null;
        ResultSet rs = null;
        Vector list = new Vector();
        try {
            con = util.DBConnectionManager.getConnectionFromPool();
            pt = con.prepareStatement(
                "SELECT l.created_at, COALESCE(cu.name, '-') AS customer_name, " +
                "CASE l.bill_type WHEN 1 THEN 'Advance' WHEN 2 THEN 'Due' WHEN 3 THEN 'Due Collection' WHEN 4 THEN 'Exchange Bill' WHEN 5 THEN 'Expense' ELSE bt.name END AS bill_type, " +
                "COALESCE(a.amount, d.amount, dc.amount, ex.counter_amount, ex.amount, ee.amount, 0) AS amount, " +
                "l.advance, l.final_advance, l.due, l.final_due, l.is_cash, l.is_bank, pm.name AS payment_method " +
                "FROM ce_bill_ledger l " +
                "LEFT JOIN ce_customer cu ON cu.id = l.customer_id " +
                "INNER JOIN ce_bill_type bt ON bt.id = l.bill_type " +
                "LEFT JOIN ce_cus_advance a ON l.bill_type = 1 AND a.id = l.bill_id " +
                "LEFT JOIN ce_cus_due d ON l.bill_type = 2 AND d.id = l.bill_id " +
                "LEFT JOIN ce_cus_due_collection dc ON l.bill_type = 3 AND dc.id = l.bill_id " +
                "LEFT JOIN ce_currency_exchange ex ON l.bill_type = 4 AND ex.id = l.bill_id " +
                "LEFT JOIN expense_entry ee ON l.bill_type = 5 AND ee.id = l.bill_id " +
                "LEFT JOIN ce_payment_method pm ON pm.id = l.payment_id " +
                "WHERE DATE(l.created_at) BETWEEN ? AND ? AND (l.is_cash > 0 OR l.is_bank > 0) " +
                "ORDER BY l.bill_type ASC, l.created_at ASC, l.id ASC"
            );
            pt.setString(1, fromDate);
            pt.setString(2, toDate);
            rs = pt.executeQuery();
            while (rs.next()) {
                Vector row = new Vector();
                row.addElement(rs.getTimestamp("created_at"));
                row.addElement(rs.getString("customer_name"));
                row.addElement(rs.getString("bill_type"));
                row.addElement(rs.getBigDecimal("amount"));
                row.addElement(rs.getBigDecimal("advance"));
                row.addElement(rs.getBigDecimal("final_advance"));
                row.addElement(rs.getBigDecimal("due"));
                row.addElement(rs.getBigDecimal("final_due"));
                row.addElement(rs.getBigDecimal("is_cash"));
                row.addElement(rs.getBigDecimal("is_bank"));
                row.addElement(rs.getString("payment_method"));
                list.addElement(row);
            }
            return list;
        } finally {
            if (rs != null) try { rs.close(); } catch (Exception e) {}
            if (pt != null) try { pt.close(); } catch (Exception e) {}
            if (con != null) try { con.close(); } catch (Exception e) {}
        }
    }

    public Vector getAllTransactionsReport(String fromDate, String toDate) throws Exception {
        Connection con = null;
        PreparedStatement pt = null;
        ResultSet rs = null;
        Vector list = new Vector();
        try {
            con = util.DBConnectionManager.getConnectionFromPool();
            pt = con.prepareStatement(
                "SELECT txn_id, created_at, customer_name, phone_number, txn_type, amount, payment_method, details, user_name " +
                "FROM (" +
                "  SELECT a.id AS txn_id, a.created_at, cu.name AS customer_name, cu.phone_number, " +
                "    'Advance' AS txn_type, a.amount, pm.name AS payment_method, a.notes AS details, NULL AS user_name " +
                "  FROM ce_cus_advance a " +
                "  INNER JOIN ce_customer cu ON cu.id = a.customer_id " +
                "  LEFT JOIN ce_payment_method pm ON pm.id = a.payment_id " +
                "  WHERE DATE(a.created_at) BETWEEN ? AND ? " +
                "  UNION ALL " +
                "  SELECT d.id, d.created_at, cu.name, cu.phone_number, " +
                "    'Due', d.amount, pm.name, d.notes, NULL " +
                "  FROM ce_cus_due d " +
                "  INNER JOIN ce_customer cu ON cu.id = d.customer_id " +
                "  LEFT JOIN ce_payment_method pm ON pm.id = d.payment_id " +
                "  WHERE DATE(d.created_at) BETWEEN ? AND ? " +
                "  UNION ALL " +
                "  SELECT dc.id, dc.created_at, cu.name, cu.phone_number, " +
                "    'Due Collection', dc.amount, pm.name, dc.notes, NULL " +
                "  FROM ce_cus_due_collection dc " +
                "  INNER JOIN ce_customer cu ON cu.id = dc.customer_id " +
                "  LEFT JOIN ce_payment_method pm ON pm.id = dc.payment_id " +
                "  WHERE DATE(dc.created_at) BETWEEN ? AND ? " +
                "  UNION ALL " +
                "  SELECT e.id, e.created_at, cu.name, cu.phone_number, " +
                "    CASE e.exchange_type WHEN 1 THEN 'Exchange - Purchase' WHEN 2 THEN 'Exchange - Sale' END, " +
                "    e.counter_amount, pm.name, " +
                "    CONCAT(c.currency_code, ' ', e.amount, ' / ', cc.currency_code, ' ', e.counter_amount), " +
                "    u.user_name " +
                "  FROM ce_currency_exchange e " +
                "  INNER JOIN ce_customer cu ON cu.id = e.customer_id " +
                "  INNER JOIN ce_currency c ON c.id = e.currency_id " +
                "  INNER JOIN ce_currency cc ON cc.id = e.counter_currency_id " +
                "  INNER JOIN ce_payment_method pm ON pm.id = e.payment_id " +
                "  LEFT JOIN users u ON u.id = e.uid " +
                "  WHERE e.is_cancelled = 0 AND e.exchange_date BETWEEN ? AND ? " +
                "  UNION ALL " +
                "  SELECT ee.id, ee.exc_date_time, NULL, NULL, " +
                "    'Expense', ee.amount, pm.name, " +
                "    CONCAT(COALESCE(et.type, 'Expense'), ' - ', ee.content), u.user_name " +
                "  FROM expense_entry ee " +
                "  LEFT JOIN expense_type et ON et.id = ee.exp_type " +
                "  LEFT JOIN ce_payment_method pm ON pm.id = ee.payment_id " +
                "  LEFT JOIN users u ON u.id = ee.uid " +
                "  WHERE ee.is_active = 1 AND DATE(ee.exc_date_time) BETWEEN ? AND ? " +
                ") t ORDER BY created_at DESC, txn_id DESC"
            );
            pt.setString(1, fromDate);
            pt.setString(2, toDate);
            pt.setString(3, fromDate);
            pt.setString(4, toDate);
            pt.setString(5, fromDate);
            pt.setString(6, toDate);
            pt.setString(7, fromDate);
            pt.setString(8, toDate);
            pt.setString(9, fromDate);
            pt.setString(10, toDate);
            rs = pt.executeQuery();
            while (rs.next()) {
                Vector row = new Vector();
                row.addElement(rs.getInt("txn_id"));
                row.addElement(rs.getTimestamp("created_at"));
                row.addElement(rs.getString("customer_name"));
                row.addElement(rs.getString("phone_number"));
                row.addElement(rs.getString("txn_type"));
                row.addElement(safeAmount(rs.getBigDecimal("amount")));
                row.addElement(rs.getString("payment_method"));
                row.addElement(rs.getString("details"));
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

    public Vector getCurrencyExchangeReport(String fromDate, String toDate, int exchangeType, int currencyId) throws Exception {
        Connection con = null;
        PreparedStatement pt = null;
        ResultSet rs = null;
        Vector list = new Vector();
        try {
            con = util.DBConnectionManager.getConnectionFromPool();
            StringBuilder sql = new StringBuilder(
                "SELECT e.id, e.exchange_date, e.created_at, cu.name AS customer_name, cu.phone_number, " +
                "CASE e.exchange_type WHEN 1 THEN 'Purchase' WHEN 2 THEN 'Sale' END AS exchange_type, " +
                "c.currency_code, e.amount, cc.currency_code AS counter_code, e.counter_amount, " +
                "pm.name AS payment_method, e.notes, u.user_name " +
                "FROM ce_currency_exchange e " +
                "INNER JOIN ce_customer cu ON cu.id = e.customer_id " +
                "INNER JOIN ce_currency c ON c.id = e.currency_id " +
                "INNER JOIN ce_currency cc ON cc.id = e.counter_currency_id " +
                "INNER JOIN ce_payment_method pm ON pm.id = e.payment_id " +
                "LEFT JOIN users u ON u.id = e.uid " +
                "WHERE e.is_cancelled = 0 AND e.exchange_date BETWEEN ? AND ?"
            );
            if (exchangeType == EXCHANGE_TYPE_PURCHASE || exchangeType == EXCHANGE_TYPE_SALE) {
                sql.append(" AND e.exchange_type = ?");
            }
            if (currencyId > 0) {
                sql.append(" AND e.currency_id = ?");
            }
            sql.append(" ORDER BY e.exchange_date DESC, e.id DESC");

            pt = con.prepareStatement(sql.toString());
            int param = 1;
            pt.setString(param++, fromDate);
            pt.setString(param++, toDate);
            if (exchangeType == EXCHANGE_TYPE_PURCHASE || exchangeType == EXCHANGE_TYPE_SALE) {
                pt.setInt(param++, exchangeType);
            }
            if (currencyId > 0) {
                pt.setInt(param++, currencyId);
            }
            rs = pt.executeQuery();
            while (rs.next()) {
                Vector row = new Vector();
                BigDecimal amount = safeAmount(rs.getBigDecimal("amount"));
                BigDecimal counterAmount = safeAmount(rs.getBigDecimal("counter_amount"));
                BigDecimal rate = BigDecimal.ZERO;
                if (amount.compareTo(BigDecimal.ZERO) > 0) {
                    rate = counterAmount.divide(amount, 4, java.math.RoundingMode.HALF_UP);
                }
                row.addElement(rs.getInt("id"));
                row.addElement(rs.getDate("exchange_date"));
                row.addElement(rs.getTimestamp("created_at"));
                row.addElement(rs.getString("customer_name"));
                row.addElement(rs.getString("phone_number"));
                row.addElement(rs.getString("exchange_type"));
                row.addElement(rs.getString("currency_code"));
                row.addElement(amount);
                row.addElement(rs.getString("counter_code"));
                row.addElement(counterAmount);
                row.addElement(rate);
                row.addElement(rs.getString("payment_method"));
                row.addElement(rs.getString("notes"));
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

    public Vector getExchangeBillsReport(String fromDate, String toDate) throws Exception {
        return getCurrencyExchangeReport(fromDate, toDate, 0, 0);
    }
}
