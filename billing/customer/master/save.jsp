<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<jsp:useBean id="customer" class="currency.currencyBean" />
<%
String customerName = request.getParameter("customerName");
String phoneNumber = request.getParameter("phoneNumber");
String address = request.getParameter("address");
String notes = request.getParameter("notes");

try {
    if (customerName == null || customerName.trim().isEmpty()) {
        response.sendRedirect(request.getContextPath() + "/customer/master/page.jsp?msg=Customer+name+is+required&type=danger");
        return;
    }

    customer.addCustomer(customerName, phoneNumber, address, notes);
    response.sendRedirect(request.getContextPath() + "/customer/master/page.jsp?msg=Customer+added+successfully&type=success");
} catch (Exception e) {
    e.printStackTrace();
    response.sendRedirect(request.getContextPath() + "/customer/master/page.jsp?msg=Error:+"
        + java.net.URLEncoder.encode(e.getMessage(), "UTF-8") + "&type=danger");
}
%>
