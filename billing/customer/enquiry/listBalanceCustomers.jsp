<%@ page language="java" contentType="application/json; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.*, java.math.BigDecimal, org.json.*" %>
<jsp:useBean id="customer" class="currency.currencyBean" />
<%
    request.setCharacterEncoding("UTF-8");
    String filterType = request.getParameter("filterType");
    String keyword = request.getParameter("keyword");
    JSONObject result = new JSONObject();
    JSONArray customers = new JSONArray();

    try {
        Vector list = customer.getCustomersWithBalance(filterType, keyword);
        for (int i = 0; i < list.size(); i++) {
            Vector row = (Vector) list.get(i);
            JSONObject obj = new JSONObject();
            obj.put("id", row.elementAt(0));
            obj.put("name", row.elementAt(1) != null ? row.elementAt(1).toString() : "");
            obj.put("phone", row.elementAt(2) != null ? row.elementAt(2).toString() : "");
            BigDecimal advance = (BigDecimal) row.elementAt(3);
            BigDecimal due = (BigDecimal) row.elementAt(4);
            obj.put("advance", advance != null ? advance.toPlainString() : "0");
            obj.put("due", due != null ? due.toPlainString() : "0");
            customers.put(obj);
        }
        result.put("success", true);
        result.put("customers", customers);
    } catch (Exception e) {
        e.printStackTrace();
        result.put("success", false);
        result.put("message", e.getMessage() != null ? e.getMessage() : "Unable to load customers");
        result.put("customers", customers);
    }

    out.print(result.toString());
%>
