<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page language="java" import="java.util.*"%>
<jsp:useBean id="users" class="user.userBean" />

<%
    String uidStr = request.getParameter("userId");
    int userId = 0;
    if (uidStr != null && !uidStr.isEmpty()) {
        userId = Integer.parseInt(uidStr);
    }

    // Get all special permissions from special_permission table
    Vector allSpecialPermissions = users.getAllSpecialPermissions();
    
    // Get user's existing special permissions
    Vector userSpecialPermissions = users.getUserSpecialPermissions(userId);
    
    // Convert userSpecialPermissions to Set for easy lookup
    Set<Integer> userPermissionIds = new HashSet<Integer>();
    for (Object obj : userSpecialPermissions) {
        if (obj instanceof Vector) {
            Vector row = (Vector) obj;
            if (!row.isEmpty()) {
                userPermissionIds.add(Integer.parseInt(row.get(0).toString()));
            }
        }
    }
%>

<!DOCTYPE html>
<html>
<head>
    <title>Special Permissions</title>
    <%@ include file="/assets/common/head.jsp" %>
</head>
<body>
    <%@ include file="/assets/navbar/navbar.jsp" %>
<%
    request.setAttribute("pageTitle",    "Special Permissions");
    request.setAttribute("pageSubtitle", "Admin — Manage User Permissions");
    request.setAttribute("pageIcon",     "fa-solid fa-lock");
%>
<jsp:include page="/assets/common/pageHeader.jsp" />

<div class="container-fluid mt-3 mst-page">
    <div class="card mst-card p-4" style="max-width: 600px; margin: 0 auto;">
        <p class="text-muted mb-3">User ID: <%=userId%></p>
                        
                        <form action="<%= request.getContextPath() %>/admin/specialPermission/page2.jsp" method="post">
                            <input type="hidden" name="userId" value="<%=userId%>">
                            
                            <div class="mb-4">
                                <h5 class="text-secondary mb-3">Select Special Permissions:</h5>
                                
                                <%
                                for (int i = 0; i < allSpecialPermissions.size(); i++) {
                                    Vector permission = (Vector) allSpecialPermissions.get(i);
                                    int contentId = Integer.parseInt(permission.get(0).toString());
                                    String content = permission.get(1).toString();
                                    boolean checked = userPermissionIds.contains(contentId);
                                %>
                                <div class="form-check">
                                    <input class="form-check-input" type="checkbox" 
                                           name="permissions" 
                                           value="<%=contentId%>"
                                           id="perm<%=contentId%>"
                                           <%=checked ? "checked" : ""%>>
                                    <label class="form-check-label" for="perm<%=contentId%>">
                                        <%=content%>
                                    </label>
                                </div>
                                <%
                                }
                                %>
                            </div>
                            
                            <div class="d-flex gap-2">
                                <button type="submit" class="bb bb-primary">
                                    <i class="fa-solid fa-floppy-disk me-2"></i>Update Permissions
                                </button>
                                <a href="<%=request.getContextPath()%>/admin/specialPermission/page.jsp" class="bb bb-outline">
                                    <i class="fa-solid fa-arrow-left me-2"></i>Back
                                </a>
                            </div>
                        </form>
    </div>
</div>
</body>
</html>
