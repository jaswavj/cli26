<%@ page language="java" contentType="application/json; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.*, org.json.*, java.math.BigDecimal" %>
<jsp:useBean id="exchange" class="currency.exchangeBean" />
<%
    request.setCharacterEncoding("UTF-8");
    JSONObject result = new JSONObject();

    try {
        String customerIdStr = request.getParameter("customerId");
        if (customerIdStr == null || customerIdStr.trim().isEmpty()) {
            result.put("success", false);
            result.put("message", "Customer is required");
            out.print(result.toString());
            return;
        }

        int customerId = Integer.parseInt(customerIdStr.trim());
        Vector balances = exchange.getCustomerBalanceSummary(customerId);
        BigDecimal advance = (BigDecimal) balances.elementAt(0);
        BigDecimal due = (BigDecimal) balances.elementAt(1);

        result.put("success", true);
        result.put("advance", advance != null ? advance.toPlainString() : "0");
        result.put("due", due != null ? due.toPlainString() : "0");
    } catch (Exception e) {
        result.put("success", false);
        result.put("message", e.getMessage());
        e.printStackTrace();
    }

    out.print(result.toString());
%>
