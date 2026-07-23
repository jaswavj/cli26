<%@ page language="java" contentType="application/json; charset=UTF-8"%>
<%@ page import="java.util.*" %>
<%@ page import="print.OrderPrinter" %>
<jsp:useBean id="userBean" class="user.userBean" scope="page"/>
<%
/**
 * Direct Order Print Endpoint
 * POST/GET  directPrintOrder.jsp?orderId=XXX  - Print order
 */

response.setContentType("application/json");
response.setCharacterEncoding("UTF-8");

// Check if user is logged in
if (session.getAttribute("userId") == null) {
    response.setStatus(401);
    out.print("{\"success\":false,\"message\":\"Not authenticated\"}");
    return;
}

// Print order
String orderId = request.getParameter("orderId");

if (orderId == null || orderId.trim().isEmpty()) {
    response.setStatus(400);
    out.print("{\"success\":false,\"message\":\"Missing order ID\"}");
    return;
}

// Check company print format preference
int printType = 1; // Default: Thermal
try {
    Vector companyDetails = userBean.getCompanyDetails();
    if (companyDetails != null && companyDetails.size() > 4) {
        Object ptObj = companyDetails.elementAt(4);
        if (ptObj != null) {
            printType = ((Integer)ptObj).intValue();
        }
    }
} catch (Exception e) {
    e.printStackTrace();
}

// If A4 format selected, return redirect instruction
if (printType == 2) {
    out.print("{\"success\":true,\"type\":\"a4\",\"orderId\":\"" + orderId.trim() + "\",\"message\":\"Opening A4 print preview\"}");
    return;
}

try {
    // Set application path for cloud deployment compatibility
    OrderPrinter.setApplicationPath(application.getRealPath("/"));
    
    print.OrderPrinter.PrintResult result = OrderPrinter.printOrder(orderId.trim());
    if (result.printed) {
        out.print("{\"success\":true,\"type\":\"printed\",\"message\":\"" + result.message.replace("\"", "'") + "\"}");
    } else if (result.txtSaved) {
        String safePath = result.txtPath.replace("\\", "/").replace("\"", "'");
        String safeOrderId = orderId.trim().replace("/", "-").replace("\\", "-").replace(" ", "_");
        out.print("{\"success\":true,\"type\":\"txt\",\"message\":\"" + result.message.replace("\\", "/").replace("\"", "'") + "\",\"txtFile\":\"Order_" + safeOrderId + ".txt\",\"txtPath\":\"" + safePath + "\"}");
    } else {
        response.setStatus(500);
        out.print("{\"success\":false,\"message\":\"Print failed - unknown error\"}");
    }
} catch (Exception e) {
    e.printStackTrace();
    response.setStatus(500);
    String msg = e.getMessage() != null ? e.getMessage().replace("\"", "'").replace("\n", " ") : "Unknown error";
    out.print("{\"success\":false,\"message\":\"Print error: " + msg + "\"}");
}
%>
