<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page language="java" import= "java.util.*"%>
<%@ page errorPage="" %>
<jsp:useBean id="prod" class="product.productBean" />
<%

// Session check
Integer userId = (Integer) session.getAttribute("userId");
if (userId == null) {
    response.sendRedirect(request.getContextPath() + "/index.jsp");
    return;
}
%>
<!DOCTYPE html>
<html lang="en">
<head> 
    <meta charset="UTF-8">
    <title>Expense Entry - Billing App</title>
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <!-- Bootstrap CSS -->
    <%@ include file="/assets/common/head.jsp" %>

</head>
<body>
    <%@ include file="/assets/navbar/navbar.jsp" %>
<%
    request.setAttribute("pageTitle",    "Expense Entry");
    request.setAttribute("pageSubtitle", "Add a new expense record");
    request.setAttribute("pageIcon",     "fa-solid fa-receipt");
%>
<jsp:include page="/assets/common/pageHeader.jsp" />

<div class="container-fluid mt-3 mst-page" style="max-width:900px;">
<%
String msg = request.getParameter("msg");
String type = request.getParameter("type");
%>
<% if (msg != null) { %>
<div class="alert alert-<%= (type != null ? type : "info") %> alert-dismissible fade show mb-3" role="alert">
  <%= msg %>
  <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Close"></button>
</div>
<% } %>
    <div class="card mst-card">
        <div class="mst-card-header">
            <h5 class="mb-0"><i class="fa-solid fa-receipt me-2"></i>Add Expense Entry</h5>
        </div>
        <div class="card-body p-4">
                <form action="<%=contextPath%>/expense/expenseEntry/saveExpenseEntry.jsp" method="post" onsubmit="return validateForm()">
                    
                    <div class="row mb-3">
                        <div class="col-md-6">
                            <label class="form-label fw-semibold">Expense Type</label>
                            <select name="expenseType" id="expenseType" class="form-select fg-inp" required>
                                <option value="">-- Select Expense Type --</option>
                                <%
                                try {
                                    Vector expTypes = prod.getExpenseTypeList();
                                    for (int i = 0; i < expTypes.size(); i++) {
                                        Vector expType = (Vector) expTypes.get(i);
                                        String typeName = expType.elementAt(0).toString();
                                        String typeId = expType.elementAt(1).toString();
                                %>
                                    <option value="<%=typeId%>"><%=typeName%></option>
                                <%
                                    }
                                } catch (Exception e) {
                                    out.println("<option value=''>Error loading expense types</option>");
                                }
                                %>
                            </select>
                        </div>
                        
                        <div class="col-md-6">
                            <label class="form-label fw-semibold">Amount</label>
                            <input type="number" step="0.01" name="amount" id="amount" class="form-control fg-inp" placeholder="0.00" required>
                        </div>
                    </div>
                    
                    <div class="mb-3">
                        <label class="form-label fw-semibold">Content</label>
                        <input type="text" name="content" id="content" class="form-control fg-inp" placeholder="Enter content" required>
                    </div>
                    
                    <div class="mb-3">
                        <label class="form-label fw-semibold">Description</label>
                        <textarea name="description" id="description" class="form-control fg-inp" rows="4" placeholder="Type anything you want to store here"></textarea>
                    </div>
                    
                    <div class="row mb-3">
                        <div class="col-md-6">
                            <label class="form-label fw-semibold">Date</label>
                            <input type="date" name="expenseDate" id="expenseDate" class="form-control fg-inp" required value="<%= new java.text.SimpleDateFormat("yyyy-MM-dd").format(new java.util.Date()) %>">
                        </div>
                        
                        <div class="col-md-6">
                            <label class="form-label fw-semibold">Time</label>
                            <input type="time" name="expenseTime" id="expenseTime" class="form-control fg-inp" required value="<%= new java.text.SimpleDateFormat("HH:mm").format(new java.util.Date()) %>">
                        </div>
                    </div>
                    
                    <div class="d-flex gap-2 justify-content-end mt-4">
                        <button type="reset" class="bb bb-outline">
                            <i class="fa-solid fa-rotate-left me-2"></i>Reset
                        </button>
                        <button type="submit" class="bb bb-primary">
                            <i class="fa-solid fa-floppy-disk me-2"></i>Save Expense
                        </button>
                    </div>
                        </button>
                    </div>
                </form>
            </div>
        </div>
    </div>

    <script>
        function validateForm() {
            const expenseType = document.getElementById('expenseType').value;
            const amount = document.getElementById('amount').value;
            const content = document.getElementById('content').value;
            const expenseDate = document.getElementById('expenseDate').value;
            const expenseTime = document.getElementById('expenseTime').value;
            
            if (!expenseType) {
                alert('Please select an expense type');
                return false;
            }
            
            if (!amount || parseFloat(amount) <= 0) {
                alert('Please enter a valid amount');
                return false;
            }
            
            if (!content.trim()) {
                alert('Please enter content');
                return false;
            }
            
            if (!expenseDate) {
                alert('Please select a date');
                return false;
            }
            
            if (!expenseTime) {
                alert('Please select a time');
                return false;
            }
            
            return true;
        }
    </script>

</body>
</html>
