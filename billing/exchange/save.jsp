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
String exchangeTypeStr = request.getParameter("exchangeType");
String exchangeDate = request.getParameter("exchangeDate");
String currencyIdStr = request.getParameter("currencyId");
String amountStr = request.getParameter("amount");
String counterCurrencyIdStr = request.getParameter("counterCurrencyId");
String counterAmountStr = request.getParameter("counterAmount");
String paidStr = request.getParameter("paid");
String paymentIdStr = request.getParameter("paymentId");
String notes = request.getParameter("notes");

try {
    int customerId = 0;
    if (customerIdStr != null && !customerIdStr.trim().isEmpty()) {
        customerId = Integer.parseInt(customerIdStr.trim());
    }
    if (customerId <= 0) {
        customerId = exchange.findOrCreateCustomer(customerName, customerPhone);
    }

    int exchangeType = Integer.parseInt(exchangeTypeStr);
    int currencyId = Integer.parseInt(currencyIdStr);
    BigDecimal amount = new BigDecimal(amountStr.trim());
    int counterCurrencyId = Integer.parseInt(counterCurrencyIdStr);
    BigDecimal counterAmount = new BigDecimal(counterAmountStr.trim());
    BigDecimal paid = (paidStr != null && paidStr.trim().length() > 0)
        ? new BigDecimal(paidStr.trim()) : counterAmount;
    int paymentId = Integer.parseInt(paymentIdStr);

    exchange.saveExchange(customerId, exchangeType, exchangeDate, currencyId, amount,
        counterCurrencyId, counterAmount, paid, paymentId, notes, userId);

    response.sendRedirect(request.getContextPath() + "/exchange/page.jsp?msg=Exchange+saved+successfully&type=success");
} catch (Exception e) {
    e.printStackTrace();
    response.sendRedirect(request.getContextPath() + "/exchange/page.jsp?msg=Error:+"
        + java.net.URLEncoder.encode(e.getMessage(), "UTF-8") + "&type=danger");
}
%>
