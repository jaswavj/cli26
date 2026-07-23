<%@ page language="java" contentType="text/html; charset=UTF-8"%>
<%@ page language="java" import="java.util.*"%>
<%@ page language="java" import="java.text.DecimalFormat"%>

<jsp:useBean id="bill" class="billing.billingBean" />
<jsp:useBean id="userBean" class="user.userBean" scope="page"/>
<%
String billNo = request.getParameter("billNo");
if(billNo == null || billNo.trim().isEmpty()){
    out.print("Error: Missing bill number");
    return;
}

double extradisc = bill.getExtraDisc(billNo);
String cusName=bill.getCusName(billNo);
String cusNumber=bill.getCusNumber(billNo);

// Get customer details from customers table
Vector customerDetails = bill.getCustomerDetailsByBillNo(billNo);
String customerName = "-";
String customerPhone = "-";
String customerAddress = "-";
String customerGSTIN = "-";

if (customerDetails != null && customerDetails.size() >= 4) {
    customerName = customerDetails.get(0) != null ? customerDetails.get(0).toString() : cusName;
    customerPhone = customerDetails.get(1) != null ? customerDetails.get(1).toString() : cusNumber;
    customerAddress = customerDetails.get(2) != null ? customerDetails.get(2).toString() : "-";
    customerGSTIN = customerDetails.get(3) != null ? customerDetails.get(3).toString() : "-";
} else {
    // Fallback to old fields if customer not found
    customerName = cusName;
    customerPhone = cusNumber;
}


double paid = bill.getPaidTotal(billNo);
String numPaid=bill.getNumPaid(paid);
double balance = bill.getbalanceTotal(billNo);
String billDate = bill.getBillDate(billNo);
Vector<Vector<Object>> billDetails = bill.getBillDetailsUsingNo(billNo);

// Get LR details
Vector lrDetails = bill.getLRDetails(billNo);
String lrNo = "";
String lrDate = "";
String lrName = "";

if (lrDetails != null && lrDetails.size() >= 3) {
    lrNo = lrDetails.get(0) != null ? lrDetails.get(0).toString() : "";
    lrDate = lrDetails.get(1) != null ? lrDetails.get(1).toString() : "";
    lrName = lrDetails.get(2) != null ? lrDetails.get(2).toString() : "";
}

// Fetch company details
Vector companyDetails = userBean.getCompanyDetails();
String companyName = "";
String companyAddress = "";
String companyGSTIN = "";
String companyBankDetails = "";

if (companyDetails != null && companyDetails.size() >= 4) {
    companyName = companyDetails.get(1) != null ? companyDetails.get(1).toString() : "";
    companyAddress = companyDetails.get(2) != null ? companyDetails.get(2).toString() : "";
    companyGSTIN = companyDetails.get(3) != null ? companyDetails.get(3).toString() : "";
    if (companyDetails.size() > 6) {
        companyBankDetails = companyDetails.get(6) != null ? companyDetails.get(6).toString() : "";
    }
}

DecimalFormat df = new DecimalFormat("0.00");

// GST Calculation variables
double totalAmount = 0;
double totalDiscount = 0;
double finalPaid = 0;
double totalItemAmount = 0;
double totalTaxableAmount = 0;
double totalCGST = 0;
double totalSGST = 0;
double totalIGST = 0;
double totalGSTAmount = 0;
double totalQty = 0;
double subTotalBeforeDiscount = 0;

// Map to store GST-wise totals
Map<Integer, Double> gstWiseTaxable = new HashMap<Integer, Double>();
Map<Integer, Double> gstWiseCGST = new HashMap<Integer, Double>();
Map<Integer, Double> gstWiseSGST = new HashMap<Integer, Double>();

for(Vector<Object> prod : billDetails){
    double itemTotal = Double.parseDouble(prod.get(4).toString());
    double itemDisc = Double.parseDouble(prod.get(3).toString());
    double itemPrice = Double.parseDouble(prod.get(2).toString());
    int gstPer = Integer.parseInt(prod.get(5).toString());
    double qty = Double.parseDouble(prod.get(1).toString());
    
    // Calculate taxable amount (amount before GST)
    double taxableAmount = itemTotal / (1 + (gstPer / 100.0));
    double gstAmount = itemTotal - taxableAmount;
    double cgst = gstAmount / 2;
    double sgst = gstAmount / 2;
    
    totalAmount += itemTotal;
    totalDiscount += itemDisc;
    totalItemAmount += itemPrice;
    totalTaxableAmount += taxableAmount;
    totalCGST += cgst;
    totalSGST += sgst;
    totalGSTAmount += gstAmount;
    totalQty += qty;
    
    // Group by GST rate
    gstWiseTaxable.put(gstPer, gstWiseTaxable.getOrDefault(gstPer, 0.0) + taxableAmount);
    gstWiseCGST.put(gstPer, gstWiseCGST.getOrDefault(gstPer, 0.0) + cgst);
    gstWiseSGST.put(gstPer, gstWiseSGST.getOrDefault(gstPer, 0.0) + sgst);
}

// Calculate subtotal before discount (totalAmount is after item discounts, so add them back)
subTotalBeforeDiscount = totalAmount + totalDiscount;
    
finalPaid = totalAmount - extradisc;

// Payment Summary data
Vector paymentInfo = new Vector();
Vector duePayments = new Vector();
String initialMode = "-";
String initialMethod = "-";
double initialPaid = 0;
double initialBalance = 0;
double currentPaidDisplay = paid;
double currentBalanceDisplay = balance;
try {
    paymentInfo = bill.getBillPaymentInfo(billNo);
    if (paymentInfo != null && paymentInfo.size() > 0) {
        int billIdInt = (Integer) paymentInfo.get(0);
        int pMode = (Integer) paymentInfo.get(5);
        int pType = (Integer) paymentInfo.get(6);
        double cash = (Double) paymentInfo.get(7);
        double bank = (Double) paymentInfo.get(8);
        initialPaid = cash + bank;
        double payable = (Double) paymentInfo.get(4);
        initialBalance = payable - initialPaid;
        if (initialBalance < 0) initialBalance = 0;
        if (pMode == 1) initialMode = "Cash";
        else if (pMode == 2) initialMode = "Bank";
        else if (pMode == 3) initialMode = "Cash & Bank";
        if (pType == 1) initialMethod = "UPI";
        else if (pType == 2) initialMethod = "Debit Card";
        else if (pType == 3) initialMethod = "Credit Card";
        else if (pType == 4) initialMethod = "NEFT";
        else if (pType == 5) initialMethod = "Wallet";
        else initialMethod = "-";
        duePayments = bill.getDuePaidList(billIdInt);
        double currentBalance = bill.getBillCurrentBalance(billIdInt);
        currentBalanceDisplay = currentBalance;
        currentPaidDisplay = finalPaid - currentBalance;
        if (currentPaidDisplay < 0) currentPaidDisplay = 0;
    }
} catch (Exception e) { /* ignore — payment summary will be empty */ }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Tax Invoice</title>
    <style>
        @page { size: A4; margin: 5mm; }
        body {
            font-family: Arial, sans-serif;
            font-size: 11px;
            margin: 0;
            padding: 5px;
            color: #000;
        }
        .container {
            width: calc(100% - 20px);
            border: 2px solid #2c3e50;
            margin: 0 auto;
            box-shadow: 0 4px 12px rgba(0,0,0,0.1);
            background: white;
        }
        .header-title {
            text-align: center;
            font-weight: bold;
            font-size: 16px;
            margin-bottom: 8px;
            color: #2c3e50;
            text-transform: uppercase;
            letter-spacing: 2px;
        }
        
        /* Grid Layout Helpers */
        .row { display: flex; width: 100%; }
        .col-50 { width: 50%; }
        .col-40 { width: 40%; }
        .col-60 { width: 60%; }
        
        .border-bottom { border-bottom: 1px solid #000; }
        .border-right { border-right: 1px solid #000; }
        .border-top { border-top: 1px solid #000; }
        
        .p-5 { padding: 5px; }
        .text-right { text-align: right; }
        .text-center { text-align: center; }
        .font-bold { font-weight: bold; }
        
        /* Header Section */
        .company-header {
            display: flex;
            border-bottom: 2px solid #2c3e50;
            background: #f8f9fa;
            padding: 8px;
            align-items: center;
        }
        /*.logo-area {
            width: 150px;
            height: 80px;
            border-radius: 8px;
            display: flex;
            
            
        }*/

        .logo-area img {
            max-width: 200px;
            max-height: 100px;
            object-fit: contain;
            margin-right: 20px;
        }
        .logo-area1 img {
            max-width: 150px;
            max-height: 80px;
            object-fit: contain;
            margin-right: 20px;
        }
        .company-details {
            flex: 1;
            color: #000;
            font-size: 12px;
            line-height: 1.6;
        }
        .company-name {
            font-size: 22px;
            font-weight: bold;
            text-transform: uppercase;
            margin-bottom: 5px;
            letter-spacing: 1px;
            color: #000;
        }
        .company-details div {
            margin: 3px 0;
        }
        
        /* Section Headers */
        .purple-header {
            background: #e9ecef;
            color: #000;
            padding: 6px 10px;
            font-weight: bold;
            border-bottom: 1px solid #2c3e50;
            border-right: 1px solid #2c3e50;
            font-size: 11px;
            letter-spacing: 0.5px;
        }
        
        /* Bill To & Invoice Details */
        .bill-info-row {
            display: flex;
            border-bottom: 2px solid #2c3e50;
        }
        .bill-to-box {
            width: 50%;
            border-right: 2px solid #2c3e50;
        }
        .invoice-details-box {
            width: 50%;
        }
        .info-content {
            padding: 10px;
            min-height: 50px;
            font-size: 11px;
            line-height: 1.6;
        }
        
        /* Main Table */
        .items-table {
            width: 100%;
            border-collapse: collapse;
        }
        .items-table th {
            background-color: #e9ecef;
            color: #000;
            border-left: 1px solid #000;
            border-right: 1px solid #000;
            border-top: 1px solid #000;
            border-bottom: 1px solid #000;
            padding: 4px 2px;
            font-size: 10px;
            text-align: center;
            font-weight: bold;
        }
        .items-table th:first-child {
            border-left: 1px solid #000;
        }
        .items-table th:last-child {
            border-right: 1px solid #000;
        }
        .items-table td {
            border-left: 1px solid #000;
            border-right: 1px solid #000;
            border-top: none;
            border-bottom: none;
            padding: 3px 4px;
            font-size: 11px;
            vertical-align: middle;
        }
        .items-table tbody {
            display: table-row-group;
            min-height: 200px;
            height: 200px;
        }
        .items-table tbody tr:first-child td {
            border-top: 1px solid #000;
        }
        .empty-filler-row td {
            border-bottom: none !important;
            height: 25px;
        }
        
        /* Total Row */
        .total-row {
            font-weight: bold;
            background-color: transparent;
        }
        .total-row td {
            border-top: 1px solid #000 !important;
            border-bottom: 1px solid #000 !important;
        }
        
        /* Tax & Amounts Section */
        .tax-amounts-row {
            display: flex;
            border-bottom: 1px solid #2c3e50;
        }
        .tax-box {
            width: 50%;
            border-right: 1px solid #2c3e50;
        }
        .amounts-box {
            width: 50%;
        }
        
        .tax-row {
            display: flex;
            justify-content: space-between;
            padding: 2px 5px;
            border-bottom: 1px solid #ccc;
        }
        .tax-row:last-child { border-bottom: none; }
        
        .amount-row {
            display: flex;
            justify-content: space-between;
            padding: 6px 10px;
            border-bottom: 1px solid #e0e0e0;
            font-size: 11px;
        }
        .amount-row.total {
            font-weight: bold;
            border-bottom: none;
            font-size: 13px;
            background: #e8ebf0;
            padding: 8px 10px;
        }

        /* Payment Summary */
        .payment-summary-section {
            border-top: 1px solid #2c3e50;
            border-bottom: 1px solid #2c3e50;
        }
        .payment-summary-table {
            width: 100%;
            border-collapse: collapse;
            font-size: 11px;
        }
        .payment-summary-table th {
            background-color: #e9ecef;
            color: #000;
            border: 1px solid #2c3e50;
            padding: 4px 8px;
            font-weight: bold;
            text-align: left;
        }
        .payment-summary-table th:first-child {
            font-size: 11px;
            letter-spacing: 0.5px;
        }
        .payment-summary-table td {
            border: 1px solid #ccc;
            padding: 3px 8px;
            vertical-align: middle;
        }
        .payment-summary-table .text-right { text-align: right; }
        
        /* Footer Info */
        .footer-row {
            display: flex;
            border-bottom: 1px solid #2c3e50;
        }
        .words-box {
            width: 50%;
            border-right: 1px solid #2c3e50;
        }
        .rightBorder {
            border-right: 1px solid #2c3e50;
        }
        .words-boxWord {
            width: 100%;
            
        }
        .desc-box {
            width: 50%;
        }
        .footer-content {
            padding: 5px;
            text-align: center;
            min-height: 20px;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 11px;
            font-weight: 600;
        }
        
        
        /* Terms & Signature */
        .terms-sign-row {
            display: flex;
        }
        .terms-box {
            width: 50%;
            border-right: 1px solid #2c3e50;
            font-size: 9px;
        }
        .sign-box {
            width: 50%;
            padding: 8px;
            text-align: right;
            display: flex;
            flex-direction: column;
            justify-content: space-between;
            min-height: 60px;
        }
        .sign-box .text-center {
            font-weight: 600;
            color: #2c3e50;
            padding-top: 10px;
            display: inline-block;
            width: 200px;
            margin-left: auto;
        }
        
        ul.terms-list {
            padding-left: 15px;
            margin: 5px 0;
        }
        ul.terms-list li {
            margin-bottom: 2px;
        }
        
        /* Bank Details with QR Code */
        .bank-qr-container {
            display: flex;
            align-items: flex-start;
            padding: 5px;
        }
        .bank-details-text {
            flex: 1;
            line-height: 1.6;
        }
        .qr-code-box {
            margin-left: auto;
            padding-left: 15px;
        }
        .qr-code-box img {
            width: 100px;
            height: 100px;
            border: 2px solid #5b21b6;
            border-radius: 8px;
            padding: 3px;
        }
        
        /* Print/Cancel Buttons */
        .print-controls {
            position: fixed;
            top: 10px;
            right: 10px;
            z-index: 1000;
            display: flex;
            gap: 10px;
        }
        .btn {
            padding: 10px 20px;
            font-size: 14px;
            font-weight: bold;
            border: none;
            border-radius: 5px;
            cursor: pointer;
        }
        .btn-print {
            background-color: #4CAF50;
            color: white;
        }
        .btn-print:hover {
            background-color: #45a049;
        }
        .btn-cancel {
            background-color: #f44336;
            color: white;
        }
        .btn-cancel:hover {
            background-color: #da190b;
        }
        
        @media print {
            .print-controls {
                display: none !important;
            }
        }
    </style>
    <script>
        window.onload = function() {
            // Direct print on page load
            window.print();
        };
        
        // Close window after print dialog is closed (either printed or cancelled)
        window.onafterprint = function() {
            window.close();
        };
        
        function printInvoice() {
            window.print();
        }
        
        function cancelPrint() {
            window.close();
        }
    </script>
</head>
<body>

<!-- Print/Cancel Controls -->
<div class="print-controls">
    <button class="btn btn-print" onclick="printInvoice()">🖨️ Print</button>
    <button class="btn btn-cancel" onclick="cancelPrint()">❌ Cancel</button>
</div>

<div class="header-title">Tax Invoice</div>

<div class="container">
    <!-- Header -->
    <div class="company-header">
        <div class="logo-area">
            <img src="logo.png" alt="Company Logo" >
            
        </div>
        
        <div class="company-details">
            <% if (!companyName.isEmpty()) { %>
                <div class="company-name"><%= companyName %></div>
            <% } %>
            <% if (!companyAddress.isEmpty()) { %>
                <% 
                // Split address by newlines and display each line
                String[] addressLines = companyAddress.split("\\r?\\n");
                for (String line : addressLines) {
                    if (line != null && !line.trim().isEmpty()) {
                %>
                    <div><%= line.trim() %></div>
                <% 
                    }
                } 
                %>
            <% } %>
            <% if (!companyGSTIN.isEmpty()) { %>
                <div>GSTIN: <%= companyGSTIN %></div>
            <% } %>
        </div>
    </div>

    <!-- Bill To & Invoice Details -->
    <div class="bill-info-row">
        <div class="bill-to-box">
            <div class="purple-header">Bill To</div>
            <div class="info-content">
                <div class="font-bold"><%= customerName %></div>
                <% if(customerPhone != null && !customerPhone.equals("-") && !customerPhone.trim().isEmpty()) { %>
                <div>Ph: <%= customerPhone %></div>
                <% } %>
                <% if(customerAddress != null && !customerAddress.equals("-") && !customerAddress.trim().isEmpty()) { %>
                <div><%= customerAddress %></div>
                <% } %>
                <% if(customerGSTIN != null && !customerGSTIN.equals("-") && !customerGSTIN.trim().isEmpty()) { %>
                <div>GSTIN: <%= customerGSTIN %></div>
                <% } %>
            </div>
        </div>
        <div class="invoice-details-box">
            <div class="purple-header text-right">Invoice Details</div>
            <div class="info-content text-right">
                <div>Invoice No.: <%= billNo %></div>
                <div>Date: <%= billDate %></div>
                <div>Place of Supply: Tamil Nadu</div>
                <% if (lrNo != null && !lrNo.trim().isEmpty()) { %>
                <div>LR No.: <%= lrNo %></div>
                <% } %>
                <% if (lrDate != null && !lrDate.trim().isEmpty()) { %>
                <div>LR Date: <%= lrDate %></div>
                <% } %>
                <% if (lrName != null && !lrName.trim().isEmpty()) { %>
                <div>LR Name: <%= lrName %></div>
                <% } %>
            </div>
        </div>
    </div>

    <!-- Items Table -->
    <table class="items-table">
        <thead>
            <tr>
                <th style="width: 5%;">S.No</th>
                <th style="width: 30%;">Item name</th>
                <th style="width: 8%;">HSN/SAC</th>
                <th style="width: 10%;">price/Unit</th>
                <th style="width: 5%;">Qty</th>
                <th style="width: 8%;">Taxable</th>
                <th style="width: 10%;">CGST</th>
                <th style="width: 10%;">SGST</th>
                <th style="width: 14%;">Amount</th>
            </tr>
        </thead>
        <tbody>
            <%
            int count = 1;
            for(Vector<Object> prod : billDetails){
                double itemTotal = Double.parseDouble(prod.get(4).toString());
                double itemPrice = Double.parseDouble(prod.get(2).toString());
                int gstPer = Integer.parseInt(prod.get(5).toString());
                double qty = Double.parseDouble(prod.get(1).toString());
                
                String category = "";
                if(prod.size() > 6 && prod.get(6) != null){
                    category = prod.get(6).toString();
                }
                String productName = prod.get(0).toString();
                String displayName = (category.isEmpty()) ? productName : category + " - " + productName;
                
                String hsnCode = "";
                if(prod.size() > 7 && prod.get(7) != null){
                    hsnCode = prod.get(7).toString();
                }
                
                String unitName = "";
                if(prod.size() > 8 && prod.get(8) != null){
                    unitName = prod.get(8).toString();
                }
                
                double taxableAmount = itemTotal / (1 + (gstPer / 100.0));
                double gstAmount = itemTotal - taxableAmount;
                double cgst = gstAmount / 2;
                double sgst = gstAmount / 2;
            %>
            <tr class="item-row">
                <td class="text-center" style="width: 5%;"><%= count++ %></td>
                <td style="width: 30%;">
                    <div class="font-bold"><%= displayName %></div>
                </td>
                <td class="text-center" style="width: 8%;"><%= hsnCode %></td>
                <td class="text-right" style="width: 10%;"><%= df.format(itemPrice) %></td>
                <td class="text-center" style="width: 5%;"><%= qty %><% if(unitName != null && !unitName.trim().isEmpty()) { %> <%= unitName %><% } %></td>
                <td class="text-right" style="width: 8%;"><%= df.format(taxableAmount) %></td>
                <td class="text-right" style="width: 10%;"><%= df.format(cgst) %></td>
                <td class="text-right" style="width: 10%;"><%= df.format(sgst) %></td>
                <td class="text-right" style="width: 14%;"><%= df.format(itemTotal) %></td>
            </tr>
            <% } %>
            
            <!-- Add empty filler rows to maintain fixed height -->
            <% 
            int minRows = 10; // Minimum rows to display
            int actualRows = billDetails.size();
            int emptyRowsNeeded = Math.max(0, minRows - actualRows);
            for(int i = 0; i < emptyRowsNeeded; i++) { 
            %>
            <tr class="empty-filler-row">
                <td class="text-center" style="width: 5%; height: 25px;">&nbsp;</td>
                <td style="width: 30%;">&nbsp;</td>
                <td class="text-center" style="width: 8%;">&nbsp;</td>
                <td class="text-right" style="width: 10%;">&nbsp;</td>
                <td class="text-center" style="width: 5%;">&nbsp;</td>
                <td class="text-right" style="width: 10%;">&nbsp;</td>
                <td class="text-right" style="width: 10%;">&nbsp;</td>
                <td class="text-right" style="width: 10%;">&nbsp;</td>
                <td class="text-right" style="width: 11%;">&nbsp;</td>
            </tr>
            <% } %>
        </tbody>
        <tfoot>
            <tr class="total-row">
                <td colspan="4" class="text-right" style="width: 55%;">Total</td>
                <td class="text-center" style="width: 8%;"><%= totalQty %></td>
                <td class="text-right" style="width: 12%;"> <%= df.format(totalTaxableAmount) %></td>
                <td class="text-right" style="width: 8%;"> <%= df.format(totalCGST) %></td>
                <td class="text-right" style="width: 8%;"> <%= df.format(totalSGST) %></td>
                <td class="text-right" style="width: 9%;"> <%= df.format(totalAmount) %></td>
            </tr>
        </tfoot>
    </table>

    <!-- Tax & Amounts -->
    <div class="tax-amounts-row">
        <div class="tax-box">
            <div class="tax-row border-bottom">
                <div>Tax details</div>
                <div>
                    <% 
                    for(Integer rate : gstWiseTaxable.keySet()) {
                        out.print(rate + ".0%");
                    }
                    %>
                </div>
            </div>
            <div class="tax-row">
                <div>CGST</div>
                <div>₹ <%= df.format(totalCGST) %></div>
            </div>
            <div class="tax-row">
                <div>SGST</div>
                <div>₹ <%= df.format(totalSGST) %></div>
            </div>
            <div class="tax-row">
                <div>IGST</div>
                <div>₹ <%= df.format(totalIGST) %></div>
            </div>
        </div>
        <div class="amounts-box">
            <div class="purple-header">Amounts</div>
            <div class="amount-row bg-light-purple">
                <div>Sub Total</div>
                <div>₹ <%= df.format(subTotalBeforeDiscount) %></div>
            </div>
            <% if (totalDiscount > 0) { %>
            <div class="amount-row">
                <div>Item Discount</div>
                <div>- ₹ <%= df.format(totalDiscount) %></div>
            </div>
            <% } %>
            <% if (extradisc > 0) { %>
            <div class="amount-row">
                <div>Extra Discount</div>
                <div>- ₹ <%= df.format(extradisc) %></div>
            </div>
            <% } %>
            <div class="amount-row total">
                <div>Total</div>
                <div>₹ <%= df.format(finalPaid) %></div>
            </div>
            <div class="amount-row">
                <div>Paid</div>
                <div>₹ <%= df.format(currentPaidDisplay) %></div>
            </div>
            <div class="amount-row">
                <div>Balance</div>
                <div>₹ <%= df.format(currentBalanceDisplay) %></div>
            </div>
        </div>
    </div>

    <!-- Payment Summary -->
    <div class="payment-summary-section">
        <table class="payment-summary-table">
            <thead>
                <tr>
                    <th colspan="5" class="purple-header" style="border:none;">Payment Summary</th>
                </tr>
                <tr>
                    <th>Date</th>
                    <th>Mode</th>
                    <th>Method</th>
                    <th class="text-right">Paid (&#8377;)</th>
                    <th class="text-right">Balance (&#8377;)</th>
                </tr>
            </thead>
            <tbody>
                <% if (paymentInfo != null && paymentInfo.size() > 0) { %>
                <tr>
                    <td><%= billDate %></td>
                    <td><%= initialMode %></td>
                    <td><%= initialMethod %></td>
                    <td class="text-right"><%= df.format(initialPaid) %></td>
                    <td class="text-right"><%= df.format(initialBalance) %></td>
                </tr>
                <% } %>
                <% if (duePayments != null) {
                    for (int di = 0; di < duePayments.size(); di++) {
                        Vector dueRow = (Vector) duePayments.get(di);
                        String dueDate    = dueRow.get(6) != null ? dueRow.get(6).toString() : "-";
                        String dueMode    = dueRow.get(4) != null ? dueRow.get(4).toString() : "-";
                        String dueMethod  = dueRow.get(5) != null ? dueRow.get(5).toString() : "-";
                        double duePaid    = dueRow.get(2) != null ? Double.parseDouble(dueRow.get(2).toString()) : 0;
                        double dueFinalBal = dueRow.get(3) != null ? Double.parseDouble(dueRow.get(3).toString()) : 0;
                %>
                <tr>
                    <td><%= dueDate %></td>
                    <td><%= dueMode %></td>
                    <td><%= dueMethod %></td>
                    <td class="text-right"><%= df.format(duePaid) %></td>
                    <td class="text-right"><%= df.format(dueFinalBal) %></td>
                </tr>
                <% }} %>
            </tbody>
        </table>
    </div>

    <!-- Words & Description -->
    <div class="footer-row">
        <div class="words-boxWord">
            <div class="footer-content">
                Amount In Words : <%= numPaid %> 
            </div>
        </div>
        
    </div>
    <div class="footer-row">
        
        <div class="desc-box">
            <div class="purple-header">Terms & Conditions</div>
            <div  style="text-align: left; align-items: flex-start;" class="rightBorder">
                Your Terms & Conditions Here.<br><br><br><br><br><br><br><br><br><br>
            </div>
        </div>
        <div class="words-box">
            
            <% if (companyBankDetails != null && !companyBankDetails.trim().isEmpty()) { %>
            <div class="purple-header">Bank Details for Payment</div>
            <div class="footer-content" style="text-align: left; align-items: flex-start; justify-content: flex-start; padding: 0;">
                <div class="bank-qr-container">
                    <div class="bank-details-text">
                    <% 
                    // Split bank details by newlines and display each line
                    String[] bankLines = companyBankDetails.split("\\r?\\n");
                    for (String line : bankLines) {
                        if (line != null && !line.trim().isEmpty()) {
                    %>
                        <div><%= line.trim() %></div>
                    <% 
                        }
                    } 
                    %>
                    </div>
                    <div class="qr-code-box">
                        <img src="qrcode.jpeg" alt="Payment QR Code" onerror="this.style.display='none'">
                    </div>
                </div>
            </div>
            <% } %>          
        </div>
    </div>



</div>
<div style="
    display: flex;
    align-items: center;
    justify-content: flex-end;
    gap: 8px;
    margin: 3px 0 0 0;
    padding: 4px 6px;
    border-top: 1px solid rgba(11,122,68,0.2);
    opacity: 0.55;
">
    <span style="font-family: Arial, sans-serif; font-size: 8.5px; color: #1e5a3c; letter-spacing: 0.4px; font-weight: 600;">
        Powered by <strong style="font-size: 9px; letter-spacing: 0.8px;">JASXBILL</strong>
        <span style="margin: 0 4px; color: #999;">&mdash;</span>
        <span style="font-weight: 400; color: #444;">Smart Billing Software</span>
        <span style="margin: 0 5px; color: #bbb;">&bull;</span>
        <span style="color: #333;">8667214152</span>
    </span>
</div>
</body>
</html>
