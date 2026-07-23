<%@ page language="java" contentType="text/html; charset=UTF-8"%>
<%@ page import="java.util.*" %>
<jsp:useBean id="bill" class="billing.billingBean" />

<%
String code = request.getParameter("code");
String priceCategoryStr = request.getParameter("priceCategory");
int priceCategory = (priceCategoryStr != null && !priceCategoryStr.isEmpty()) ? Integer.parseInt(priceCategoryStr) : 3; // Default to Retailer (3)

// Fetch product details: [id, name, mrp, discount]
Vector getDet = bill.getProductUsingCode(code, priceCategory);

if (getDet == null || getDet.isEmpty() || getDet.get(0).toString().equals("0")) {
    out.print("{\"error\":\"Product not found\"}");
    return;
}

int productId = Integer.parseInt(getDet.get(0).toString());        // prod_id
String name = (String) getDet.get(1);      // product name
String mrp = String.valueOf(getDet.get(2)); 
String discount = String.valueOf(getDet.get(3));
int batchId = Integer.parseInt(getDet.get(4).toString());
String unitId = getDet.size() > 5 && getDet.get(5) != null ? getDet.get(5).toString() : "";
String unitName = getDet.size() > 6 && getDet.get(6) != null ? getDet.get(6).toString() : "";
String commission = getDet.size() > 7 && getDet.get(7) != null ? getDet.get(7).toString() : "0";
String convertionUnit = getDet.size() > 8 && getDet.get(8) != null ? getDet.get(8).toString() : "";

String json = "{\"id\":\"" + productId + "\","
             + "\"name\":\"" + name + "\","
             + "\"mrp\":\"" + mrp + "\","
             + "\"discount\":\"" + discount + "\","
             + "\"batchId\":\"" + batchId + "\","
             + "\"unitId\":\"" + unitId + "\","
             + "\"unitName\":\"" + unitName + "\","
             + "\"commission\":\"" + commission + "\","
             + "\"convertionUnit\":\"" + convertionUnit + "\"}";
out.print(json);
%>
