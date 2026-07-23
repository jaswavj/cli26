<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page language="java" import= "java.util.*"%>
<%@ page import="java.text.SimpleDateFormat, java.util.Date" %>
<jsp:useBean id="bill" class="billing.billingBean" />
<%
    int billId = Integer.parseInt(request.getParameter("billId"));
    Vector details = bill.getBillDetails(billId);
    double total = 0;
double prodDiscount = 0;
double extraDiscount = 0;
double payable = 0;
double paid = 0;
double cash = 0;
double bank = 0;
double balance = 0;
double currentBalance = 0;

Vector billInfo = bill.getExtraDisc(billId);
if (billInfo != null && !billInfo.isEmpty()) {
    total        = Double.parseDouble(billInfo.elementAt(0).toString());
    prodDiscount = Double.parseDouble(billInfo.elementAt(1).toString());
    extraDiscount= Double.parseDouble(billInfo.elementAt(2).toString());
    payable      = Double.parseDouble(billInfo.elementAt(3).toString());
    paid         = Double.parseDouble(billInfo.elementAt(4).toString());
    cash         = Double.parseDouble(billInfo.elementAt(5).toString());
    bank         = Double.parseDouble(billInfo.elementAt(6).toString());
    balance      = Double.parseDouble(billInfo.elementAt(7).toString());
    currentBalance      = Double.parseDouble(billInfo.elementAt(8).toString());
} else {
    out.print("<p style='color:red'>No bill info found for Bill No: " + billId + "</p>");
}

%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Bill Details</title>
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <!-- Bootstrap CSS -->
<%@ include file="/assets/common/head.jsp" %>
    
 
</head>
<body onload="document.form.opregInput.focus();">

<!--%@ include file="../menu/reportMenu.jsp" %-->
    <%@ include file="/assets/navbar/navbar.jsp" %>
    <!-- Top Navbar -->


    <div class="container mt-4 ">
        <h4>Bill Details (Bill No: <%= billId %>)</h4>
    <table class="table table-bordered table-sm mt-3">
        <thead class="table-dark">
            <tr>
                <th>S.No</th>
                <th>Product</th>
                <th>Qty</th>
                <th>Price</th>
                <th>Discount</th>
                <th>Total</th>
            </tr>
        </thead>
        <tbody>
        <%
            for (int i = 0; i < details.size(); i++) {
                Vector row = (Vector) details.elementAt(i);
        %>
            <tr>
                <td><%= i+1 %></td>
                <td><%= row.elementAt(3) %></td> <!-- product_name -->
                <td><%= row.elementAt(4) %></td> <!-- qty -->
                <td><%= row.elementAt(5) %></td> <!-- price -->
                <td><%= row.elementAt(6) %></td> <!-- discount -->
                <td><%= row.elementAt(7) %></td> <!-- total -->
            </tr>
        <%
            }
        %>
        </tbody>
    </table>
    <div class="row mt-4">
        <div class="col-md-6 offset-md-6">
            <table class="table table-bordered">
                <tr>
                    <th>Total</th>
                    <td><%= total %></td>
                </tr>
                <tr>
                    <th>Product Discount</th>
                    <td><%= prodDiscount %></td>
                </tr>
                <tr>
                    <th>Extra Discount</th>
                    <td><%= extraDiscount %></td>
                </tr>
                <tr>
                    <th>Payable</th>
                    <td><%= payable %></td>
                </tr>
                <tr class="table-success">
                    <th>Paid</th>
                    <td><%= paid %></td>
                </tr>
                <tr class="table-success">
                    <th>Cash Paid</th>
                    <td><%= cash %></td>
                </tr>
                <tr class="table-success">
                    <th>Bank Paid</th>
                    <td><%= bank %></td>
                </tr>
                <tr class="table-danger">
                    <th>Balance</th>
                    <td><%= balance %></td>
                </tr>
                <tr class="table-danger">
                    <th>Current Balance</th>
                    <td><%= currentBalance %></td>
                </tr>
            </table>
        </div>
    </div>
</div>
    <!-- Bootstrap JS -->

</body>
</html>
