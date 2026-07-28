<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page language="java" import="java.math.BigDecimal"%>
<jsp:useBean id="customer" class="currency.currencyBean" />
<%
int customerId = Integer.parseInt(request.getParameter("customerId"));
BigDecimal amount = new BigDecimal(request.getParameter("amount").trim());
String notes = request.getParameter("notes");
int paymentId = Integer.parseInt(request.getParameter("paymentId"));

try {
    customer.payAdvance(customerId, amount, notes, paymentId);
    response.sendRedirect(request.getContextPath() + "/customer/enquiry/page.jsp?customerId=" + customerId
        + "&msg=Purchase+balance+paid+successfully&type=success");
} catch (Exception e) {
    e.printStackTrace();
    response.sendRedirect(request.getContextPath() + "/customer/enquiry/page.jsp?customerId=" + customerId
        + "&msg=Error:+ " + java.net.URLEncoder.encode(e.getMessage(), "UTF-8") + "&type=danger");
}
%>
