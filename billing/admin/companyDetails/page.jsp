<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.Vector" %>
<jsp:useBean id="userBean" class="user.userBean" scope="page"/>

<!DOCTYPE html>
<html>
<head>
    <title>Company Details</title>
    <%@ include file="/assets/common/head.jsp" %>
</head>
<body>
<%
    String msg = request.getParameter("msg");
    String type = request.getParameter("type");

    // Fetch existing company details
    String shopName = "";
    String address = "";
    String gstin = "";
    int printType = 1; // Default: Thermal
    String printerName = "";
    String bankDetails = "";
    String barcodePrinter = "";

    try {
        Vector details = userBean.getCompanyDetails();
        if (details != null && details.size() > 0) {
            // details: [id, shop_name, address, gstin, print_type, printer_name, bank_details, barcode_printer]
            shopName = details.elementAt(1) != null ? (String)details.elementAt(1) : "";
            address = details.elementAt(2) != null ? (String)details.elementAt(2) : "";
            gstin = details.elementAt(3) != null ? (String)details.elementAt(3) : "";
            if (details.size() > 4) {
                Object ptObj = details.elementAt(4);
                printType = (ptObj != null) ? ((Integer)ptObj).intValue() : 1;
            }
            if (details.size() > 5) {
                printerName = details.elementAt(5) != null ? (String)details.elementAt(5) : "";
            }
            if (details.size() > 6) {
                bankDetails = details.elementAt(6) != null ? (String)details.elementAt(6) : "";
            }
            if (details.size() > 7) {
                barcodePrinter = details.elementAt(7) != null ? (String)details.elementAt(7) : "";
            }
        }
    } catch (Exception e) {
        e.printStackTrace();
    }
%>
    <%@ include file="/assets/navbar/navbar.jsp" %>
<%
    request.setAttribute("pageTitle",    "Company Details");
    request.setAttribute("pageSubtitle", "Admin — Shop Settings");
    request.setAttribute("pageIcon",     "fa-solid fa-building");
%>
<jsp:include page="/assets/common/pageHeader.jsp" />

<% if (msg != null) { %>
<div class="alert alert-<%= (type != null ? type : "info") %> alert-dismissible fade show mx-3" role="alert">
    <%= msg %>
    <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Close"></button>
</div>
<% } %>

<div class="container-fluid mt-3 mst-page">
    <form action="<%= request.getContextPath() %>/admin/companyDetails/save.jsp" method="post" class="card mst-card p-4" style="max-width: 700px; margin: 0 auto;">
                <div class="mb-3">
                    <label for="shopName" class="form-label">Trade Name <span class="text-danger">*</span></label>
                    <input type="text" name="shopName" id="shopName" class="form-control fg-inp" 
                           value="<%= shopName %>" required placeholder="Enter trade name">
                </div>

                <div class="mb-3">
                    <label for="address" class="form-label">Address & Phone Number <span class="text-danger">*</span></label>
                    <textarea name="address" id="address" class="form-control fg-inp" rows="4" 
                              required placeholder="Enter address and phone number"><%= address %></textarea>
                    <small class="form-text text-muted">Enter complete address with phone number</small>
                </div>

                <div class="mb-3">
                    <label for="gstin" class="form-label">GSTIN No</label>
                    <input type="text" name="gstin" id="gstin" class="form-control fg-inp" 
                           value="<%= gstin %>" placeholder="Enter GSTIN number" maxlength="15">
                    <small class="form-text text-muted">15 character GSTIN (optional)</small>
                </div>

                <div class="mb-3">
                    <label for="bankDetails" class="form-label">Bank Details</label>
                    <textarea name="bankDetails" id="bankDetails" class="form-control fg-inp" rows="4" 
                              placeholder="Enter bank details (Account Name, Account No, IFSC Code, Bank Name, Branch)"><%= bankDetails %></textarea>
                    <small class="form-text text-muted">Will be displayed at the bottom of printed invoices</small>
                </div>

                <div class="mb-3">
                    <label for="printType" class="form-label">Print Format <span class="text-danger">*</span></label>
                    <select name="printType" id="printType" class="form-select fg-inp" required onchange="togglePrinterField()">
                        <option value="1" <%= (printType == 1) ? "selected" : "" %>>Thermal Printer (58mm/80mm)</option>
                        <option value="2" <%= (printType == 2) ? "selected" : "" %>>A4 Paper</option>
                    </select>
                    <small class="form-text text-muted">Select the default print format for receipts</small>
                </div>

                <div class="mb-3" id="printerNameBox" style="<%= (printType == 1) ? "" : "display:none;" %>">
                    <label for="printerName" class="form-label">Printer Name <span class="text-danger">*</span></label>
                    <input type="text" name="printerName" id="printerName" class="form-control fg-inp" 
                           value="<%= printerName %>" placeholder="Enter printer sharing name">
                    <div class="alert alert-info mt-2 p-2" style="font-size: 0.9em;">
                        <strong>📌 How to setup and find your printer sharing name:</strong>
                        <ol class="mb-0 mt-1" style="padding-left: 1.2em;">
                            <li><strong>Step 1:</strong> Control Panel → Devices and Printers → Right-click printer → Printer Properties</li>
                            <li><strong>Step 2:</strong> Go to <strong>Sharing</strong> tab</li>
                            <li><strong>Step 3:</strong> If not enabled, check "Share this printer" and set a share name</li>
                            <li><strong>Step 4:</strong> Use that share name here (e.g., <code>POS-80</code>, <code>XP-58</code>)</li>
                        </ol>
                        <div class="mt-2">
                            <strong>For Network Printer:</strong> Use format <code>\\\\ComputerName\\ShareName</code>
                        </div>
                    </div>
                </div>

                <div class="mb-3">
                    <label for="barcodePrinter" class="form-label">Barcode Printer Name</label>
                    <input type="text" name="barcodePrinter" id="barcodePrinter" class="form-control fg-inp" 
                           value="<%= barcodePrinter %>" placeholder="Enter barcode/label printer name (optional)">
                    <small class="form-text text-muted">Exact printer name for barcode labels (e.g., "SNBC TVSE LP 46 NEO BPLE"). Leave empty for auto-detection.</small>
                </div>

                <div class="d-flex justify-content-between">
                    <button type="submit" class="bb bb-primary">
                        <i class="fa-solid fa-floppy-disk me-1"></i> Save Details
                    </button>
                    <a href="${pageContext.request.contextPath}/dashboard.jsp" class="bb bb-outline">
                        <i class="fa-solid fa-house me-1"></i> Home
                    </a>
                </div>
            </form>
</div>

    <script>
        // GSTIN validation (optional field)
        document.getElementById('gstin').addEventListener('input', function(e) {
            let val = e.target.value.toUpperCase();
            e.target.value = val;
            
            if (val.length > 0 && val.length !== 15) {
                e.target.classList.add('is-invalid');
            } else {
                e.target.classList.remove('is-invalid');
            }
        });

        // Toggle printer name field based on print type selection
        function togglePrinterField() {
            const printType = document.getElementById('printType').value;
            const printerBox = document.getElementById('printerNameBox');
            const printerInput = document.getElementById('printerName');
            
            if (printType === '1') {
                // Thermal printer selected - show printer name field
                printerBox.style.display = '';
                printerInput.required = true;
            } else {
                // A4 selected - hide printer name field
                printerBox.style.display = 'none';
                printerInput.required = false;
                printerInput.value = ''; // Clear the value
            }
        }
        
        // Initialize on page load
        document.addEventListener('DOMContentLoaded', function() {
            togglePrinterField();
        });
    </script>
</body>
</html>
