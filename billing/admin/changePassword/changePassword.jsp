<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>


<!DOCTYPE html>
<html>
<head>
    <title>Change Password</title>
    <%@ include file="/assets/common/head.jsp" %>
</head>
<body>
    <%@ include file="/assets/navbar/navbar.jsp" %>
<%
    request.setAttribute("pageTitle",    "Change Password");
    request.setAttribute("pageSubtitle", "Admin — Account Security");
    request.setAttribute("pageIcon",     "fa-solid fa-key");
%>
<jsp:include page="/assets/common/pageHeader.jsp" />

<%
String msg = request.getParameter("msg");
String type = request.getParameter("type");
%>
<% if (msg != null) { %>
<div class="alert alert-<%= (type != null ? type : "info") %> alert-dismissible fade show mx-3" role="alert">
  <%= msg %>
  <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Close"></button>
</div>
<% } %>

<div class="container-fluid mt-3 mst-page">
    <form action="<%= request.getContextPath() %>/admin/changePassword/updatePassword.jsp" method="post" class="card mst-card p-4" style="max-width: 480px; margin: 0 auto;">
                <input type="hidden" name="username" value="<%=session.getAttribute("username")%>">

                <div class="mb-3">
                    <label for="oldPassword" class="form-label">existing password</label>
                    <input type="password" name="oldPassword" id="oldPassword" class="form-control fg-inp" required>
                </div>

                <div class="mb-3">
                    <label for="newPassword" class="form-label">New Password</label>
                    <input type="password" name="newPassword" id="newPassword" class="form-control fg-inp" required>
                </div>

                <div class="mb-3">
                    <label for="confirmPassword" class="form-label">Confirm New Password</label>
                    <input type="password" name="confirmPassword" id="confirmPassword" class="form-control fg-inp" required>
                </div>

                <div class="d-flex justify-content-between gap-2">
                    <button type="submit" class="bb bb-primary">Update Password</button>
                    <a href="${pageContext.request.contextPath}/dashboard.jsp" class="bb bb-outline">Home</a>
                </div>
            </form>
</div>
</body>
</html>
