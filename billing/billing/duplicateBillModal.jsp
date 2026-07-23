<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.*, javax.servlet.http.*" %>
<jsp:useBean id="bill" class="billing.billingBean" />
<%

Vector billList = bill.getBillsForPrint();
%>

<div
  class="modal fade"
  id="duplicateBillModal"
  tabindex="-1"
  aria-labelledby="duplicateBillModalLabel"
  aria-hidden="true"
>
  <div class="modal-dialog modal-lg modal-fullscreen-sm-down">
    <div class="modal-content">
      <div class="modal-header">
        <h5 class="modal-title" id="duplicateBillModalLabel">
          Duplicate Bill
        </h5>
        <button class="btn btn-primary btn-sm" onclick="printSelectedBill()" >
                  <i class="fa fa-print"></i> Print
        </button>
        <button
          type="button"
          class="btn-close"
          data-bs-dismiss="modal"
          aria-label="Close"
        ></button>
      </div>
        
      <div class="modal-body">
        <!-- Table inside modal -->
        <div class="table-responsive">
        <table class="table table-bordered table-sm align-middle">
          <thead class="table-light">
            <tr>
              <th>Bill No</th>
              <th>Name</th>
              <th>Total</th>
              <th>Paid</th>
              <th>Date</th>
              <th>Time</th>
              <!--th>Action</th-->
            </tr>
          </thead>
          <tbody>
            <%
            for (int i = 0; i < billList.size(); i++) {
                Vector row = (Vector) billList.get(i);
                
                
                String billId  = row.get(0).toString();
                String billNo  = row.get(1).toString();
                String total   = row.get(2).toString();
                String paid   = row.get(3).toString();
                String date   = row.get(4).toString();
                String time   = row.get(5).toString();
                String name   = row.get(6).toString();
            %>
                <tr>
              <td>
                <input
                type="radio"
                name="billSelect"
                value="<%=billNo%>"
                class="form-check-input"
                /><%=billNo%>
              </td>
              <td><%=name%></td>
              <td><%=total%></td>
              <td><%=paid%></td>
              <td><%=date%></td>
              <td><%=time%></td>
              <!--td>
                <button class="btn btn-primary btn-sm" onclick="printSelectedBill()">
                  <i class="fa fa-print"></i> Print
                </button>
              </td-->
            </tr>
            <%
            }
            %>
            
            <!-- More rows can be appended dynamically -->
          </tbody>
        </table>
        </div>
      </div>

      <div class="modal-footer">
        <button class="btn btn-primary btn-sm" onclick="printSelectedBill()">
                  <i class="fa fa-print"></i> Print
        </button>
        <button
          type="button"
          class="btn btn-secondary"
          data-bs-dismiss="modal"
        >
          Close
        </button>
      </div>
    </div>
  </div>
</div>
<script>
  const contextPathss = '<%=contextPaths%>';
  function printSelectedBill() {
  const selected = document.querySelector('input[name="billSelect"]:checked');
  if (!selected) {
    alert('Please select a bill first.');
    return;
  }
  const billNo = selected.value;

  // Direct print via ESC/POS (no browser dialog, no empty page)
  fetch(contextPathss + '/billing/directPrint.jsp?billNo=' + encodeURIComponent(billNo), {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    credentials: 'same-origin'
  })
  .then(response => response.json())
  .then(data => {
    if (data.success) {
      if (data.type === 'a4') {
        // A4 format selected in company settings - open print.jsp
        window.open('print.jsp?billNo=' + encodeURIComponent(data.billNo), '_blank');
        if (typeof showPrintToast === 'function') {
          showPrintToast('Opening A4 print preview', 'info');
        }
      } else if (data.type === 'printed') {
        if (typeof showPrintToast === 'function') {
          showPrintToast('Receipt printed successfully!', 'success');
        } else {
          alert('Receipt printed successfully!');
        }
      } else if (data.type === 'txt') {
        if (typeof showPrintToast === 'function') {
          showPrintToast('No printer found. Receipt saved as TXT file', 'info');
        }
        alert('Receipt saved to: ' + data.txtPath + '\n\nFile: ' + data.txtFile + '\n\nYou can open this file with Notepad to see how the receipt looks.');
      }
    } else {
      if (confirm('Direct print failed: ' + data.message + '\n\nOpen print preview instead?')) {
        window.open('thermalPrint.jsp?billNo=' + encodeURIComponent(billNo), 'ThermalPrintWindow', 'width=400,height=600');
      }
    }
  })
  .catch(error => {
    console.error('Direct print error:', error);
    if (confirm('Could not reach print server.\n\nOpen print preview instead?')) {
      window.open('thermalPrint.jsp?billNo=' + encodeURIComponent(billNo), 'ThermalPrintWindow', 'width=400,height=600');
    }
  });
}

// Reload modal content when shown to get fresh data
$('#duplicateBillModal').on('show.bs.modal', function (e) {
    // Check if we need to refresh (e.g., after saving a new bill)
    if (window.duplicateBillNeedsRefresh) {
        location.reload();
    }
});

</script>

