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
    private static final int TRANSFER_TYPE_GIVE = 1;
    private static final int TRANSFER_TYPE_GET = 2;
    private static final int TRANSFER_STATUS_OPEN = 0;
    private static final int TRANSFER_STATUS_RETURNED = 1;

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

    private void ensureCustomerAccount(Connection con, int customerId) throws Exception {
        PreparedStatement pt = null;
        try {
            pt = con.prepareStatement(
                "INSERT IGNORE INTO ce_customer_account (customer_id, advance, due) VALUES (?, 0, 0)"
            );
            pt.setInt(1, customerId);
            pt.executeUpdate();
        } finally {
            if (pt != null) try { pt.close(); } catch (Exception e) {}
        }
    }

    /**
     * Applies exchange offsets and unpaid balance to ce_customer_account.
     * Purchase: existing due reduces payable; remaining unpaid → advance.
     * Sale: existing advance reduces collectible; remaining unpaid → due.
     * balances array is filled as [beforeAdvance, afterAdvance, beforeDue, afterDue].
     */
    private void applyExchangeAccountUpdates(Connection con, int customerId, int exchangeType,
            BigDecimal dueAdjusted, BigDecimal advanceAdjusted, BigDecimal balanceAmt,
            BigDecimal[] balances) throws Exception {
        ensureCustomerAccount(con, customerId);

        BigDecimal[] current = new BigDecimal[2];
        loadAccountBalances(con, customerId, current);
        BigDecimal beforeAdvance = current[0];
        BigDecimal beforeDue = current[1];
        BigDecimal afterAdvance = beforeAdvance;
        BigDecimal afterDue = beforeDue;

        PreparedStatement pt = null;
        try {
            if (dueAdjusted != null && dueAdjusted.compareTo(BigDecimal.ZERO) > 0) {
                afterDue = beforeDue.subtract(dueAdjusted);
                pt = con.prepareStatement(
                    "UPDATE ce_customer_account SET due = due - ? WHERE customer_id = ?"
                );
                pt.setBigDecimal(1, dueAdjusted);
                pt.setInt(2, customerId);
                pt.executeUpdate();
                pt.close();
                pt = null;
            }

            if (advanceAdjusted != null && advanceAdjusted.compareTo(BigDecimal.ZERO) > 0) {
                afterAdvance = afterAdvance.subtract(advanceAdjusted);
                pt = con.prepareStatement(
                    "UPDATE ce_customer_account SET advance = advance - ? WHERE customer_id = ?"
                );
                pt.setBigDecimal(1, advanceAdjusted);
                pt.setInt(2, customerId);
                pt.executeUpdate();
                pt.close();
                pt = null;
            }

            if (balanceAmt != null && balanceAmt.compareTo(BigDecimal.ZERO) > 0) {
                if (exchangeType == EXCHANGE_TYPE_SALE) {
                    afterDue = afterDue.add(balanceAmt);
                    pt = con.prepareStatement(
                        "UPDATE ce_customer_account SET due = due + ? WHERE customer_id = ?"
                    );
                } else {
                    afterAdvance = afterAdvance.add(balanceAmt);
                    pt = con.prepareStatement(
                        "UPDATE ce_customer_account SET advance = advance + ? WHERE customer_id = ?"
                    );
                }
                pt.setBigDecimal(1, balanceAmt);
                pt.setInt(2, customerId);
                pt.executeUpdate();
            }
        } finally {
            if (pt != null) try { pt.close(); } catch (Exception e) {}
        }

        balances[0] = beforeAdvance;
        balances[1] = afterAdvance;
        balances[2] = beforeDue;
        balances[3] = afterDue;
    }

    public Vector getCustomerBalanceSummary(int customerId) throws Exception {
        Connection con = null;
        BigDecimal[] balances = new BigDecimal[2];
        try {
            con = util.DBConnectionManager.getConnectionFromPool();
            ensureCustomerAccount(con, customerId);
            loadAccountBalances(con, customerId, balances);
        } finally {
            if (con != null) try { con.close(); } catch (Exception e) {}
        }
        Vector row = new Vector();
        row.addElement(balances[0]);
        row.addElement(balances[1]);
        return row;
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
        insertStockTransaction(con, Integer.valueOf(exchangeId), null, null, currencyId, stockTxnType,
            quantity, beforeQty, afterQty);
    }

    private void applyTransferStockMovement(Connection con, int transferId, int currencyId,
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
        insertStockTransaction(con, null, null, Integer.valueOf(transferId), currencyId, stockTxnType,
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

    private void insertStockTransaction(Connection con, Integer exchangeId, Integer adjustmentId, Integer transferId,
            int currencyId, int txnType, BigDecimal quantity, BigDecimal beforeQty, BigDecimal afterQty) throws Exception {
        PreparedStatement pt = null;
        try {
            pt = con.prepareStatement(
                "INSERT INTO ce_currency_stock_transaction " +
                "(exchange_id, adjustment_id, transfer_id, currency_id, txn_type, quantity, before_qty, after_qty) " +
                "VALUES (?, ?, ?, ?, ?, ?, ?, ?)"
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
            if (transferId != null) {
                pt.setInt(3, transferId.intValue());
            } else {
                pt.setNull(3, java.sql.Types.INTEGER);
            }
            pt.setInt(4, currencyId);
            pt.setInt(5, txnType);
            pt.setBigDecimal(6, quantity);
            pt.setBigDecimal(7, beforeQty);
            pt.setBigDecimal(8, afterQty);
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
            BigDecimal paid, int paymentId, String notes, int userId) throws Exception {
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

        BigDecimal paidAmount = safeAmount(paid);
        if (paidAmount.compareTo(BigDecimal.ZERO) < 0) {
            throw new Exception("Paid amount cannot be negative");
        }

        Connection con = null;
        PreparedStatement pt = null;
        try {
            con = util.DBConnectionManager.getConnectionFromPool();
            con.setAutoCommit(false);

            ensureCustomerAccount(con, customerId);
            BigDecimal[] currentBalances = new BigDecimal[2];
            loadAccountBalances(con, customerId, currentBalances);
            BigDecimal customerAdvance = currentBalances[0];
            BigDecimal customerDue = currentBalances[1];

            BigDecimal dueAdjusted = BigDecimal.ZERO;
            BigDecimal advanceAdjusted = BigDecimal.ZERO;
            if (exchangeType == EXCHANGE_TYPE_PURCHASE) {
                dueAdjusted = customerDue.min(counterAmount).setScale(4, java.math.RoundingMode.HALF_UP);
            } else {
                advanceAdjusted = customerAdvance.min(counterAmount).setScale(4, java.math.RoundingMode.HALF_UP);
            }

            BigDecimal offsetAmount = exchangeType == EXCHANGE_TYPE_PURCHASE ? dueAdjusted : advanceAdjusted;
            BigDecimal payableAfterAdjust = counterAmount.subtract(offsetAmount)
                .setScale(4, java.math.RoundingMode.HALF_UP);

            if (paidAmount.compareTo(payableAfterAdjust) > 0) {
                throw new Exception("Paid amount cannot exceed "
                    + payableAfterAdjust.toPlainString() + " after balance adjustment");
            }

            BigDecimal balanceAmount = payableAfterAdjust.subtract(paidAmount)
                .setScale(4, java.math.RoundingMode.HALF_UP);

            if (paidAmount.compareTo(counterAmount) > 0) {
                throw new Exception("Paid amount cannot exceed counter amount");
            }

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
            BigDecimal[] cashBank = resolveCashBankAmounts(con, paymentId, paidAmount);

            pt = con.prepareStatement(
                "INSERT INTO ce_currency_exchange " +
                "(customer_id, exchange_type, exchange_date, currency_id, amount, counter_currency_id, counter_amount, paid, balance, due_adjusted, advance_adjusted, payment_id, notes, uid, is_cancelled) " +
                "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 0)",
                Statement.RETURN_GENERATED_KEYS
            );
            pt.setInt(1, customerId);
            pt.setInt(2, exchangeType);
            pt.setString(3, exchangeDate.trim());
            pt.setInt(4, currencyId);
            pt.setBigDecimal(5, amount);
            pt.setInt(6, counterCurrencyId);
            pt.setBigDecimal(7, counterAmount);
            pt.setBigDecimal(8, paidAmount);
            pt.setBigDecimal(9, balanceAmount);
            pt.setBigDecimal(10, dueAdjusted);
            pt.setBigDecimal(11, advanceAdjusted);
            pt.setInt(12, paymentId);
            if (notes != null && notes.trim().length() > 0) {
                pt.setString(13, notes.trim());
            } else {
                pt.setNull(13, java.sql.Types.LONGVARCHAR);
            }
            pt.setInt(14, userId);
            pt.executeUpdate();
            int exchangeId = insertGeneratedId(pt);
            pt.close();
            pt = null;

            if (exchangeType == EXCHANGE_TYPE_PURCHASE) {
                applyStockMovement(con, exchangeId, currencyId, true, amount);
                if (isCash == 1 && paidAmount.compareTo(BigDecimal.ZERO) > 0) {
                    applyStockMovement(con, exchangeId, counterCurrencyId, false, paidAmount);
                }
            } else {
                applyStockMovement(con, exchangeId, currencyId, false, amount);
                if (isCash == 1 && paidAmount.compareTo(BigDecimal.ZERO) > 0) {
                    applyStockMovement(con, exchangeId, counterCurrencyId, true, paidAmount);
                }
            }

            BigDecimal[] accountBalances = new BigDecimal[4];
            applyExchangeAccountUpdates(con, customerId, exchangeType, dueAdjusted, advanceAdjusted,
                balanceAmount, accountBalances);
            insertBillLedger(con, customerId, exchangeId,
                accountBalances[0], accountBalances[1],
                accountBalances[2], accountBalances[3],
                cashBank[0], cashBank[1], paymentId);

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
            insertStockTransaction(con, null, Integer.valueOf(adjustmentId), null, currencyId, stockTxnType,
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

    private BigDecimal getLedgerNetBalance(String date, boolean cashColumn, boolean inclusive) throws Exception {
        Connection con = null;
        PreparedStatement pt = null;
        ResultSet rs = null;
        try {
            con = util.DBConnectionManager.getConnectionFromPool();
            String column = cashColumn ? "is_cash" : "is_bank";
            String dateCondition = inclusive ? "DATE(l.created_at) <= ?" : "DATE(l.created_at) < ?";
            pt = con.prepareStatement(
                "SELECT COALESCE(SUM(net_amount), 0) AS balance FROM (" +
                "  SELECT " +
                "    CASE " +
                "      WHEN l.bill_type = 3 OR (l.bill_type = 4 AND e.exchange_type = 2) THEN l." + column + " " +
                "      WHEN l.bill_type = 4 AND e.exchange_type = 1 THEN -l." + column + " " +
                "      WHEN l.bill_type IN (5, 6) THEN -l." + column + " " +
                "      ELSE 0 " +
                "    END AS net_amount " +
                "  FROM ce_bill_ledger l " +
                "  LEFT JOIN ce_currency_exchange e ON l.bill_type = 4 AND e.id = l.bill_id AND e.is_cancelled = 0 " +
                "  WHERE " + dateCondition + " AND l." + column + " > 0 AND l.bill_type NOT IN (1, 2) " +
                ") t"
            );
            pt.setString(1, date);
            rs = pt.executeQuery();
            if (rs.next()) {
                return safeAmount(rs.getBigDecimal("balance"));
            }
            return BigDecimal.ZERO;
        } finally {
            if (rs != null) try { rs.close(); } catch (Exception e) {}
            if (pt != null) try { pt.close(); } catch (Exception e) {}
            if (con != null) try { con.close(); } catch (Exception e) {}
        }
    }

    public BigDecimal getLedgerOpeningBalance(String fromDate, boolean cashColumn) throws Exception {
        return getLedgerNetBalance(fromDate, cashColumn, false);
    }

    public BigDecimal getLedgerBalanceUpTo(String toDate, boolean cashColumn) throws Exception {
        return getLedgerNetBalance(toDate, cashColumn, true);
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
        BigDecimal totalIn = BigDecimal.ZERO;
        BigDecimal totalOut = BigDecimal.ZERO;
        Vector summary = getLedgerBookSummary(fromDate, toDate, cashColumn);
        for (int i = 0; i < summary.size(); i++) {
            Vector row = (Vector) summary.get(i);
            totalIn = totalIn.add((BigDecimal) row.elementAt(1));
            totalOut = totalOut.add((BigDecimal) row.elementAt(2));
        }
        return opening.add(totalIn).subtract(totalOut);
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
                "SELECT description, SUM(cash_in) AS cash_in, SUM(cash_out) AS cash_out, SUM(credit) AS credit FROM (" +
                "  SELECT " +
                "    CASE " +
                "      WHEN l.bill_type = 3 THEN 'Due Collection' " +
                "      WHEN l.bill_type = 4 AND e.exchange_type = 1 THEN 'Exchange - Purchase' " +
                "      WHEN l.bill_type = 4 AND e.exchange_type = 2 THEN 'Exchange - Sale' " +
                "      WHEN l.bill_type = 4 THEN 'Exchange Bill' " +
                "      WHEN l.bill_type = 5 THEN 'Expense' " +
                "      WHEN l.bill_type = 6 THEN 'Purchase Balance Pay' " +
                "      ELSE bt.name " +
                "    END AS description, " +
                "    CASE " +
                "      WHEN l.bill_type = 3 OR (l.bill_type = 4 AND e.exchange_type = 2) THEN (l.is_cash + l.is_bank) " +
                "      ELSE 0 " +
                "    END AS cash_in, " +
                "    CASE " +
                "      WHEN l.bill_type = 4 AND e.exchange_type = 1 THEN (l.is_cash + l.is_bank) " +
                "      WHEN l.bill_type IN (5, 6) THEN (l.is_cash + l.is_bank) " +
                "      ELSE 0 " +
                "    END AS cash_out, " +
                "    CASE " +
                "      WHEN l.bill_type = 4 AND COALESCE(e.balance, 0) > 0 THEN e.balance " +
                "      ELSE 0 " +
                "    END AS credit " +
                "  FROM ce_bill_ledger l " +
                "  INNER JOIN ce_bill_type bt ON bt.id = l.bill_type " +
                "  LEFT JOIN ce_currency_exchange e ON l.bill_type = 4 AND e.id = l.bill_id AND e.is_cancelled = 0 " +
                "  WHERE DATE(l.created_at) BETWEEN ? AND ? " +
                "    AND l.bill_type NOT IN (1, 2) " +
                "    AND ((l.is_cash + l.is_bank) > 0 OR (l.bill_type = 4 AND COALESCE(e.balance, 0) > 0)) " +
                ") t GROUP BY description " +
                "HAVING SUM(cash_in) > 0 OR SUM(cash_out) > 0 OR SUM(credit) > 0 " +
                "ORDER BY FIELD(description, 'Due Collection', 'Exchange - Purchase', 'Exchange - Sale', 'Exchange Bill', 'Expense', 'Purchase Balance Pay')"
            );
            pt.setString(1, fromDate);
            pt.setString(2, toDate);
            rs = pt.executeQuery();
            while (rs.next()) {
                Vector row = new Vector();
                row.addElement(rs.getString("description"));
                row.addElement(safeAmount(rs.getBigDecimal("cash_in")));
                row.addElement(safeAmount(rs.getBigDecimal("cash_out")));
                row.addElement(safeAmount(rs.getBigDecimal("credit")));
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
                "      WHEN l.bill_type = 3 THEN 'Due Collection' " +
                "      WHEN l.bill_type = 4 AND e.exchange_type = 1 THEN 'Exchange - Purchase' " +
                "      WHEN l.bill_type = 4 AND e.exchange_type = 2 THEN 'Exchange - Sale' " +
                "      WHEN l.bill_type = 4 THEN 'Exchange Bill' " +
                "      WHEN l.bill_type = 5 THEN 'Expense' " +
                "      WHEN l.bill_type = 6 THEN 'Purchase Balance Pay' " +
                "      ELSE bt.name " +
                "    END AS description, " +
                "    CASE " +
                "      WHEN l.bill_type = 3 OR (l.bill_type = 4 AND e.exchange_type = 2) THEN l." + column + " " +
                "      ELSE 0 " +
                "    END AS cash_in, " +
                "    CASE " +
                "      WHEN l.bill_type = 4 AND e.exchange_type = 1 THEN l." + column + " " +
                "      WHEN l.bill_type IN (5, 6) THEN l." + column + " " +
                "      ELSE 0 " +
                "    END AS cash_out " +
                "  FROM ce_bill_ledger l " +
                "  INNER JOIN ce_bill_type bt ON bt.id = l.bill_type " +
                "  LEFT JOIN ce_currency_exchange e ON l.bill_type = 4 AND e.id = l.bill_id AND e.is_cancelled = 0 " +
                "  WHERE DATE(l.created_at) BETWEEN ? AND ? AND l." + column + " > 0 " +
                "    AND l.bill_type NOT IN (1, 2) " +
                ") t GROUP BY description " +
                "ORDER BY FIELD(description, 'Due Collection', 'Exchange - Purchase', 'Exchange - Sale', 'Exchange Bill', 'Expense', 'Purchase Balance Pay')"
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
                "CASE l.bill_type WHEN 1 THEN 'Advance' WHEN 2 THEN 'Due' WHEN 3 THEN 'Due Collection' WHEN 4 THEN 'Exchange Bill' WHEN 5 THEN 'Expense' WHEN 6 THEN 'Purchase Balance Pay' ELSE bt.name END AS bill_type, " +
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
                "CASE l.bill_type WHEN 1 THEN 'Advance' WHEN 2 THEN 'Due' WHEN 3 THEN 'Due Collection' WHEN 4 THEN 'Exchange Bill' WHEN 5 THEN 'Expense' WHEN 6 THEN 'Purchase Balance Pay' ELSE bt.name END AS bill_type, " +
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
                "SELECT txn_id, created_at, customer_name, phone_number, txn_type, amount, payment_method, " +
                "details, user_name, bill_amount, paid_amount, balance_amount, due_adjusted, advance_adjusted, notes " +
                "FROM (" +
                "  SELECT a.id AS txn_id, a.created_at, cu.name AS customer_name, cu.phone_number, " +
                "    'Advance' AS txn_type, a.amount, pm.name AS payment_method, " +
                "    'Purchase balance added' AS details, NULL AS user_name, " +
                "    a.amount AS bill_amount, a.amount AS paid_amount, 0 AS balance_amount, " +
                "    0 AS due_adjusted, 0 AS advance_adjusted, a.notes " +
                "  FROM ce_cus_advance a " +
                "  INNER JOIN ce_customer cu ON cu.id = a.customer_id " +
                "  LEFT JOIN ce_payment_method pm ON pm.id = a.payment_id " +
                "  WHERE DATE(a.created_at) BETWEEN ? AND ? " +
                "  UNION ALL " +
                "  SELECT d.id, d.created_at, cu.name, cu.phone_number, " +
                "    'Due', d.amount, pm.name, 'Customer due added', NULL, " +
                "    d.amount, d.amount, 0, 0, 0, d.notes " +
                "  FROM ce_cus_due d " +
                "  INNER JOIN ce_customer cu ON cu.id = d.customer_id " +
                "  LEFT JOIN ce_payment_method pm ON pm.id = d.payment_id " +
                "  WHERE DATE(d.created_at) BETWEEN ? AND ? " +
                "  UNION ALL " +
                "  SELECT dc.id, dc.created_at, cu.name, cu.phone_number, " +
                "    'Due Collection', dc.amount, pm.name, 'Due collection received', NULL, " +
                "    dc.amount, dc.amount, 0, 0, 0, dc.notes " +
                "  FROM ce_cus_due_collection dc " +
                "  INNER JOIN ce_customer cu ON cu.id = dc.customer_id " +
                "  LEFT JOIN ce_payment_method pm ON pm.id = dc.payment_id " +
                "  WHERE DATE(dc.created_at) BETWEEN ? AND ? " +
                "  UNION ALL " +
                "  SELECT ap.id, ap.created_at, cu.name, cu.phone_number, " +
                "    'Purchase Balance Pay', ap.amount, pm.name, 'Purchase balance paid to customer', NULL, " +
                "    ap.amount, ap.amount, 0, 0, 0, ap.notes " +
                "  FROM ce_cus_advance_payment ap " +
                "  INNER JOIN ce_customer cu ON cu.id = ap.customer_id " +
                "  LEFT JOIN ce_payment_method pm ON pm.id = ap.payment_id " +
                "  WHERE DATE(ap.created_at) BETWEEN ? AND ? " +
                "  UNION ALL " +
                "  SELECT e.id, e.created_at, cu.name, cu.phone_number, " +
                "    CASE e.exchange_type WHEN 1 THEN 'Exchange - Purchase' WHEN 2 THEN 'Exchange - Sale' END, " +
                "    e.counter_amount, pm.name, " +
                "    CONCAT(c.currency_code, ' ', e.amount, ' @ ', ROUND(e.counter_amount / e.amount, 4), " +
                "      ' = ', cc.currency_code, ' ', e.counter_amount), " +
                "    u.user_name, " +
                "    e.counter_amount, e.paid, e.balance, " +
                "    COALESCE(e.due_adjusted, 0), COALESCE(e.advance_adjusted, 0), e.notes " +
                "  FROM ce_currency_exchange e " +
                "  INNER JOIN ce_customer cu ON cu.id = e.customer_id " +
                "  INNER JOIN ce_currency c ON c.id = e.currency_id " +
                "  INNER JOIN ce_currency cc ON cc.id = e.counter_currency_id " +
                "  INNER JOIN ce_payment_method pm ON pm.id = e.payment_id " +
                "  LEFT JOIN users u ON u.id = e.uid " +
                "  WHERE e.is_cancelled = 0 AND e.exchange_date BETWEEN ? AND ? " +
                "  UNION ALL " +
                "  SELECT ee.id, ee.exc_date_time, '-', NULL, " +
                "    'Expense', ee.amount, pm.name, " +
                "    CONCAT(COALESCE(et.type, 'Expense'), IF(ee.content IS NOT NULL AND ee.content <> '', CONCAT(' - ', ee.content), '')), " +
                "    u.user_name, ee.amount, ee.amount, 0, 0, 0, ee.content " +
                "  FROM expense_entry ee " +
                "  LEFT JOIN expense_type et ON et.id = ee.exp_type " +
                "  LEFT JOIN ce_payment_method pm ON pm.id = ee.payment_id " +
                "  LEFT JOIN users u ON u.id = ee.uid " +
                "  WHERE ee.is_active = 1 AND DATE(ee.exc_date_time) BETWEEN ? AND ? " +
                ") t ORDER BY created_at ASC, txn_id ASC"
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
            pt.setString(11, fromDate);
            pt.setString(12, toDate);
            rs = pt.executeQuery();
            while (rs.next()) {
                Vector row = new Vector();
                row.addElement(Integer.valueOf(rs.getInt("txn_id")));
                row.addElement(rs.getTimestamp("created_at"));
                row.addElement(rs.getString("customer_name"));
                row.addElement(rs.getString("phone_number"));
                row.addElement(rs.getString("txn_type"));
                row.addElement(safeAmount(rs.getBigDecimal("amount")));
                row.addElement(rs.getString("payment_method"));
                row.addElement(rs.getString("details"));
                row.addElement(rs.getString("user_name"));
                row.addElement(safeAmount(rs.getBigDecimal("bill_amount")));
                row.addElement(safeAmount(rs.getBigDecimal("paid_amount")));
                row.addElement(safeAmount(rs.getBigDecimal("balance_amount")));
                row.addElement(safeAmount(rs.getBigDecimal("due_adjusted")));
                row.addElement(safeAmount(rs.getBigDecimal("advance_adjusted")));
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
                "COALESCE(e.paid, e.counter_amount) AS paid, COALESCE(e.balance, 0) AS balance, " +
                "COALESCE(e.due_adjusted, 0) AS due_adjusted, COALESCE(e.advance_adjusted, 0) AS advance_adjusted, " +
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
                BigDecimal paidAmt = safeAmount(rs.getBigDecimal("paid"));
                BigDecimal balanceAmt = safeAmount(rs.getBigDecimal("balance"));
                BigDecimal dueAdjusted = safeAmount(rs.getBigDecimal("due_adjusted"));
                BigDecimal advanceAdjusted = safeAmount(rs.getBigDecimal("advance_adjusted"));
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
                row.addElement(paidAmt);
                row.addElement(balanceAmt);
                row.addElement(dueAdjusted);
                row.addElement(advanceAdjusted);
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

    public int saveCurrencyTransfer(int customerId, int currencyId, int transferType, String transferDate,
            BigDecimal quantity, String notes, int userId) throws Exception {
        if (customerId <= 0) {
            throw new Exception("Customer is required");
        }
        if (currencyId <= 0) {
            throw new Exception("Currency is required");
        }
        if (transferType != TRANSFER_TYPE_GIVE && transferType != TRANSFER_TYPE_GET) {
            throw new Exception("Invalid transfer type");
        }
        if (transferDate == null || transferDate.trim().isEmpty()) {
            throw new Exception("Date is required");
        }
        if (quantity == null || quantity.compareTo(BigDecimal.ZERO) <= 0) {
            throw new Exception("Quantity must be greater than zero");
        }

        Connection con = null;
        PreparedStatement pt = null;
        try {
            con = util.DBConnectionManager.getConnectionFromPool();
            con.setAutoCommit(false);

            pt = con.prepareStatement(
                "INSERT INTO ce_currency_transfer " +
                "(customer_id, currency_id, transfer_type, quantity, transfer_date, notes, status, uid) " +
                "VALUES (?, ?, ?, ?, ?, ?, ?, ?)",
                Statement.RETURN_GENERATED_KEYS
            );
            pt.setInt(1, customerId);
            pt.setInt(2, currencyId);
            pt.setInt(3, transferType);
            pt.setBigDecimal(4, quantity);
            pt.setString(5, transferDate.trim());
            if (notes != null && notes.trim().length() > 0) {
                pt.setString(6, notes.trim());
            } else {
                pt.setNull(6, java.sql.Types.LONGVARCHAR);
            }
            pt.setInt(7, TRANSFER_STATUS_OPEN);
            pt.setInt(8, userId);
            pt.executeUpdate();
            int transferId = insertGeneratedId(pt);
            pt.close();
            pt = null;

            if (transferType == TRANSFER_TYPE_GIVE) {
                applyTransferStockMovement(con, transferId, currencyId, false, quantity);
            } else {
                applyTransferStockMovement(con, transferId, currencyId, true, quantity);
            }

            con.commit();
            return transferId;
        } catch (Exception e) {
            if (con != null) con.rollback();
            throw e;
        } finally {
            if (pt != null) try { pt.close(); } catch (Exception e) {}
            if (con != null) try { con.close(); } catch (Exception e) {}
        }
    }

    public void returnCurrencyTransfer(int transferId, String returnDate, int userId) throws Exception {
        if (transferId <= 0) {
            throw new Exception("Invalid transfer");
        }
        if (returnDate == null || returnDate.trim().isEmpty()) {
            throw new Exception("Return date is required");
        }

        Connection con = null;
        PreparedStatement pt = null;
        ResultSet rs = null;
        try {
            con = util.DBConnectionManager.getConnectionFromPool();
            con.setAutoCommit(false);

            pt = con.prepareStatement(
                "SELECT customer_id, currency_id, transfer_type, quantity, status " +
                "FROM ce_currency_transfer WHERE id = ? FOR UPDATE"
            );
            pt.setInt(1, transferId);
            rs = pt.executeQuery();
            if (!rs.next()) {
                throw new Exception("Transfer not found");
            }
            int status = rs.getInt("status");
            if (status != TRANSFER_STATUS_OPEN) {
                throw new Exception("This transfer is already returned");
            }
            int transferType = rs.getInt("transfer_type");
            int currencyId = rs.getInt("currency_id");
            BigDecimal quantity = safeAmount(rs.getBigDecimal("quantity"));
            rs.close();
            pt.close();
            pt = null;

            if (transferType == TRANSFER_TYPE_GIVE) {
                applyTransferStockMovement(con, transferId, currencyId, true, quantity);
            } else {
                applyTransferStockMovement(con, transferId, currencyId, false, quantity);
            }

            pt = con.prepareStatement(
                "UPDATE ce_currency_transfer SET status = ?, return_date = ? WHERE id = ?"
            );
            pt.setInt(1, TRANSFER_STATUS_RETURNED);
            pt.setString(2, returnDate.trim());
            pt.setInt(3, transferId);
            pt.executeUpdate();

            con.commit();
        } catch (Exception e) {
            if (con != null) con.rollback();
            throw e;
        } finally {
            if (rs != null) try { rs.close(); } catch (Exception e) {}
            if (pt != null) try { pt.close(); } catch (Exception e) {}
            if (con != null) try { con.close(); } catch (Exception e) {}
        }
    }

    public Vector getCurrencyTransferList(int transferTypeFilter) throws Exception {
        Connection con = null;
        PreparedStatement pt = null;
        ResultSet rs = null;
        Vector list = new Vector();
        try {
            con = util.DBConnectionManager.getConnectionFromPool();
            StringBuilder sql = new StringBuilder(
                "SELECT t.id, t.transfer_date, t.created_at, cu.name AS customer_name, cu.phone_number, " +
                "CASE t.transfer_type WHEN 1 THEN 'Give' WHEN 2 THEN 'Get' END AS transfer_type, " +
                "c.currency_code, t.quantity, t.notes, t.status, t.return_date, u.user_name " +
                "FROM ce_currency_transfer t " +
                "INNER JOIN ce_customer cu ON cu.id = t.customer_id " +
                "INNER JOIN ce_currency c ON c.id = t.currency_id " +
                "LEFT JOIN users u ON u.id = t.uid " +
                "WHERE 1=1 "
            );
            if (transferTypeFilter == TRANSFER_TYPE_GIVE || transferTypeFilter == TRANSFER_TYPE_GET) {
                sql.append("AND t.transfer_type = ? ");
            }
            sql.append("ORDER BY t.transfer_date DESC, t.id DESC");

            pt = con.prepareStatement(sql.toString());
            if (transferTypeFilter == TRANSFER_TYPE_GIVE || transferTypeFilter == TRANSFER_TYPE_GET) {
                pt.setInt(1, transferTypeFilter);
            }
            rs = pt.executeQuery();
            while (rs.next()) {
                Vector row = new Vector();
                row.addElement(rs.getInt("id"));
                row.addElement(rs.getDate("transfer_date"));
                row.addElement(rs.getTimestamp("created_at"));
                row.addElement(rs.getString("customer_name"));
                row.addElement(rs.getString("phone_number"));
                row.addElement(rs.getString("transfer_type"));
                row.addElement(rs.getString("currency_code"));
                row.addElement(safeAmount(rs.getBigDecimal("quantity")));
                row.addElement(rs.getString("notes"));
                row.addElement(rs.getInt("status"));
                row.addElement(rs.getDate("return_date"));
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

    public Vector getCurrencyTransferReport(String fromDate, String toDate, int customerId) throws Exception {
        Connection con = null;
        PreparedStatement pt = null;
        ResultSet rs = null;
        Vector list = new Vector();
        try {
            con = util.DBConnectionManager.getConnectionFromPool();
            StringBuilder sql = new StringBuilder(
                "SELECT t.id, t.transfer_date, t.created_at, cu.name AS customer_name, cu.phone_number, " +
                "CASE t.transfer_type WHEN 1 THEN 'Give' WHEN 2 THEN 'Get' END AS transfer_type, " +
                "c.currency_code, t.quantity, t.notes, " +
                "CASE t.status WHEN 0 THEN 'Open' WHEN 1 THEN 'Returned' END AS status_label, " +
                "t.return_date, u.user_name " +
                "FROM ce_currency_transfer t " +
                "INNER JOIN ce_customer cu ON cu.id = t.customer_id " +
                "INNER JOIN ce_currency c ON c.id = t.currency_id " +
                "LEFT JOIN users u ON u.id = t.uid " +
                "WHERE t.transfer_date BETWEEN ? AND ? "
            );
            if (customerId > 0) {
                sql.append("AND t.customer_id = ? ");
            }
            sql.append("ORDER BY t.transfer_date DESC, t.id DESC");

            pt = con.prepareStatement(sql.toString());
            int param = 1;
            pt.setString(param++, fromDate);
            pt.setString(param++, toDate);
            if (customerId > 0) {
                pt.setInt(param++, customerId);
            }
            rs = pt.executeQuery();
            while (rs.next()) {
                Vector row = new Vector();
                row.addElement(rs.getInt("id"));
                row.addElement(rs.getDate("transfer_date"));
                row.addElement(rs.getTimestamp("created_at"));
                row.addElement(rs.getString("customer_name"));
                row.addElement(rs.getString("phone_number"));
                row.addElement(rs.getString("transfer_type"));
                row.addElement(rs.getString("currency_code"));
                row.addElement(safeAmount(rs.getBigDecimal("quantity")));
                row.addElement(rs.getString("notes"));
                row.addElement(rs.getString("status_label"));
                row.addElement(rs.getDate("return_date"));
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
}
