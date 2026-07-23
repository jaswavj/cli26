<%@ page language="java" contentType="application/json; charset=UTF-8" pageEncoding="UTF-8"%>
<jsp:useBean id="bill" class="billing.billingBean" />
<%
    try {
        String billNo = request.getParameter("billNo");
        String lrNo = request.getParameter("lrNo");
        String lrDate = request.getParameter("lrDate");
        String lrName = request.getParameter("lrName");
        
        System.out.println("Updating LR Details - BillNo: " + billNo + ", LR No: " + lrNo + ", LR Date: " + lrDate + ", LR Name: " + lrName);
        
        if (billNo == null || billNo.trim().isEmpty()) {
            out.print("{\"success\":false,\"message\":\"Bill number is required\"}");
            return;
        }
        
        // Set default values for empty fields
        if (lrNo == null) lrNo = "";
        if (lrDate == null || lrDate.trim().isEmpty()) lrDate = null;
        if (lrName == null) lrName = "";
        
        bill.updateLRDetails(billNo, lrNo, lrDate, lrName);
        System.out.println("LR Details updated successfully for bill: " + billNo);
        out.print("{\"success\":true,\"message\":\"LR details updated successfully\"}");
    } catch (Exception e) {
        System.err.println("Error updating LR details: " + e.getMessage());
        e.printStackTrace();
        out.print("{\"success\":false,\"message\":\"" + e.getMessage().replace("\"", "\\\"") + "\"}");
    }
%>
