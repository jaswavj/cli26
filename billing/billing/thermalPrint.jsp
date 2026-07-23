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

// Fetch company details
Vector companyDetails = userBean.getCompanyDetails();
String companyName = "";
String companyAddress = "";
String companyGSTIN = "";
String companyPhone = "";

if (companyDetails != null && companyDetails.size() >= 4) {
    companyName = companyDetails.get(1) != null ? companyDetails.get(1).toString() : "";
    companyAddress = companyDetails.get(2) != null ? companyDetails.get(2).toString() : "";
    companyGSTIN = companyDetails.get(3) != null ? companyDetails.get(3).toString() : "";
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
double totalQtyD = 0;

// Map to store GST-wise totals
Map<Integer, Double> gstWiseTaxable = new HashMap<Integer, Double>();
Map<Integer, Double> gstWiseCGST = new HashMap<Integer, Double>();
Map<Integer, Double> gstWiseSGST = new HashMap<Integer, Double>();
Map<Integer, Double> gstWiseIGST = new HashMap<Integer, Double>();

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
    
    totalQtyD += qty;
    totalAmount += itemTotal;
    totalDiscount += itemDisc;
    totalTaxableAmount += taxableAmount;
    totalGSTAmount += gstAmount;
    totalCGST += cgst;
    totalSGST += sgst;
    
    // Accumulate GST-wise totals
    if (!gstWiseTaxable.containsKey(gstPer)) {
        gstWiseTaxable.put(gstPer, 0.0);
        gstWiseCGST.put(gstPer, 0.0);
        gstWiseSGST.put(gstPer, 0.0);
    }
    gstWiseTaxable.put(gstPer, gstWiseTaxable.get(gstPer) + taxableAmount);
    gstWiseCGST.put(gstPer, gstWiseCGST.get(gstPer) + cgst);
    gstWiseSGST.put(gstPer, gstWiseSGST.get(gstPer) + sgst);
}

double subTotalBeforeDiscount = totalAmount + totalDiscount;
finalPaid = totalAmount - extradisc;
%>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Thermal Print - <%= billNo %></title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        
        body {
            font-family: 'Courier New', monospace;
            width: 80mm;
            padding: 5mm;
            background: #fff;
            font-size: 10px;
        }
        
        @page {
            size: 80mm auto;
            margin: 0;
        }
        
        @media print {
            html, body {
                width: 80mm;
                height: auto;
                margin: 0;
                padding: 0;
                overflow: hidden;
            }
            .thermal-receipt {
                page-break-after: avoid;
                page-break-inside: avoid;
            }
            .no-print {
                display: none !important;
            }
        }
        
        .thermal-receipt {
            width: 100%;
        }
        
        .center {
            text-align: center;
        }
        
        .left {
            text-align: left;
        }
        
        .right {
            text-align: right;
        }
        
        .bold {
            font-weight: bold;
        }
        
        .large {
            font-size: 14px;
        }
        
        .medium {
            font-size: 11px;
        }
        
        .small {
            font-size: 9px;
        }
        
        .divider {
            border-top: 1px dashed #000;
            margin: 3px 0;
        }
        
        .double-divider {
            border-top: 2px solid #000;
            margin: 3px 0;
        }
        
        .header {
            margin-bottom: 5px;
        }
        
        .company-name {
            font-size: 16px;
            font-weight: bold;
            margin-bottom: 2px;
        }
        
        .info-row {
            display: flex;
            justify-content: space-between;
            margin: 1px 0;
        }
        
        .items-table {
            width: 100%;
            margin: 5px 0;
        }
        
        .item-row {
            margin: 2px 0;
            border-bottom: 1px dotted #999;
            padding-bottom: 2px;
        }
        
        .item-name {
            font-weight: bold;
        }
        
        .item-details {
            display: flex;
            justify-content: space-between;
            font-size: 9px;
        }
        
        .totals-section {
            margin-top: 5px;
        }
        
        .total-row {
            display: flex;
            justify-content: space-between;
            margin: 2px 0;
        }
        
        .grand-total {
            font-size: 13px;
            font-weight: bold;
            border-top: 2px solid #000;
            border-bottom: 2px solid #000;
            padding: 3px 0;
            margin: 3px 0;
        }
        
        .footer {
            margin-top: 10px;
            text-align: center;
            font-size: 9px;
        }
        
        .gst-section {
            margin: 5px 0;
            font-size: 9px;
        }
    </style>
</head>
<body>
<div class="thermal-receipt">
    <!-- Header -->
    <div class="header center">
        <div class="company-name"><%= companyName %></div>
        <div class="small"><%= companyAddress %></div>
        <% if (!companyGSTIN.isEmpty()) { %>
        <div class="small">GSTIN: <%= companyGSTIN %></div>
        <% } %>
    </div>
    
    <div class="double-divider"></div>
    
    <!-- Bill Info -->
    <div class="info-row bold">
        <span>Bill No: <%= billNo %></span>
        <span><%= billDate %></span>
    </div>
    
    <div class="divider"></div>
    
    <!-- Customer Info -->
    <div class="left small">
        <div>Customer: <%= customerName %></div>
        <% if (!customerPhone.equals("-")) { %>
        <div>Phone: <%= customerPhone %></div>
        <% } %>
        <% if (!customerGSTIN.equals("-")) { %>
        <div>GSTIN: <%= customerGSTIN %></div>
        <% } %>
    </div>
    
    <div class="divider"></div>
    
    <!-- Items Header -->
    <div class="info-row bold small">
        <span style="width: 50%">ITEM</span>
        <span style="width: 15%; text-align: center">QTY</span>
        <span style="width: 17%; text-align: right">RATE</span>
        <span style="width: 18%; text-align: right">AMT</span>
    </div>
    
    <div class="divider"></div>
    
    <!-- Items -->
    <div class="items-table">
        <%
        for(Vector<Object> prod : billDetails){
            String itemName = prod.get(0).toString();
            double qty = Double.parseDouble(prod.get(1).toString());
            double itemPrice = Double.parseDouble(prod.get(2).toString());
            double itemDisc = Double.parseDouble(prod.get(3).toString());
            double itemTotal = Double.parseDouble(prod.get(4).toString());
            int gstPer = Integer.parseInt(prod.get(5).toString());
        %>
        <div class="item-row">
            <div class="item-name small"><%= itemName %></div>
            <div class="info-row small">
                <span style="width: 50%"><%= gstPer > 0 ? "GST " + gstPer + "%" : "" %></span>
                <span style="width: 15%; text-align: center"><%= prod.get(1) %></span>
                <span style="width: 17%; text-align: right"><%= df.format(itemPrice) %></span>
                <span style="width: 18%; text-align: right"><%= df.format(itemTotal) %></span>
            </div>
            <% if (itemDisc > 0) { %>
            <div class="small" style="text-align: right;">Disc: -<%= df.format(itemDisc) %></div>
            <% } %>
        </div>
        <%
        }
        %>
    </div>
    
    <div class="double-divider"></div>
    
    <!-- Totals -->
    <div class="totals-section">
        <div class="total-row">
            <span>Items:</span>
            <span><%= totalQtyD %></span>
        </div>
        
        <div class="divider"></div>
        
        <div class="total-row">
            <span>Sub Total:</span>
            <span>₹ <%= df.format(subTotalBeforeDiscount) %></span>
        </div>
        
        <% if (totalDiscount > 0) { %>
        <div class="total-row">
            <span>Item Discount:</span>
            <span>- ₹ <%= df.format(totalDiscount) %></span>
        </div>
        <% } %>
        
        <% if (extradisc > 0) { %>
        <div class="total-row">
            <span>Extra Discount:</span>
            <span>- ₹ <%= df.format(extradisc) %></span>
        </div>
        <% } %>
        
        <div class="total-row grand-total">
            <span>TOTAL:</span>
            <span>₹ <%= df.format(finalPaid) %></span>
        </div>
        
        <div class="total-row">
            <span>Paid:</span>
            <span>₹ <%= df.format(paid) %></span>
        </div>
        
        <% if (balance != 0) { %>
        <div class="total-row bold">
            <span><%= balance > 0 ? "Balance Due:" : "Change:" %></span>
            <span>₹ <%= df.format(Math.abs(balance)) %></span>
        </div>
        <% } %>
    </div>
    
    <% if (totalGSTAmount > 0) { %>
    <div class="double-divider"></div>
    
    <!-- GST Summary -->
    <div class="gst-section">
        <div class="bold small">GST Summary:</div>
        <%
        List<Integer> gstRates = new ArrayList<Integer>(gstWiseTaxable.keySet());
        Collections.sort(gstRates);
        for(Integer rate : gstRates) {
            if(rate > 0) {
        %>
        <div class="info-row small">
            <span>GST <%= rate %>%:</span>
            <span>Taxable: ₹<%= df.format(gstWiseTaxable.get(rate)) %></span>
        </div>
        <div class="info-row small" style="margin-left: 15px;">
            <span>CGST:</span>
            <span>₹<%= df.format(gstWiseCGST.get(rate)) %></span>
        </div>
        <div class="info-row small" style="margin-left: 15px;">
            <span>SGST:</span>
            <span>₹<%= df.format(gstWiseSGST.get(rate)) %></span>
        </div>
        <%
            }
        }
        %>
        <div class="divider"></div>
        <div class="info-row small bold">
            <span>Total GST:</span>
            <span>₹ <%= df.format(totalGSTAmount) %></span>
        </div>
    </div>
    
    <div class="double-divider"></div>
    <% } %>
    
    <!-- Footer -->
    <div class="footer">
        <div class="bold"><%= numPaid.toUpperCase() %></div>
        <div style="margin-top: 5px;">Thank You! Visit Again</div>
    </div>
    
    <!-- Print Button -->
    <div class="no-print" style="text-align: center; margin-top: 10px;">
        <button onclick="window.print()" style="padding: 10px 20px; font-size: 12px; cursor: pointer;">
            Print Receipt
        </button>
    </div>
</div>

<script>
    // Auto-print on load (optional)
    // window.onload = function() {
    //     setTimeout(function() {
    //         window.print();
    //     }, 500);
    // }
</script>
</body>
</html>
