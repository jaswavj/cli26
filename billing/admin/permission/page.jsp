<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page language="java" import="java.util.*,java.sql.*,java.text.*"%>
<jsp:useBean id="prod" class="product.productBean" />

<%
    
%>
<!DOCTYPE html>
<html>
<head>
    <title>Select User</title>
    <%@ include file="/assets/common/head.jsp" %>
</head>
<body>
<!--%@ include file="../menu/adminMenu.jsp" %-->
        <%@ include file="/assets/navbar/navbar.jsp" %>
<%
    request.setAttribute("pageTitle",    "Permissions");
    request.setAttribute("pageSubtitle", "Admin — Select User");
    request.setAttribute("pageIcon",     "fa-solid fa-shield-halved");
%>
<jsp:include page="/assets/common/pageHeader.jsp" />

<div class="container-fluid mt-3 mst-page">
    <form action="<%= request.getContextPath() %>/admin/permission/page1.jsp" method="get" class="card mst-card p-4" style="max-width: 500px; margin: 0 auto;">
                        <div class="mb-3">
                            <label class="form-label fw-bold">Choose a User</label>
                            <select name="userId" class="form-select fg-inp" required>
                                <option value="">-- Select User --</option>
                                <%
                                Vector userList = prod.getAllUser(); 

                                for(int i=0; i<userList.size(); i++){
                                    Vector row = (Vector) userList.elementAt(i);
                                    String userId = row.get(0).toString();
                                    String  uname= row.get(1).toString();
                            %>
                                <option value="<%=userId%>"><%=uname%></option>
                            <%
                                }
                            %>
                            </select>
                        </div>
                        <div class="d-grid">
                            <button type="submit" class="bb bb-primary w-100">Give Permissions</button>
                        </div>
    </form>
</div>
</body>
</html>
