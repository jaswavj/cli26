<%@ page language="java" contentType="application/json; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.*, org.json.*, java.math.BigDecimal, java.text.SimpleDateFormat" %>
<jsp:useBean id="customer" class="currency.currencyBean" />
<%
    request.setCharacterEncoding("UTF-8");
    JSONObject result = new JSONObject();
    SimpleDateFormat sdf = new SimpleDateFormat("dd-MM-yyyy hh:mm a");

    try {
        String customerIdStr = request.getParameter("customerId");
        if (customerIdStr == null || customerIdStr.trim().isEmpty()) {
            result.put("success", false);
            result.put("message", "Customer is required");
            out.print(result.toString());
            return;
        }

        int customerId = Integer.parseInt(customerIdStr.trim());
        Vector customerRow = customer.getCustomerById(customerId);
        if (customerRow == null || customerRow.isEmpty()) {
            result.put("success", false);
            result.put("message", "Customer not found");
            out.print(result.toString());
            return;
        }

        Vector account = customer.getCustomerAccount(customerId);
        BigDecimal advance = (BigDecimal) account.elementAt(1);
        BigDecimal due = (BigDecimal) account.elementAt(2);

        JSONArray entries = new JSONArray();
        Vector transactions = customer.getCustomerTransactions(customerId);
        for (int i = 0; i < transactions.size(); i++) {
            Vector row = (Vector) transactions.get(i);
            JSONObject entry = new JSONObject();
            entry.put("type", row.elementAt(0).toString());
            BigDecimal amount = (BigDecimal) row.elementAt(1);
            entry.put("amount", amount != null ? amount.toPlainString() : "0");
            entry.put("notes", row.elementAt(2) != null ? row.elementAt(2).toString() : "");
            java.sql.Timestamp createdAt = (java.sql.Timestamp) row.elementAt(3);
            entry.put("date", createdAt != null ? sdf.format(createdAt) : "");
            BigDecimal advBefore = (BigDecimal) row.elementAt(4);
            BigDecimal advFinal = (BigDecimal) row.elementAt(5);
            BigDecimal dueBefore = (BigDecimal) row.elementAt(6);
            BigDecimal dueFinal = (BigDecimal) row.elementAt(7);
            entry.put("advance", advBefore != null ? advBefore.toPlainString() : "0");
            entry.put("finalAdvance", advFinal != null ? advFinal.toPlainString() : "0");
            entry.put("due", dueBefore != null ? dueBefore.toPlainString() : "0");
            entry.put("finalDue", dueFinal != null ? dueFinal.toPlainString() : "0");
            entry.put("paymentMethod", row.size() > 8 && row.elementAt(8) != null ? row.elementAt(8).toString() : "-");
            if (row.size() > 16 && row.elementAt(16) != null && Integer.parseInt(row.elementAt(16).toString()) == 4) {
                BigDecimal billAmount = (BigDecimal) row.elementAt(11);
                BigDecimal paidAmount = (BigDecimal) row.elementAt(12);
                BigDecimal balanceAmount = (BigDecimal) row.elementAt(13);
                BigDecimal dueAdjusted = (BigDecimal) row.elementAt(14);
                BigDecimal advanceAdjusted = (BigDecimal) row.elementAt(15);
                entry.put("billAmount", billAmount != null ? billAmount.toPlainString() : "0");
                entry.put("paid", paidAmount != null ? paidAmount.toPlainString() : "0");
                entry.put("balance", balanceAmount != null ? balanceAmount.toPlainString() : "0");
                entry.put("dueAdjusted", dueAdjusted != null ? dueAdjusted.toPlainString() : "0");
                entry.put("advanceAdjusted", advanceAdjusted != null ? advanceAdjusted.toPlainString() : "0");
                entry.put("isExchange", true);
            } else {
                entry.put("isExchange", false);
            }
            entries.put(entry);
        }

        result.put("success", true);
        result.put("customerId", customerId);
        result.put("name", customerRow.elementAt(1).toString());
        result.put("phone", customerRow.elementAt(2) != null ? customerRow.elementAt(2).toString() : "");
        result.put("address", customerRow.elementAt(3) != null ? customerRow.elementAt(3).toString() : "");
        result.put("notes", customerRow.elementAt(4) != null ? customerRow.elementAt(4).toString() : "");
        result.put("advance", advance != null ? advance.toPlainString() : "0");
        result.put("due", due != null ? due.toPlainString() : "0");
        result.put("entries", entries);
    } catch (Exception e) {
        result.put("success", false);
        result.put("message", e.getMessage());
        e.printStackTrace();
    }

    out.print(result.toString());
%>
