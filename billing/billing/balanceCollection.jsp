<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.*, javax.servlet.http.*" %>
<jsp:useBean id="bill" class="billing.billingBean" />
<%
Vector billList = bill.getDueBills();

double totalPendingBalance = 0.0;
int totalDueBills = 0;
for (int i = 0; i < billList.size(); i++) {
    Vector r = (Vector) billList.get(i);
    try {
        double cb = Double.parseDouble(r.get(10).toString());
        if (cb > 0) {
            totalPendingBalance += cb;
            totalDueBills++;
        }
    } catch (Exception ex) {}
}
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Billing - Billing App</title>
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <%@ include file="/assets/common/head.jsp" %>
</head>
<body>
    <jsp:include page="/assets/navbar/navbar.jsp" />
<%
    request.setAttribute("pageTitle",    "Credit Details");
    request.setAttribute("pageSubtitle", "Billing — Due Bills");
    request.setAttribute("pageIcon",     "fa-solid fa-file-invoice-dollar");
%>
<jsp:include page="/assets/common/pageHeader.jsp" />

<div class="container-fluid mt-3 mst-page">

  <!-- Total Pending Balance Card -->
  <div class="row mb-4 justify-content-center">
    <div class="col-12 col-md-5">
      <div style="
          background: linear-gradient(135deg, #dc2626 0%, #991b1b 100%);
          border-radius: 14px;
          padding: 28px 36px;
          display: flex;
          align-items: center;
          justify-content: space-between;
          box-shadow: 0 6px 24px rgba(220,38,38,.30);
          color: #fff;
      ">
        <div>
          <div style="font-size:12px;font-weight:700;letter-spacing:1.2px;text-transform:uppercase;opacity:.85;margin-bottom:6px;">
            Total Pending Balance
          </div>
          <div style="font-size:42px;font-weight:900;line-height:1;letter-spacing:-1px;">
            &#8377;<%= String.format("%,.2f", totalPendingBalance) %>
          </div>
          <div style="font-size:13px;margin-top:8px;opacity:.80;">
            <%= totalDueBills %> bill<%= totalDueBills != 1 ? "s" : "" %> with pending dues
          </div>
        </div>
        <i class="fa-solid fa-file-invoice-dollar" style="font-size:64px;opacity:.20;"></i>
      </div>
    </div>
  </div>

  <!-- Filter Section -->
  <div class="row mb-3">
    <div class="col-md-4">
      <div class="input-group">
        <span class="input-group-text"><i class="fas fa-user"></i></span>
        <input type="text" id="nameFilter" class="form-control fg-inp" placeholder="Filter by Name..." onkeyup="filterTable()">
      </div>
    </div>
    <div class="col-md-4">
      <div class="input-group">
        <span class="input-group-text"><i class="fas fa-phone"></i></span>
        <input type="text" id="phoneFilter" class="form-control fg-inp" placeholder="Filter by Phone Number..." onkeyup="filterTable()">
      </div>
    </div>
    <div class="col-md-4">
      <button class="bb bb-outline" onclick="clearFilters()">
        <i class="fa-solid fa-xmark me-1"></i>Clear Filters
      </button>
    </div>
  </div>

  <div class="table-responsive">
    <table id="billingTable" class="table mst-table">
      <thead>
        <tr>
          <th>S.No</th>
          <th>Bill No</th>
          <th>Name</th>
          <th>Phone Number</th>
          <th class="text-end">Total</th>
          <th class="text-end">Paid</th>
          <th class="text-end">Balance</th>
          <th class="text-end">Pending Balance</th>
          <th>Date</th>
          <th>Time</th>
          <th>Biller</th>
          <th>Action</th>
        </tr>
      </thead>
      <tbody>
        <%
            for (int i = 0; i < billList.size(); i++) {
                Vector row = (Vector) billList.get(i);
                
                
                String name  = row.get(0).toString();
                String phno  = row.get(1).toString();
                String payable   = row.get(2).toString();
                String paid   = row.get(3).toString();
                String Balance   = row.get(4).toString();
                String currentBalance   = row.get(10).toString();
                String date   = row.get(5).toString();
                String time   = row.get(6).toString();
                String uname   = row.get(7).toString();
                String billNo   = row.get(8).toString();
                int billId		= Integer.parseInt(row.elementAt(9).toString());

            %>
        <tr class="bill-row" data-name="<%=name.toLowerCase()%>" data-phone="<%=phno%>">
          <td><%=i+1%></td>
          <td><a href="#" onclick="loadBillDetails(<%=billId%>); return false;" class="inv-link"><%=billNo%></a></td>
          <td><%=name%></td>
          <td>
            <a href="#" onclick="sendToWhatsApp('<%=phno%>', '<%=name%>', '<%=billNo%>', '<%=payable%>', '<%=paid%>', '<%=currentBalance%>', '<%=date%>', <%=billId%>); return false;" class="text-success" title="Send details via WhatsApp">
              <i class="fab fa-whatsapp"></i> <%=phno%>
            </a>
          </td>
          <td class="text-end"><%=payable%></td>
          <td class="text-end"><%=paid%></td>
          <td class="text-end"><%=Balance%></td>
          <td class="text-end <%= (Double.parseDouble(currentBalance) > 0) ? "text-danger fw-bold" : "" %>"><%=currentBalance%></td>
          <td><%=date%></td>
          <td><%=time%></td>
          <td><%=uname%></td>
          <td class="text-center">
            <a href="<%=contextPath%>/billing/payBalance.jsp?billId=<%=billId%>" class="bb bb-outline">Pay Balance</a>
          </td>
        </tr>
        <%
    }
        %>
        
      </tbody>
    </table>
  </div>
</div>

<!-- Bill Details Modal -->
<div class="modal fade" id="billDetailModal" tabindex="-1" aria-labelledby="billDetailModalLabel" aria-hidden="true">
  <div class="modal-dialog modal-xl modal-dialog-scrollable">
    <div class="modal-content">
      <div class="modal-header mst-card-header">
        <h5 class="modal-title" id="billDetailModalLabel">Bill Details</h5>
        <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal" aria-label="Close"></button>
      </div>
      <div class="modal-body" id="billDetailContent">
        <div class="text-center py-5">
          <div class="spinner-border text-primary" role="status">
            <span class="visually-hidden">Loading...</span>
          </div>
        </div>
      </div>
      <div class="modal-footer">
        <button type="button" class="bb bb-outline" data-bs-dismiss="modal">Close</button>
      </div>
    </div>
  </div>
</div>

<script>
const contextPath = '<%=contextPath%>';
function sendToWhatsApp(phone, name, billNo, payable, paid, currentBalance, date, billId) {
  // Remove any non-numeric characters from phone
  var cleanPhone = phone.replace(/\D/g, '');
  
  // Format detailed message for WhatsApp
  var message = `*JASXBILL - Bill Details*\n`;
  message += `${'='.repeat(15)}\n\n`;
  message += ` *Customer:* ${name}\n`;
  message += ` *Bill No:* ${billNo}\n`;
  message += ` *Date:* ${date}\n\n`;
  message += `${'='.repeat(15)}\n`;
  message += `*PAYMENT SUMMARY*\n`;
  message += `${'='.repeat(15)}\n\n`;
  message += ` *Total Amount:* ₹${payable}\n`;
  //message += `✅ *Paid:* ₹${paid}\n`;
  message += ` *Pending Balance:* ₹${currentBalance}\n\n`;
  message += `${'='.repeat(15)}\n\n`;
  
  if (parseFloat(currentBalance) > 0) {
    message += ` Please clear the pending balance at your earliest convenience.\n\n`;
  } else {
    message += ` Payment completed. Thank you!\n\n`;
  }
  
  message += `Thank you for your business! \n`;
  message += `For any queries, please contact us.`;
  
  // Encode the message for URL
  var encodedMessage = encodeURIComponent(message);
  
  // Open WhatsApp with pre-filled message
  var whatsappUrl = `https://wa.me/${cleanPhone}?text=${encodedMessage}`;
  window.open(whatsappUrl, '_blank');
}

function loadBillDetails(billId) {
  // Show the modal
  var modal = new bootstrap.Modal(document.getElementById('billDetailModal'));
  modal.show();
  
  // Show loading spinner
  document.getElementById('billDetailContent').innerHTML = `
    <div class="text-center py-5">
      <div class="spinner-border text-primary" role="status">
        <span class="visually-hidden">Loading...</span>
      </div>
    </div>
  `;
  
  // Fetch bill details
  fetch(contextPath + '/billing/balanceDetailModal.jsp?billId=' + billId)
    .then(response => response.text())
    .then(data => {
      document.getElementById('billDetailContent').innerHTML = data;
    })
    .catch(error => {
      document.getElementById('billDetailContent').innerHTML = `
        <div class="alert alert-danger" role="alert">
          <i class="fas fa-exclamation-triangle"></i> Error loading bill details. Please try again.
        </div>
      `;
      console.error('Error:', error);
    });
}

function filterTable() {
  var nameFilter = document.getElementById('nameFilter').value.toLowerCase();
  var phoneFilter = document.getElementById('phoneFilter').value;
  var table = document.getElementById('billingTable');
  var rows = table.getElementsByClassName('bill-row');
  
  for (var i = 0; i < rows.length; i++) {
    var row = rows[i];
    var name = row.getAttribute('data-name');
    var phone = row.getAttribute('data-phone');
    
    var nameMatch = name.includes(nameFilter);
    var phoneMatch = phone.includes(phoneFilter);
    
    if (nameMatch && phoneMatch) {
      row.style.display = '';
    } else {
      row.style.display = 'none';
    }
  }
  
  updateSerialNumbers();
}

function clearFilters() {
  document.getElementById('nameFilter').value = '';
  document.getElementById('phoneFilter').value = '';
  filterTable();
}

function updateSerialNumbers() {
  var table = document.getElementById('billingTable');
  var rows = table.getElementsByClassName('bill-row');
  var visibleCount = 1;
  
  for (var i = 0; i < rows.length; i++) {
    var row = rows[i];
    if (row.style.display !== 'none') {
      row.cells[0].textContent = visibleCount++;
    }
  }
}
</script>

<script src="billing.js"></script>
</body>
</html>
    

