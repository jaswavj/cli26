<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page language="java" import="java.util.*"%>
<jsp:useBean id="users" class="user.userBean" />

<%
    String userIdStr = request.getParameter("userId");
    String[] selectedPermissions = request.getParameterValues("permissions");
    
    int userId = 0;
    if (userIdStr != null && !userIdStr.isEmpty()) {
        userId = Integer.parseInt(userIdStr);
    }
    
    try {
        // Update user special permissions
        users.updateUserSpecialPermissions(userId, selectedPermissions);
        
        response.sendRedirect(request.getContextPath() + "/admin/specialPermission/page.jsp?msg=Special permissions updated successfully&type=success");
    } catch (Exception e) {
        e.printStackTrace();
        response.sendRedirect(request.getContextPath() + "/admin/specialPermission/page.jsp?msg=Error updating special permissions: " + e.getMessage() + "&type=danger");
    }
%>
