<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page language="java" import="java.math.BigDecimal"%>
<jsp:useBean id="exchange" class="currency.exchangeBean" />
<%
Integer userId = (Integer) session.getAttribute("userId");
if (userId == null) {
    response.sendRedirect(request.getContextPath() + "/index.jsp");
    return;
}

String customerIdStr = request.getParameter("customerId");
String customerName = request.getParameter("customerName");
String customerPhone = request.getParameter("customerPhone");
String currencyIdStr = request.getParameter("currencyId");
String transferTypeStr = request.getParameter("transferType");
String transferDate = request.getParameter("transferDate");
String quantityStr = request.getParameter("quantity");
String notes = request.getParameter("notes");

try {
    int customerId = 0;
    if (customerIdStr != null && !customerIdStr.trim().isEmpty()) {
        customerId = Integer.parseInt(customerIdStr.trim());
    }
    if (customerId <= 0) {
        customerId = exchange.findOrCreateCustomer(customerName, customerPhone);
    }

    int currencyId = Integer.parseInt(currencyIdStr);
    int transferType = Integer.parseInt(transferTypeStr);
    BigDecimal quantity = new BigDecimal(quantityStr.trim());

    exchange.saveCurrencyTransfer(customerId, currencyId, transferType, transferDate, quantity, notes, userId);

    response.sendRedirect(request.getContextPath() + "/transfer/page.jsp?msg=Transfer+saved+successfully&type=success");
} catch (Exception e) {
    e.printStackTrace();
    response.sendRedirect(request.getContextPath() + "/transfer/page.jsp?msg=Error:+"
        + java.net.URLEncoder.encode(e.getMessage(), "UTF-8") + "&type=danger");
}
%>
