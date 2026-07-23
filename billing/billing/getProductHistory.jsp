<%@ page language="java" contentType="application/json; charset=UTF-8"%>
<jsp:useBean id="bill" class="billing.billingBean" />

<%
String productIdStr = request.getParameter("productId");
String customerIdStr = request.getParameter("customerId");

if (productIdStr == null || productIdStr.trim().isEmpty()) {
    out.print("{\"error\":\"Product ID is required\"}");
    return;
}

int productId = Integer.parseInt(productIdStr);
int customerId = (customerIdStr != null && !customerIdStr.trim().isEmpty()) ? Integer.parseInt(customerIdStr) : 0;

try {
    String result = bill.getProductHistory(productId, customerId);
    out.print(result);
} catch (Exception e) {
    out.print("{\"error\":\"" + e.getMessage() + "\"}");
}
%>
