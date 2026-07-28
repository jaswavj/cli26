<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<jsp:useBean id="exchange" class="currency.exchangeBean" />
<%
Integer userId = (Integer) session.getAttribute("userId");
if (userId == null) {
    response.sendRedirect(request.getContextPath() + "/index.jsp");
    return;
}

int transferId = Integer.parseInt(request.getParameter("transferId"));
String returnDate = request.getParameter("returnDate");

try {
    exchange.returnCurrencyTransfer(transferId, returnDate, userId);
    response.sendRedirect(request.getContextPath() + "/transfer/page.jsp?msg=Return+recorded+successfully&type=success");
} catch (Exception e) {
    e.printStackTrace();
    response.sendRedirect(request.getContextPath() + "/transfer/page.jsp?msg=Error:+"
        + java.net.URLEncoder.encode(e.getMessage(), "UTF-8") + "&type=danger");
}
%>
