<%@ page language="java" contentType="application/json; charset=UTF-8"%>
<%@ page import="java.util.*" %>
<%@ page import="print.POSPrinter" %>
<jsp:useBean id="userBean" class="user.userBean" scope="page"/>
<%
// Direct Thermal Print Endpoint (JSP-based)
// POST/GET  directPrint.jsp?billNo=XXX         - Print receipt
// GET       directPrint.jsp?action=printers    - List available printers

response.setContentType("application/json");
response.setCharacterEncoding("UTF-8");

// Check if user is logged in
if (session.getAttribute("userId") == null) {
    response.setStatus(401);
    out.print("{\"success\":false,\"message\":\"Not authenticated\"}");
    return;
}

String action = request.getParameter("action");

if ("printers".equals(action)) {
    // List available printers
    try {
        List<String> printers = POSPrinter.getAvailablePrinters();
        StringBuilder json = new StringBuilder();
        json.append("{\"success\":true,\"printers\":[");
        for (int i = 0; i < printers.size(); i++) {
            if (i > 0) json.append(",");
            String name = printers.get(i).replace("\\", "\\\\").replace("\"", "\\\"");
            json.append("\"").append(name).append("\"");
        }
        json.append("]}");
        out.print(json.toString());
    } catch (Exception e) {
        response.setStatus(500);
        out.print("{\"success\":false,\"message\":\"Error listing printers: " + e.getMessage().replace("\"", "'") + "\"}");
    }
    return;
}

if ("debug".equals(action)) {
    // Debug: show what config is loaded and which printer will be used
    response.setContentType("text/html; charset=UTF-8");
    try {
        Vector dbDetails = userBean.getCompanyDetails();
        int dbPrintType = 0;
        String dbPrinterName = "(not set)";
        if (dbDetails != null) {
            if (dbDetails.size() > 4 && dbDetails.elementAt(4) != null) dbPrintType = ((Integer)dbDetails.elementAt(4)).intValue();
            if (dbDetails.size() > 5 && dbDetails.elementAt(5) != null) dbPrinterName = dbDetails.elementAt(5).toString();
        }

        javax.print.PrintService[] allServices = javax.print.PrintServiceLookup.lookupPrintServices(null, null);
        StringBuilder sb = new StringBuilder();
        sb.append("<h2>directPrint.jsp Debug</h2><pre>");
        sb.append("DB print_type   : ").append(dbPrintType).append(" (1=Thermal, 2=A4)\n");
        sb.append("DB printer_name : [").append(dbPrinterName).append("]\n\n");
        sb.append("Windows printers found:\n");
        boolean matched = false;
        for (javax.print.PrintService svc : allServices) {
            String svcName = svc.getName();
            boolean match = svcName.toLowerCase().contains(dbPrinterName.toLowerCase());
            sb.append("  [").append(match ? "MATCH" : "     ").append("] ").append(svcName).append("\n");
            if (match) matched = true;
        }
        sb.append("\nResult: ");
        if (dbPrintType == 2) {
            sb.append("A4 mode -> will open print.jsp (browser popup)\n");
        } else if (dbPrinterName.equals("(not set)") || dbPrinterName.trim().isEmpty()) {
            sb.append("No printer_name set in DB -> will save TXT file\n");
        } else if (!matched) {
            sb.append("Printer name [").append(dbPrinterName).append("] NOT found in Windows -> will save TXT file\n");
            sb.append("FIX: printer_name in DB must match one of the Windows printer names above\n");
        } else {
            sb.append("Printer found! Should print directly to thermal printer.\n");
        }
        sb.append("</pre>");
        out.print(sb.toString());
    } catch (Exception e) {
        out.print("<pre>ERROR: " + e.getMessage() + "</pre>");
    }
    return;
}

// Print receipt
String billNo = request.getParameter("billNo");

if (billNo == null || billNo.trim().isEmpty()) {
    response.setStatus(400);
    out.print("{\"success\":false,\"message\":\"Missing bill number\"}");
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
    // If error fetching settings, use default thermal
    e.printStackTrace();
}

// If A4 format selected, return redirect instruction
if (printType == 2) {
    out.print("{\"success\":true,\"type\":\"a4\",\"billNo\":\"" + billNo.trim() + "\",\"message\":\"Opening A4 print preview\"}");
    return;
}

try {
    // Set application path for cloud deployment compatibility
    POSPrinter.setApplicationPath(application.getRealPath("/"));
    
    print.POSPrinter.PrintResult result = POSPrinter.printReceipt(billNo.trim());
    if (result.printed) {
        out.print("{\"success\":true,\"type\":\"printed\",\"message\":\"" + result.message.replace("\"", "'") + "\"}");
    } else if (result.txtSaved) {
        String safePath = result.txtPath.replace("\\", "/").replace("\"", "'");
        String safeBillNo = billNo.trim().replace("/", "-").replace("\\", "-").replace(" ", "_");
        out.print("{\"success\":true,\"type\":\"txt\",\"message\":\"" + result.message.replace("\\", "/").replace("\"", "'") + "\",\"txtFile\":\"Bill_" + safeBillNo + ".txt\",\"txtPath\":\"" + safePath + "\"}");
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