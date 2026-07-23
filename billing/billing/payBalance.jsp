<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.*, javax.servlet.http.*" %>
<jsp:useBean id="bill" class="billing.billingBean" />
<%


int billId = Integer.parseInt(request.getParameter("billId"));
Vector billDetails = bill.getBillAmount(billId);


       double total = Double.parseDouble(billDetails.get(0).toString());
       double balance = Double.parseDouble(billDetails.get(2).toString());
              double paid = total - balance;


%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Pay Balance - Billing App</title>
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <%@ include file="/assets/common/head.jsp" %>
</head>
<body>
    <%@ include file="/assets/navbar/navbar.jsp" %>
<%
    request.setAttribute("pageTitle",    "Pay Balance");
    request.setAttribute("pageSubtitle", "Billing — Credit Payment");
    request.setAttribute("pageIcon",     "fa-solid fa-money-bill-wave");
%>
<jsp:include page="/assets/common/pageHeader.jsp" />

<div class="container-fluid mt-3 mst-page">

        <form id="payForm" action="<%= request.getContextPath() %>/billing/saveDuePayment.jsp" method="post" class="row g-3">
            <input type="hidden" name="billId" value="<%=billId%>">

            <!-- Totals -->
            <div class="col-md-4">
                <label class="form-label">Total</label>
                <input type="text" class="form-control fg-inp" name="total" id="total"
                       value="<%=total%>" readonly>
            </div>

            <div class="col-md-4">
                <label class="form-label">Paid</label>
                <input type="text" class="form-control fg-inp" name="paid" id="paid"
                       value="<%=paid%>" readonly>
            </div>

            <div class="col-md-4">
                <label class="form-label">Balance</label>
                <input type="text" class="form-control fg-inp" name="balance" id="balance"
                       value="<%=balance%>" readonly>
            </div>

            <!-- Payment Mode -->
            <div class="col-md-4">
                <label class="form-label">Payment Mode</label>
                <select class="form-select fg-inp" id="mode" name="mode">
                    <option value="1">Cash</option>
                    <option value="2">Bank</option>
                </select>
            </div>

            <!-- Bank Options -->
            <div class="col-md-4">
                <label class="form-label">Bank Options</label>
                <select class="form-select fg-inp" id="bankOption" name="bankOption" disabled>
                    <option value="0">--Select--</option>
                    <option value="1">UPI</option>
                    <option value="2">Debit Card</option>
                    <option value="3">Credit Card</option>
                    <option value="4">Net Banking</option>
                    <option value="5">Wallet</option>
                    <option value="6">Cheque</option>
                </select>
            </div>
            <input type="hidden" name="bankOption" value="0">

            <!-- Pay Now -->
            <div class="col-md-4">
                <label class="form-label">Amount to Pay</label>
                <input type="number" class="form-control fg-inp" name="payNow" id="payNow"
                       min="0" step="0.001" placeholder="Enter amount" required autofocus>
            </div>

            

            <div class="col-12">
                <button type="submit" class="bb bb-primary">Submit Payment</button>
            </div>
        </form>

        <div class="card mst-card mt-4">
            <div class="card-header mst-card-header">
                <h6>Due Paid List</h6>
            </div>
            <div class="card-body p-0">
                <div class="table-responsive">
                <table class="table mst-table mb-0">
                    <thead>
                        <tr>
                            <th>#</th>
                            <th>Name</th>
                            <th>Balance</th>
                            <th>Paid</th>
                            <th>Final Balance</th>
                            <th>Mode</th>
                            <th>Bank Option</th>
                            <th>Date</th>
                            <th>Time</th>
                            <th>Biller</th>
                        </tr>
                    </thead>
                    <tbody>

                        <%
                            
                            Vector duePaidList = bill.getDuePaidList(billId);
                            for (int i = 0; i < duePaidList.size(); i++) {
                                Vector vec1 = (Vector) duePaidList.get(i); // inner vector (row)
                                String customerName =vec1.elementAt(0).toString();
                                double balanceAmount = Double.parseDouble(vec1.elementAt(1).toString());
                                double paidAmount = Double.parseDouble(vec1.elementAt(2).toString());
                                double finalBalance = Double.parseDouble(vec1.elementAt(3).toString());
                                String mode = vec1.elementAt(4).toString();
                                String bankOption = vec1.elementAt(5).toString();
                                String date = vec1.elementAt(6).toString();
                                String time = vec1.elementAt(7).toString();
                                String biller = vec1.elementAt(8).toString();


                        %>
                        <tr>
                            <td><%=i+1%></td>
                            <td><%=customerName%></td>
                            <td><%=balanceAmount%></td>
                            <td><%=paidAmount%></td> 
                            <td><%=finalBalance%></td>
                            <td><%=mode%></td>
                            <td><%=bankOption%></td>
                            <td><%=date%></td>
                            <td><%=time%></td>
                            <td><%=biller%></td>   
                        </tr>
                        <%
                    }
                        %>
                        <%-- Dynamic rows will come here --%>
                    </tbody>
                </table>
                </div>
            </div>
        </div>
</div>
<script>
    const payNowInput = document.getElementById("payNow");
    const balanceInput = document.getElementById("balance");
    const modeSelect = document.getElementById("mode");
    const bankOption = document.getElementById("bankOption");

    // Validate amount: cannot exceed balance
    payNowInput.addEventListener("input", function () {
        const entered = parseFloat(this.value) || 0;
        const balance = parseFloat(balanceInput.value) || 0;
        if (entered > balance) {
            alert("Entered amount cannot be greater than the balance!");
            this.value = "";
            this.focus();
        }
    });

    // Enable/disable bank options
    modeSelect.addEventListener("change", function () {
        if (this.value === "2") {
            bankOption.removeAttribute("disabled");
        } else {
            bankOption.value = "";
            bankOption.setAttribute("disabled", "disabled");
        }
    });
</script>

</body>
</html>
