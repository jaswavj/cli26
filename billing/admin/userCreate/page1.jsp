
<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page language="java" import="java.util.*,java.sql.*,java.text.*,java.security.MessageDigest,java.security.NoSuchAlgorithmException,java.security.SecureRandom"%>
<jsp:useBean id="prod" class="product.productBean" />

<%
   String fullName = request.getParameter("fullName");
    String userName = request.getParameter("userName");
    String password = request.getParameter("password");
    // Remove pre-hashing - let addUser method handle it
    String[] modules = request.getParameterValues("modules");
 
    int check=prod.checkTheUserNameExist(userName);
    if (check > 0) {
    out.println("<script type='text/javascript'>");
    out.println("alert('Username already exists!');");
    out.println("window.location.href='" + request.getContextPath() + "/admin/userCreate/page.jsp';");
    out.println("</script>");
    return;
}
    else{
        boolean success = prod.addUser(fullName, userName, password, modules);
        response.sendRedirect(request.getContextPath() + "/admin/userCreate/page.jsp");
    }
    

    
%>
