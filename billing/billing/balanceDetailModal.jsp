<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page language="java" import= "java.util.*"%>
<%@ page import="java.text.SimpleDateFormat, java.util.Date" %>
<jsp:useBean id="bill" class="billing.billingBean" />
<jsp:useBean id="user" class="user.userBean" />
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
    
    String head3 = user.getHead3();

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

<div class="container-fluid p-0">
    <h5 class="mb-3">Bill No: <%= billId %></h5>
    
    <div class="table-responsive">
        <table class="table mst-table table-sm">
            <thead>
                <tr>
                    <th>S.No</th>
                    <th><%=head3%></th>
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
                    <td><%= row.elementAt(3) %></td>
                    <td><%= row.elementAt(4) %></td>
                    <td><%= row.elementAt(5) %></td>
                    <td><%= row.elementAt(6) %></td>
                    <td><%= row.elementAt(7) %></td>
                </tr>
            <%
                }
            %>
            </tbody>
        </table>
    </div>
    
    <div class="row mt-3">
        <div class="col-md-8 offset-md-2">
            <table class="table mst-table table-sm">
                <tr>
                    <th>Total</th>
                    <td><%= total %></td>
                </tr>
                <tr>
                    <th><%=head3%> Discount</th>
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
