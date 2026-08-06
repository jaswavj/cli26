<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.math.BigDecimal" %>
<jsp:useBean id="currency" class="currency.currencyBean" />
<%
Integer userId = (Integer) session.getAttribute("userId");
if (userId == null) {
    response.sendRedirect(request.getContextPath() + "/index.jsp");
    return;
}

String particular = request.getParameter("particular");
String amountStr = request.getParameter("amount");
String description = request.getParameter("description");

try {
    BigDecimal amount = new BigDecimal(amountStr.trim());
    currency.addAdditionalIncome(particular, amount, description, userId);
    response.sendRedirect(request.getContextPath() + "/income/additionalIncome/page.jsp?msg=Additional+income+saved+successfully&type=success");
} catch (Exception e) {
    response.sendRedirect(request.getContextPath() + "/income/additionalIncome/page.jsp?msg="
        + java.net.URLEncoder.encode("Error: " + e.getMessage(), "UTF-8") + "&type=danger");
}
%>
