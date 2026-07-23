<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<jsp:useBean id="currency" class="currency.currencyBean" />
<%
int id = Integer.parseInt(request.getParameter("id"));
String action = request.getParameter("action");

try {
    if ("block".equals(action)) {
        currency.updateCurrencyStatus(id, 0);
        response.sendRedirect(request.getContextPath() + "/master/exchange/page.jsp?msg=Currency+blocked+successfully&type=info");
    } else if ("unblock".equals(action)) {
        currency.updateCurrencyStatus(id, 1);
        response.sendRedirect(request.getContextPath() + "/master/exchange/page.jsp?msg=Currency+unblocked+successfully&type=success");
    } else {
        response.sendRedirect(request.getContextPath() + "/master/exchange/page.jsp?msg=Invalid+action&type=danger");
    }
} catch (Exception e) {
    e.printStackTrace();
    response.sendRedirect(request.getContextPath() + "/master/exchange/page.jsp?msg=Error:+"
        + java.net.URLEncoder.encode(e.getMessage(), "UTF-8") + "&type=danger");
}
%>
