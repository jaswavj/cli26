<%@ page language="java" contentType="application/json; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.*, org.json.*, java.math.BigDecimal" %>
<jsp:useBean id="exchange" class="currency.exchangeBean" />
<%
    request.setCharacterEncoding("UTF-8");
    JSONObject result = new JSONObject();
    JSONArray currencies = new JSONArray();
    try {
        int baseCurrencyId = exchange.getBaseCurrencyId();
        int bankCurrencyId = exchange.getBankCurrencyId();
        Vector list = exchange.getCurrenciesWithLimits();
        for (int i = 0; i < list.size(); i++) {
            Vector row = (Vector) list.get(i);
            JSONObject obj = new JSONObject();
            obj.put("id", row.elementAt(0));
            obj.put("code", row.elementAt(1).toString());
            obj.put("name", row.elementAt(2).toString());
            BigDecimal minVal = (BigDecimal) row.elementAt(3);
            BigDecimal maxVal = (BigDecimal) row.elementAt(4);
            BigDecimal stock = (BigDecimal) row.elementAt(5);
            obj.put("min", minVal != null ? minVal.toPlainString() : "0");
            obj.put("max", maxVal != null ? maxVal.toPlainString() : "0");
            obj.put("stock", stock != null ? stock.toPlainString() : "0");
            obj.put("isBase", baseCurrencyId > 0 && baseCurrencyId == ((Integer) row.elementAt(0)).intValue());
            obj.put("isBank", bankCurrencyId > 0 && bankCurrencyId == ((Integer) row.elementAt(0)).intValue());
            currencies.put(obj);
        }
        result.put("currencies", currencies);
        result.put("baseCurrencyId", baseCurrencyId);
        result.put("bankCurrencyId", bankCurrencyId);
    } catch (Exception e) {
        e.printStackTrace();
        result.put("currencies", currencies);
        result.put("baseCurrencyId", 0);
        result.put("bankCurrencyId", 0);
    }
    out.print(result.toString());
%>
