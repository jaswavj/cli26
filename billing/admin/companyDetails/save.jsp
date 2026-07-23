<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<jsp:useBean id="userBean" class="user.userBean" scope="page"/>

<%
    // Get form parameters
    String shopName = request.getParameter("shopName");
    String address = request.getParameter("address");
    String gstin = request.getParameter("gstin");
    String printTypeStr = request.getParameter("printType");
    String printerName = request.getParameter("printerName");
    String bankDetails = request.getParameter("bankDetails");
    String barcodePrinter = request.getParameter("barcodePrinter");
    
    // Validate required fields
    if (shopName == null || shopName.trim().isEmpty() || 
        address == null || address.trim().isEmpty() ||
        printTypeStr == null || printTypeStr.trim().isEmpty()) {
        response.sendRedirect(request.getContextPath() + "/admin/companyDetails/page.jsp?msg=Please fill all required fields&type=danger");
        return;
    }
    
    // Parse print type
    int printType = 1;
    try {
        printType = Integer.parseInt(printTypeStr);
        if (printType != 1 && printType != 2) {
            response.sendRedirect(request.getContextPath() + "/admin/companyDetails/page.jsp?msg=Invalid print type&type=danger");
            return;
        }
    } catch (NumberFormatException e) {
        response.sendRedirect(request.getContextPath() + "/admin/companyDetails/page.jsp?msg=Invalid print type format&type=danger");
        return;
    }
    
    // Validate printer name for thermal printer
    if (printType == 1 && (printerName == null || printerName.trim().isEmpty())) {
        response.sendRedirect(request.getContextPath() + "/admin/companyDetails/page.jsp?msg=Printer name is required for thermal printing&type=danger");
        return;
    }
    
    // Trim inputs
    shopName = shopName.trim();
    address = address.trim();
    gstin = (gstin != null) ? gstin.trim() : "";
    printerName = (printerName != null) ? printerName.trim() : "";
    bankDetails = (bankDetails != null) ? bankDetails.trim() : "";
    barcodePrinter = (barcodePrinter != null) ? barcodePrinter.trim() : "";
    
    // Validate GSTIN format if provided
    if (!gstin.isEmpty() && gstin.length() != 15) {
        response.sendRedirect(request.getContextPath() + "/admin/companyDetails/page.jsp?msg=GSTIN must be 15 characters&type=danger");
        return;
    }
    
    try {
        // Save company details
        boolean success = userBean.saveCompanyDetails(shopName, address, gstin, printType, printerName, bankDetails, barcodePrinter);
        
        if (success) {
            response.sendRedirect(request.getContextPath() + "/admin/companyDetails/page.jsp?msg=Company details saved successfully&type=success");
        } else {
            response.sendRedirect(request.getContextPath() + "/admin/companyDetails/page.jsp?msg=Failed to save company details&type=danger");
        }
    } catch (Exception e) {
        e.printStackTrace();
        response.sendRedirect(request.getContextPath() + "/admin/companyDetails/page.jsp?msg=Error: " + e.getMessage() + "&type=danger");
    }
%>
