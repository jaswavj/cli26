<%@ page language="java" contentType="application/json; charset=UTF-8" pageEncoding="UTF-8"%>
<jsp:useBean id="bill" class="billing.billingBean" />
<%
    String customerIdStr = request.getParameter("customerId");
    
    if (customerIdStr == null || customerIdStr.trim().isEmpty() || customerIdStr.equals("0")) {
        out.print("{\"hasOverdue\":false,\"message\":\"\"}");
        return;
    }
    
    try {
        int customerId = Integer.parseInt(customerIdStr);
        String result = bill.checkOverdueDues(customerId);
        out.print(result);
    } catch (Exception e) {
        e.printStackTrace();
        out.print("{\"hasOverdue\":false,\"message\":\"Error: " + e.getMessage().replace("\"", "\\\"") + "\"}");
    }
%>
