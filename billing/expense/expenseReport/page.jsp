<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page language="java" import="java.util.*"%>
<%@ page import="java.text.SimpleDateFormat, java.util.Date, java.text.DecimalFormat" %>
<jsp:useBean id="prod" class="product.productBean" />
<%
// Session check
Integer userId = (Integer) session.getAttribute("userId");
if (userId == null) {
    response.sendRedirect(request.getContextPath() + "/index.jsp");
    return;
}

String today = new SimpleDateFormat("yyyy-MM-dd").format(new Date());

// Get filter parameters
String fromDate = request.getParameter("fromDate");
String toDate = request.getParameter("toDate");
String expenseTypeFilter = request.getParameter("expenseType");

// Set defaults
if (fromDate == null || fromDate.isEmpty()) {
    fromDate = today;
}
if (toDate == null || toDate.isEmpty()) {
    toDate = today;
}
if (expenseTypeFilter == null) {
    expenseTypeFilter = "0";
}

// Fetch expense data
Vector expenseData = null;
double totalAmount = 0.0;
DecimalFormat df = new DecimalFormat("#,##0.00");
String selectedExpenseTypeName = "All Types";

try {
    int expenseTypeId = Integer.parseInt(expenseTypeFilter);
    expenseData = prod.getExpenseReport(fromDate, toDate, expenseTypeId);
    
    // Get expense type name
    if (expenseTypeId != 0) {
        Vector expTypes = prod.getExpenseTypeList();
        for (int i = 0; i < expTypes.size(); i++) {
            Vector expType = (Vector) expTypes.get(i);
            int typeId = Integer.parseInt(expType.elementAt(1).toString());
            if (typeId == expenseTypeId) {
                selectedExpenseTypeName = expType.elementAt(0).toString();
                break;
            }
        }
    }
    
    // Debug output
    System.out.println("Expense Report Query - From: " + fromDate + ", To: " + toDate + ", Type: " + expenseTypeId);
    System.out.println("Records found: " + (expenseData != null ? expenseData.size() : 0));
    
    // Calculate total
    if (expenseData != null) {
        for (int i = 0; i < expenseData.size(); i++) {
            Vector row = (Vector) expenseData.get(i);
            if (row.size() > 4) {
                totalAmount += Double.parseDouble(row.get(4).toString());
            }
        }
    }
} catch (Exception e) {
    System.err.println("Error loading expense data: " + e.getMessage());
    e.printStackTrace();
    out.println("<!-- Error loading expense data: " + e.getMessage() + " -->");
}
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Expense Report - Billing App</title>
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <%@ include file="/assets/common/head.jsp" %>
    
    <style>
        .summary-card {
            background: var(--bill-bg);
            border: 1px solid #e2e8f0;
            border-radius: 6px;
            padding: 0.625rem 0.75rem;
            text-align: center;
        }
        .summary-value {
            font-size: 1.25rem;
            font-weight: 600;
            margin-bottom: 0.125rem;
            color: var(--bill-navy);
        }
        .summary-label {
            font-size: 0.75rem;
            color: var(--bill-muted);
            font-weight: 500;
        }
        .expense-badge {
            padding: 0.25rem 0.625rem;
            border-radius: 6px;
            font-weight: 500;
            font-size: 0.85rem;
            display: inline-block;
            background: var(--bill-bg);
            color: var(--bill-navy);
        }
        @media print {
            .print-hide { display: none !important; }
            body { background: white; }
        }
    </style>
</head>
<body>
    <%@ include file="/assets/navbar/navbar.jsp" %>
<%
    request.setAttribute("pageTitle",    "Expense Report");
    request.setAttribute("pageSubtitle", "View and filter expense entries");
    request.setAttribute("pageIcon",     "fa-solid fa-file-invoice");
%>
<jsp:include page="/assets/common/pageHeader.jsp" />

<div class="container-fluid mt-3 mst-page">
    
    <!-- Filter Section -->
    <div class="card mst-card print-hide mb-3">
        <div class="card-body p-3">
                <form method="get" class="row g-3">
                    <div class="col-md-3">
                        <label for="fromDate" class="form-label fw-semibold">From Date</label>
                        <input type="date" id="fromDate" name="fromDate" value="<%=fromDate%>" class="form-control fg-inp" required>
                    </div>

                    <div class="col-md-3">
                        <label for="toDate" class="form-label fw-semibold">To Date</label>
                        <input type="date" id="toDate" name="toDate" value="<%=toDate%>" class="form-control fg-inp" required>
                    </div>

                    <div class="col-md-4">
                        <label for="expenseType" class="form-label fw-semibold">Expense Type</label>
                        <select id="expenseType" name="expenseType" class="form-select fg-inp">
                            <option value="0" <%= expenseTypeFilter.equals("0") ? "selected" : "" %>>-- All Expense Types --</option>
                            <%
                            try {
                                Vector expTypes = prod.getExpenseTypeList();
                                for (int i = 0; i < expTypes.size(); i++) {
                                    Vector expType = (Vector) expTypes.get(i);
                                    String typeName = expType.elementAt(0).toString();
                                    String typeId = expType.elementAt(1).toString();
                                    String selected = expenseTypeFilter.equals(typeId) ? "selected" : "";
                            %>
                                <option value="<%=typeId%>" <%= selected %>><%=typeName%></option>
                            <%
                                }
                            } catch (Exception e) {
                                out.println("<option value='0'>Error loading expense types</option>");
                            }
                            %>
                        </select>
                    </div>

                    <div class="col-md-2 d-flex align-items-end">
                        <button type="submit" class="bb bb-primary w-100">
                            <i class="fa-solid fa-magnifying-glass me-2"></i>Generate
                        </button>
                    </div>
                </form>
            </div>
        </div>

        <!-- Summary Section -->
        <div class="card mst-card p-3 mb-3">
            <div class="row g-2">
                <div class="col-md-3">
                    <div class="summary-card">
                        <div class="summary-value"><%= expenseData != null ? expenseData.size() : 0 %></div>
                        <div class="summary-label">Total Entries</div>
                    </div>
                </div>
                <div class="col-md-3">
                    <div class="summary-card">
                        <div class="summary-value">₹ <%= df.format(totalAmount) %></div>
                        <div class="summary-label">Total Expense Amount</div>
                    </div>
                </div>
                <div class="col-md-3">
                    <div class="summary-card">
                        <div class="summary-value"><%= selectedExpenseTypeName %></div>
                        <div class="summary-label">Expense Type</div>
                    </div>
                </div>
                <div class="col-md-3">
                    <div class="summary-card">
                        <div class="summary-value"><%= new SimpleDateFormat("dd/MM/yy").format(new SimpleDateFormat("yyyy-MM-dd").parse(fromDate)) %> - <%= new SimpleDateFormat("dd/MM/yy").format(new SimpleDateFormat("yyyy-MM-dd").parse(toDate)) %></div>
                        <div class="summary-label">Report Period</div>
                    </div>
                </div>
            </div>
        </div>

        <!-- Data Table -->
        <div class="card mst-card">
            <div class="mst-card-header d-flex justify-content-between align-items-center print-hide">
                <h5 class="mb-0"><i class="fa-solid fa-table me-2"></i>Expense Details</h5>
                <button onclick="window.print()" class="bb bb-navy btn-sm">
                    <i class="fa-solid fa-print me-2"></i>Print Report
                </button>
            </div>
            
            <div class="table-responsive">
                <table class="table mst-table mb-0">
                    <thead>
                        <tr>
                            <th style="width: 5%;">#</th>
                            <th style="width: 12%;">Date</th>
                            <th style="width: 15%;">Expense Type</th>
                            <th style="width: 20%;">Content</th>
                            <th style="width: 30%;">Description</th>
                            <th style="width: 12%;" class="text-end">Amount</th>
                            <th style="width: 10%;">Entry By</th>
                        </tr>
                    </thead>
                    <tbody>
                        <%
                        if (expenseData != null && expenseData.size() > 0) {
                            for (int i = 0; i < expenseData.size(); i++) {
                                Vector row = (Vector) expenseData.get(i);
                                // Expected columns: exp_date_time, expense_type_name, content, description, amount, username
                                String expDateTime = row.get(0).toString();
                                String expenseTypeName = row.get(1).toString();
                                String content = row.get(2).toString();
                                String description = row.get(3) != null ? row.get(3).toString() : "";
                                double amount = Double.parseDouble(row.get(4).toString());
                                String username = row.get(5).toString();
                        %>
                        <tr>
                            <td class="text-muted fw-medium"><%=i+1%></td>
                            <td class="fw-medium">
                                <i class="fa-regular fa-calendar me-1" style="color:var(--bill-navy);"></i>
                                <%= new SimpleDateFormat("dd MMM yyyy HH:mm").format(new SimpleDateFormat("yyyy-MM-dd HH:mm:ss").parse(expDateTime)) %>
                            </td>
                            <td>
                                <span class="expense-badge">
                                    <%= expenseTypeName %>
                                </span>
                            </td>
                            <td class="fw-medium"><%=content%></td>
                            <td class="text-muted small"><%=description.isEmpty() ? "-" : description%></td>
                            <td class="text-end fw-semibold" style="color:var(--bill-red);">
                                ₹ <%= df.format(amount) %>
                            </td>
                            <td class="text-muted">
                                <i class="fa-solid fa-circle-user me-1"></i><%=username%>
                            </td>
                        </tr>
                        <%
                            }
                        } else {
                        %>
                        <tr>
                            <td colspan="7" class="text-center py-5 text-muted">
                                <i class="fa-solid fa-inbox fa-2x mb-2 d-block opacity-50"></i>
                                No expense entries found for the selected period.
                            </td>
                        </tr>
                        <%
                        }
                        %>
                    </tbody>
                    <% if (expenseData != null && expenseData.size() > 0) { %>
                    <tfoot class="table-light">
                        <tr>
                            <th colspan="5" class="text-end fw-semibold py-3">Grand Total:</th>
                            <th class="text-end fw-bold py-3" style="color:var(--bill-red);">
                                ₹ <%= df.format(totalAmount) %>
                            </th>
                            <th></th>
                        </tr>
                    </tfoot>
                    <% } %>
                </table>
            </div>
        </div>
    </div>

</body>
</html>
