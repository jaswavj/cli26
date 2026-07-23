<%@ page language="java" contentType="text/html; charset=UTF-8"%>
<jsp:useBean id="bill" class="billing.billingBean" />
<%
try {
    String quotIdStr = request.getParameter("quotId");
    
    if (quotIdStr == null || quotIdStr.trim().isEmpty()) {
        response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
        out.print("ERROR: Missing quotation ID");
        return;
    }
    
    int quotId = Integer.parseInt(quotIdStr);
    
    // Cancel the quotation (now with transaction rollback)
    bill.cancelQuotation(quotId);
    
    out.print("SUCCESS: Quotation cancelled");
    
} catch (NumberFormatException e) {
    response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
    out.print("ERROR: Invalid quotation ID");
    e.printStackTrace();
} catch (Exception e) {
    response.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
    out.print("ERROR: " + e.getMessage());
    e.printStackTrace();
}
%>
