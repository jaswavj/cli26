<%@ page language="java" contentType="application/json; charset=UTF-8" pageEncoding="UTF-8"%>
<jsp:useBean id="bill" class="billing.billingBean" />
<%
    try {
        String customerIdStr = request.getParameter("customerId");
        if (customerIdStr == null || customerIdStr.trim().isEmpty()) {
            out.print("[]");
            return;
        }
        
        int customerId = Integer.parseInt(customerIdStr);
        String result = bill.getAvailableChequesForCustomer(customerId);
        out.print(result);
    } catch (Exception e) {
        e.printStackTrace();
        out.print("[]");
    }
%>
