<%@ page language="java" contentType="application/json; charset=UTF-8" pageEncoding="UTF-8"%>
<jsp:useBean id="bill" class="billing.billingBean" />
<%
    Integer userId = (Integer) session.getAttribute("userId");
    
    try {
        if (userId == null) {
            out.print("{\"hasPermission\":false}");
            return;
        }
        
        boolean hasPermission = bill.checkUserSpecialPermission(userId, 1);
        out.print("{\"hasPermission\":" + hasPermission + "}");
    } catch (Exception e) {
        e.printStackTrace();
        out.print("{\"hasPermission\":false}");
    }
%>
