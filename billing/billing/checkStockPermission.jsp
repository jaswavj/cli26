<%@ page import="org.json.*, user.userBean" %>
<%
    response.setContentType("application/json");
    Integer uid = (Integer) session.getAttribute("userId");
    
    userBean userBeanObj = new userBean();
    boolean hasPermission = false;
    
    if (uid != null) {
        // Check if user has special permission with content_id=1 (No stock check)
        hasPermission = userBeanObj.checkUserSpecialPermission(uid, 1);
    }
    
    JSONObject result = new JSONObject();
    result.put("hasPermission", hasPermission);
    out.print(result.toString());
%>
