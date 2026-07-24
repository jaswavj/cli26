<%@ page language="java" contentType="application/json; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.*, org.json.*, java.math.BigDecimal" %>
<jsp:useBean id="exchange" class="currency.exchangeBean" />
<%
    request.setCharacterEncoding("UTF-8");
    JSONObject result = new JSONObject();
    try {
        int currencyId = Integer.parseInt(request.getParameter("currencyId"));
        int counterCurrencyId = Integer.parseInt(request.getParameter("counterCurrencyId"));
        Vector limits = exchange.getCurrencyPairLimits(currencyId, counterCurrencyId);
        BigDecimal minVal = (BigDecimal) limits.elementAt(0);
        BigDecimal maxVal = (BigDecimal) limits.elementAt(1);
        result.put("success", true);
        result.put("min", minVal.toPlainString());
        result.put("max", maxVal.toPlainString());
        result.put("hasLimit", maxVal.compareTo(BigDecimal.ZERO) > 0);
    } catch (Exception e) {
        result.put("success", false);
        result.put("min", "0");
        result.put("max", "0");
        result.put("hasLimit", false);
        result.put("message", e.getMessage());
    }
    out.print(result.toString());
%>
