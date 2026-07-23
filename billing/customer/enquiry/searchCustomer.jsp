<%@ page language="java" contentType="application/json; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.*, org.json.*" %>
<jsp:useBean id="customer" class="currency.currencyBean" />
<%
    request.setCharacterEncoding("UTF-8");
    String query = request.getParameter("query");
    JSONArray results = new JSONArray();

    try {
        if (query != null && query.trim().length() > 0) {
            Vector customers = customer.searchCustomers(query.trim());
            for (int i = 0; i < customers.size(); i++) {
                Vector row = (Vector) customers.get(i);
                JSONObject obj = new JSONObject();
                obj.put("id", row.elementAt(0));
                obj.put("name", row.elementAt(1) != null ? row.elementAt(1).toString() : "");
                obj.put("phone", row.elementAt(2) != null ? row.elementAt(2).toString() : "");
                obj.put("address", row.elementAt(3) != null ? row.elementAt(3).toString() : "");
                obj.put("notes", row.elementAt(4) != null ? row.elementAt(4).toString() : "");
                results.put(obj);
            }
        }
    } catch (Exception e) {
        e.printStackTrace();
    }

    out.print(results.toString());
%>
