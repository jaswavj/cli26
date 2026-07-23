<%@ page language="java" contentType="application/json; charset=UTF-8" pageEncoding="UTF-8"%>
<jsp:useBean id="bill" class="billing.billingBean" />
<%
    try {
        String productIdStr = request.getParameter("productId");
        if (productIdStr == null || productIdStr.trim().isEmpty()) {
            out.print("{\"stock\":0}");
            return;
        }
        
        int productId = Integer.parseInt(productIdStr);
        double stock = bill.getProductStock(productId);
        out.print("{\"stock\":" + stock + "}");
    } catch (Exception e) {
        e.printStackTrace();
        out.print("{\"stock\":0}");
    }
%>
