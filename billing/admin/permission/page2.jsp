<%@ page import="java.util.*, java.sql.*" %>
<jsp:useBean id="prod" class="product.productBean" />

<%
    String uidStr = request.getParameter("userId1");
    int userId2 = Integer.parseInt(uidStr);

    String[] selectedModules = request.getParameterValues("modules");


    prod.clearUserPermissions(userId2);


    if (selectedModules != null) {
        for (String moduleIdStr : selectedModules) {
            int moduleId = Integer.parseInt(moduleIdStr);
            prod.addUserPermission(userId2, moduleId);
        }
    }
%>

<!DOCTYPE html>
<html>
<head>
    <title>Permissions Updated</title>
    <%@ include file="/assets/common/head.jsp" %>
</head>
<body>
    <!--%@ include file="../menu/adminMenu.jsp" %-->
        <%@ include file="/assets/navbar/navbar.jsp" %>
<%
    request.setAttribute("pageTitle",    "Permissions Updated");
    request.setAttribute("pageSubtitle", "Admin — Permissions");
    request.setAttribute("pageIcon",     "fa-solid fa-circle-check");
%>
<jsp:include page="/assets/common/pageHeader.jsp" />

<div class="container-fluid mt-3 mst-page">
        <a href="<%= request.getContextPath() %>/admin/permission/page.jsp?userId1=<%=userId2%>" class="bb bb-outline">Go Back</a>
</div>
</body>
</html>
