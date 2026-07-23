<%@ page import="java.util.*" %>
<jsp:useBean id="prod" class="product.productBean" />

<%
Integer uid = (Integer) session.getAttribute("userId");

String oldPassword = request.getParameter("oldPassword");
String newPassword = request.getParameter("newPassword");
String confirmPassword = request.getParameter("confirmPassword");

if (oldPassword.equals(newPassword)) {
    response.sendRedirect(request.getContextPath() + "/admin/changePassword/changePassword.jsp?msg=Old+password+and+new+password+should+not+match!&type=warning");
    return;
}

if (!confirmPassword.equals(newPassword)) {
    response.sendRedirect(request.getContextPath() + "/admin/changePassword/changePassword.jsp?msg=New+password+and+confirm+password+should+match!&type=warning");
    return;
}

boolean success = prod.validateOldPassword(uid, oldPassword);
if (!success) {
    response.sendRedirect(request.getContextPath() + "/admin/changePassword/changePassword.jsp?msg=Your+existing+password+is+wrong!&type=danger");
    return;
}

prod.updatePassword(uid, newPassword);
response.sendRedirect(request.getContextPath() + "/index.jsp?msg=Password+changed+successfully&type=success");
%>

