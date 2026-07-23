<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<jsp:useBean id="customer" class="currency.currencyBean" />
<%
int id = Integer.parseInt(request.getParameter("id"));
String action = request.getParameter("action");

try {
    if ("block".equals(action)) {
        customer.updateCustomerStatus(id, 0);
        response.sendRedirect(request.getContextPath() + "/customer/master/page.jsp?msg=Customer+blocked+successfully&type=info");
    } else if ("unblock".equals(action)) {
        customer.updateCustomerStatus(id, 1);
        response.sendRedirect(request.getContextPath() + "/customer/master/page.jsp?msg=Customer+unblocked+successfully&type=success");
    } else {
        response.sendRedirect(request.getContextPath() + "/customer/master/page.jsp?msg=Invalid+action&type=danger");
    }
} catch (Exception e) {
    e.printStackTrace();
    response.sendRedirect(request.getContextPath() + "/customer/master/page.jsp?msg=Error:+"
        + java.net.URLEncoder.encode(e.getMessage(), "UTF-8") + "&type=danger");
}
%>
