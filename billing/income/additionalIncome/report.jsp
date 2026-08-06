<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.*, java.math.BigDecimal, java.text.SimpleDateFormat, java.text.DecimalFormat" %>
<jsp:useBean id="currency" class="currency.currencyBean" />
<%
Integer userId = (Integer) session.getAttribute("userId");
if (userId == null) {
    response.sendRedirect(request.getContextPath() + "/index.jsp");
    return;
}

String today = new SimpleDateFormat("yyyy-MM-dd").format(new Date());
String fromDate = request.getParameter("fromDate");
String toDate = request.getParameter("toDate");
if (fromDate == null || fromDate.isEmpty()) fromDate = today;
if (toDate == null || toDate.isEmpty()) toDate = today;

Vector reportData = currency.getAdditionalIncomeReport(fromDate, toDate);
BigDecimal totalAmount = BigDecimal.ZERO;
DecimalFormat df = new DecimalFormat("#,##0.00");
SimpleDateFormat displayDt = new SimpleDateFormat("dd MMM yyyy hh:mm a");
SimpleDateFormat periodFmt = new SimpleDateFormat("dd/MM/yy");
String periodLabel = periodFmt.format(new SimpleDateFormat("yyyy-MM-dd").parse(fromDate))
    + " - " + periodFmt.format(new SimpleDateFormat("yyyy-MM-dd").parse(toDate));

if (reportData != null) {
    for (int i = 0; i < reportData.size(); i++) {
        Vector row = (Vector) reportData.get(i);
        totalAmount = totalAmount.add((BigDecimal) row.elementAt(3));
    }
}
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Additional Income Report</title>
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <%@ include file="/assets/common/head.jsp" %>
    <style>
        .summary-card {
            background: #f8fafc;
            border: 1px solid #e2e8f0;
            border-radius: 8px;
            padding: 12px;
            text-align: center;
        }
        .summary-value { font-size: 1.2rem; font-weight: 700; color: var(--bill-navy, #1e3a5f); }
        .summary-label { font-size: 0.8rem; color: #64748b; }
        #printTable .print-meta { margin-bottom: 16px; }
        #printTable .print-meta h2 { font-size: 1.25rem; margin: 0 0 4px; color: var(--bill-navy, #1e3a5f); }
        #printTable .print-meta p { margin: 0 0 4px; color: #64748b; font-size: 0.9rem; }
        #printTable .print-summary { margin-bottom: 14px; font-size: 0.92rem; }
        #printTable .print-summary span { margin-right: 18px; font-weight: 600; }
    </style>
</head>
<body>
    <%@ include file="/assets/navbar/navbar.jsp" %>
<%
    request.setAttribute("pageTitle", "Additional Income Report");
    request.setAttribute("pageSubtitle", "Income entries by date range");
    request.setAttribute("pageIcon", "fa-solid fa-chart-line");
%>
<div class="print-hide">
    <jsp:include page="/assets/common/pageHeader.jsp" />
</div>

<div class="container-fluid mt-3 mst-page print-hide">
    <div class="card mst-card mb-3">
        <div class="card-body p-3">
            <form method="get" class="row g-2 align-items-end">
                <div class="col-md-3">
                    <label class="form-label fw-semibold">From Date</label>
                    <input type="date" name="fromDate" class="form-control fg-inp" value="<%= fromDate %>" required>
                </div>
                <div class="col-md-3">
                    <label class="form-label fw-semibold">To Date</label>
                    <input type="date" name="toDate" class="form-control fg-inp" value="<%= toDate %>" required>
                </div>
                <div class="col-md-3">
                    <button type="submit" class="bb bb-primary w-100">
                        <i class="fa-solid fa-filter me-1"></i>Generate
                    </button>
                </div>
                <div class="col-md-3">
                    <button type="button" class="bb bb-outline w-100" onclick="printIncomeReport()">
                        <i class="fa-solid fa-print me-1"></i>Print
                    </button>
                </div>
            </form>
        </div>
    </div>
</div>

<div class="container-fluid mst-page">
    <div id="printTable">
        <div class="print-meta">
            <h2>Additional Income Report</h2>
            <p>Period: <%= periodLabel %></p>
            <div class="print-summary">
                <span>Total Entries: <%= reportData != null ? reportData.size() : 0 %></span>
                <span>Total Income: <%= df.format(totalAmount) %></span>
            </div>
        </div>

        <div class="row g-2 mb-3 print-hide">
            <div class="col-md-4">
                <div class="summary-card">
                    <div class="summary-value"><%= reportData != null ? reportData.size() : 0 %></div>
                    <div class="summary-label">Total Entries</div>
                </div>
            </div>
            <div class="col-md-4">
                <div class="summary-card">
                    <div class="summary-value"><%= df.format(totalAmount) %></div>
                    <div class="summary-label">Total Income (Base Currency)</div>
                </div>
            </div>
            <div class="col-md-4">
                <div class="summary-card">
                    <div class="summary-value"><%= periodLabel %></div>
                    <div class="summary-label">Report Period</div>
                </div>
            </div>
        </div>

        <div class="card mst-card">
            <div class="mst-card-header print-hide">
                <h6 class="mb-0"><i class="fa-solid fa-table me-2"></i>Income Details</h6>
            </div>
            <div class="card-body p-0">
                <div class="table-responsive">
                    <table class="table mst-table table-hover mb-0" id="incomeReportTable">
                        <thead>
                            <tr>
                                <th>S.No</th>
                                <th>Date/Time</th>
                                <th>Particular</th>
                                <th>Description</th>
                                <th class="text-end">Amount</th>
                                <th>User</th>
                            </tr>
                        </thead>
                        <tbody>
                            <% if (reportData != null && reportData.size() > 0) {
                                for (int i = 0; i < reportData.size(); i++) {
                                    Vector row = (Vector) reportData.get(i);
                                    java.sql.Timestamp incomeDate = (java.sql.Timestamp) row.elementAt(0);
                                    String particular = row.elementAt(1) != null ? row.elementAt(1).toString() : "-";
                                    String description = row.elementAt(2) != null ? row.elementAt(2).toString() : "";
                                    BigDecimal amount = (BigDecimal) row.elementAt(3);
                                    String userName = row.elementAt(4) != null ? row.elementAt(4).toString() : "-";
                            %>
                            <tr>
                                <td><%= i + 1 %></td>
                                <td><%= incomeDate != null ? displayDt.format(incomeDate) : "-" %></td>
                                <td class="fw-semibold"><%= particular %></td>
                                <td><%= description.isEmpty() ? "-" : description %></td>
                                <td class="text-end fw-semibold text-success"><%= df.format(amount) %></td>
                                <td><%= userName %></td>
                            </tr>
                            <%  }
                               } else { %>
                            <tr><td colspan="6" class="text-center py-4 text-muted">No income entries found for the selected period</td></tr>
                            <% } %>
                        </tbody>
                        <% if (reportData != null && reportData.size() > 0) { %>
                        <tfoot>
                            <tr class="table-light">
                                <th colspan="4" class="text-end">Grand Total</th>
                                <th class="text-end text-success"><%= df.format(totalAmount) %></th>
                                <th></th>
                            </tr>
                        </tfoot>
                        <% } %>
                    </table>
                </div>
            </div>
        </div>
    </div>
</div>

<script>
    var incomeReportTitle = 'Additional Income Report (<%= fromDate %> to <%= toDate %>)';

    function getIncomePrintStyles() {
        return 'body,h1,h2,h3,p,span,td,th{color:#000!important;}' +
            'h2{font-size:20px;margin:0 0 4px;}' +
            'p{margin:0 0 8px;color:#333!important;}' +
            '.print-summary{margin:8px 0 14px;font-size:13px;}' +
            'table{border-collapse:collapse!important;width:100%;font-size:11px;color:#000!important;}' +
            'table,th,td{border:1px solid black!important;padding:4px!important;color:#000!important;}' +
            'th{background:#ddd!important;}.text-end{text-align:right;}.text-center{text-align:center;}' +
            '.text-success{color:#000!important;font-weight:700;}.print-hide{display:none!important;}';
    }

    function printIncomeReport() {
        var content = document.getElementById('printTable');
        if (!content) return;
        var w = window.open('', '_blank');
        w.document.write('<html><head><title>' + incomeReportTitle + '</title><style>' +
            getIncomePrintStyles() + '</style></head><body>' + content.innerHTML + '</body></html>');
        w.document.close();
        w.focus();
        setTimeout(function() {
            w.print();
            w.close();
        }, 300);
    }
</script>
<br><br><br><br><br>
</body>
</html>
