<%@ page language="java" contentType="application/json; charset=UTF-8" pageEncoding="UTF-8"%>
<jsp:useBean id="bill" class="billing.billingBean" />
<%
    try {
        String result = bill.checkDueCheques();
        out.print(result);
    } catch (Exception e) {
        e.printStackTrace();
        out.print("{\"hasBillsToday\":false,\"hasDueCheques\":false,\"error\":\"" + e.getMessage().replace("\"", "\\\"") + "\"}");
    }
%>
