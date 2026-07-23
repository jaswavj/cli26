<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page language="java" import= "java.util.*"%>
<%@ page language="java" import= "java.util.*,java.text.*" %>
<jsp:useBean id="prod" class="user.userBean" />
<%
Vector userList = prod.getUserModules();
%>
<!DOCTYPE html>
<html>
<head>
    <title>Create User</title>
    <%@ include file="/assets/common/head.jsp" %>
</head>
<body>
    <%@ include file="/assets/navbar/navbar.jsp" %>
<%
    request.setAttribute("pageTitle",    "Create User");
    request.setAttribute("pageSubtitle", "Admin — User Management");
    request.setAttribute("pageIcon",     "fa-solid fa-user-plus");
%>
<jsp:include page="/assets/common/pageHeader.jsp" />

<div class="container-fluid mt-3 mst-page">

    <form action="<%= request.getContextPath() %>/admin/userCreate/page1.jsp" method="post" class="card mst-card p-4" style="max-width: 600px; margin: 0 auto;">

    <!-- Full Name -->
    <div class="mb-3">
        <label class="form-label">Full Name</label>
        <input type="text" name="fullName" class="form-control fg-inp" required>
    </div>

    <!-- Username -->
    <div class="mb-3">
        <label class="form-label">Username</label>
        <input type="text" name="userName" class="form-control fg-inp" required>
    </div>

    <!-- Password -->
    <div class="mb-3">
        <label class="form-label">Password</label>
        <input type="password" name="password" class="form-control fg-inp" required>
    </div>

    <!-- Module Permissions -->
    <div class="mb-3">
        <label class="form-label">Module Permissions</label><br>
        <%
        
        for (int i = 0; i < userList.size(); i++) {
            Vector module = (Vector) userList.get(i);
            String moduleId = module.get(0).toString();
            String moduleName = module.get(1).toString();
        
        %>
        <div class="form-check">
            <input class="form-check-input" type="checkbox" name="modules" value="<%=moduleId%>" id="billing">
            <label class="form-check-label" for="billing"><%=moduleName%></label>
        </div>
        <%
    }   
        %>
        <!--div class="form-check">
            <input class="form-check-input" type="checkbox" name="modules" value="2" id="product">
            <label class="form-check-label" for="product">Product</label>
        </div>
        <div class="form-check">
            <input class="form-check-input" type="checkbox" name="modules" value="3" id="reports">
            <label class="form-check-label" for="reports">Reports</label>
        </div>
        <div class="form-check">
            <input class="form-check-input" type="checkbox" name="modules" value="4" id="admin">
            <label class="form-check-label" for="admin">Admin</label>
        </div>
        <div class="form-check">
            <input class="form-check-input" type="checkbox" name="modules" value="5" id="admin">
            <label class="form-check-label" for="admin">Inventory</label>
        </div-->
    </div>

    <!-- Submit -->
    <div class="d-grid">
        <button type="submit" class="bb bb-primary w-100">Create User</button>
    </div>
    </form>

</div>
</body>
</html>
