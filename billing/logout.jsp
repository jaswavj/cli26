<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%
// Prevent caching
response.setHeader("Cache-Control", "no-cache, no-store, must-revalidate");
response.setHeader("Pragma", "no-cache");
response.setDateHeader("Expires", 0);

// Invalidate the session
if (session != null) {
    session.invalidate();
}

// Redirect to login page
response.sendRedirect(request.getContextPath() + "/");
%>
