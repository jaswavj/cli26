<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>

<%@ page language="java" import="java.util.*, java.math.BigDecimal, java.text.SimpleDateFormat, java.util.Date" %>

<jsp:useBean id="exchange" class="currency.exchangeBean" />
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



Vector cashBookSummary = exchange.getCashBookSummary(fromDate, toDate);
Vector bankBookSummary = exchange.getBankBookSummary(fromDate, toDate);
Vector dayBookSummary = exchange.getDayBookSummary(fromDate, toDate);
Vector allTransactions = exchange.getAllTransactionsReport(fromDate, toDate);

BigDecimal cashOpening = exchange.getLedgerOpeningBalance(fromDate, true);
BigDecimal bankOpening = exchange.getLedgerOpeningBalance(fromDate, false);

BigDecimal cashTotalIn = BigDecimal.ZERO;
BigDecimal cashTotalOut = BigDecimal.ZERO;
for (int i = 0; i < cashBookSummary.size(); i++) {
    Vector row = (Vector) cashBookSummary.get(i);
    cashTotalIn = cashTotalIn.add((BigDecimal) row.elementAt(1));
    cashTotalOut = cashTotalOut.add((BigDecimal) row.elementAt(2));
}
BigDecimal cashClosing = cashOpening.add(cashTotalIn).subtract(cashTotalOut);

BigDecimal bankTotalIn = BigDecimal.ZERO;
BigDecimal bankTotalOut = BigDecimal.ZERO;
for (int i = 0; i < bankBookSummary.size(); i++) {
    Vector row = (Vector) bankBookSummary.get(i);
    bankTotalIn = bankTotalIn.add((BigDecimal) row.elementAt(1));
    bankTotalOut = bankTotalOut.add((BigDecimal) row.elementAt(2));
}
BigDecimal bankClosing = bankOpening.add(bankTotalIn).subtract(bankTotalOut);

BigDecimal dayOpening = cashOpening.add(bankOpening);
BigDecimal dayTotalIn = cashTotalIn.add(bankTotalIn);
BigDecimal dayTotalOut = cashTotalOut.add(bankTotalOut);
BigDecimal dayClosing = dayOpening.add(dayTotalIn).subtract(dayTotalOut);
%>

<!DOCTYPE html>

<html lang="en">

<head>

    <meta charset="UTF-8">

    <title>Ledger Report</title>

    <meta name="viewport" content="width=device-width, initial-scale=1">

    <%@ include file="/assets/common/head.jsp" %>

    <style>

        .summary-card { background: #f8fafc; border: 1px solid #e2e8f0; border-radius: 8px; padding: 12px; text-align: center; }

        .summary-value { font-size: 1.2rem; font-weight: 700; color: var(--bill-navy, #1e3a5f); }

        .balance-row td { background: #e8f4fd; font-weight: 700; color: var(--bill-navy, #1e3a5f); }
        .group-header td { background: #eef2f7; font-weight: 700; color: var(--bill-navy, #1e3a5f); }

        .report-section { margin-bottom: 28px; }

        .report-section-title {

            font-size: 1rem; font-weight: 700; color: var(--bill-navy, #1e3a5f);

            margin-bottom: 12px; padding-bottom: 6px; border-bottom: 2px solid #e2e8f0;

        }

        .export-btn {

            width: 42px; height: 42px; border-radius: 8px; border: 1px solid #dbe3ee;

            background: #fff; color: var(--bill-navy, #1e3a5f); display: inline-flex;

            align-items: center; justify-content: center; font-size: 1.1rem;

            cursor: pointer; transition: all 0.15s ease;

        }

        .export-btn:hover { background: var(--bill-navy, #1e3a5f); color: #fff; border-color: var(--bill-navy, #1e3a5f); }

        .export-btn.print-btn:hover { background: #0f766e; border-color: #0f766e; }

        .export-btn.excel-btn:hover { background: #15803d; border-color: #15803d; }

        .export-btn.pdf-btn:hover { background: #b91c1c; border-color: #b91c1c; }

        #printTable .print-meta { margin-bottom: 18px; }

        #printTable .print-meta h2 { font-size: 1.25rem; margin: 0 0 4px; color: var(--bill-navy, #1e3a5f); }

        #printTable .print-meta p { margin: 0; color: #64748b; font-size: 0.9rem; }

        @media print {

            .print-hide { display: none !important; }

            .navbar, nav, header { display: none !important; }

            body { padding: 0; }

            .report-section { page-break-inside: avoid; margin-bottom: 20px; }

            .mst-card { border: none !important; box-shadow: none !important; }

        }

    </style>

</head>

<body>

    <%@ include file="/assets/navbar/navbar.jsp" %>

<%

    request.setAttribute("pageTitle", "Ledger Report");

    request.setAttribute("pageSubtitle", "Cash Book / Bank Book / Day Book / All Transactions");

    request.setAttribute("pageIcon", "fa-solid fa-book");

%>

<jsp:include page="/assets/common/pageHeader.jsp" />



<div class="container-fluid mt-3 mst-page">

    <div class="d-flex flex-wrap justify-content-between align-items-center gap-2 mb-3 print-hide">

        <a href="<%=request.getContextPath()%>/exchange/page.jsp" class="bb bb-outline btn-sm">

            <i class="fa-solid fa-arrow-left me-1"></i>Back to Exchange

        </a>

        <div class="d-flex gap-2" title="Export all sections">

            <button type="button" class="export-btn print-btn" onclick="printLedgerReport()" title="Print">

                <i class="fa-solid fa-print"></i>

            </button>

            <button type="button" class="export-btn excel-btn" onclick="exportLedgerExcel()" title="Export Excel">

                <i class="fa-solid fa-file-excel"></i>

            </button>

            <button type="button" class="export-btn pdf-btn" onclick="exportLedgerPdf()" title="Export PDF">

                <i class="fa-solid fa-file-pdf"></i>

            </button>

        </div>

    </div>



    <div class="card mst-card mb-3 print-hide">

        <div class="card-body p-3">

            <form method="get" class="row g-2 align-items-end">

                <div class="col-md-3">

                    <label class="form-label fw-semibold">From Date</label>

                    <input type="date" name="fromDate" class="form-control fg-inp" value="<%= fromDate %>">

                </div>

                <div class="col-md-3">

                    <label class="form-label fw-semibold">To Date</label>

                    <input type="date" name="toDate" class="form-control fg-inp" value="<%= toDate %>">

                </div>

                <div class="col-md-3">

                    <button type="submit" class="bb bb-primary w-100"><i class="fa-solid fa-filter me-1"></i>Filter</button>

                </div>

            </form>

        </div>

    </div>



    <div id="printTable">

        <div class="print-meta">

            <h2>Ledger Report</h2>

            <p>Period: <%= fromDate %> to <%= toDate %></p>

        </div>



        <!-- Cash Book -->

        <div class="report-section">

            <div class="report-section-title"><i class="fa-solid fa-money-bill-wave me-2"></i>Cash Book</div>

            <div class="row g-2 mb-3 print-hide">
                <div class="col-md-3">
                    <div class="summary-card">
                        <div class="summary-value"><%= cashOpening.toPlainString() %></div>
                        <div class="text-muted small">Opening Balance</div>
                    </div>
                </div>
                <div class="col-md-3">
                    <div class="summary-card">
                        <div class="summary-value"><%= cashTotalIn.toPlainString() %></div>
                        <div class="text-muted small">Total Cash In</div>
                    </div>
                </div>
                <div class="col-md-3">
                    <div class="summary-card">
                        <div class="summary-value"><%= cashTotalOut.toPlainString() %></div>
                        <div class="text-muted small">Total Cash Out</div>
                    </div>
                </div>
                <div class="col-md-3">
                    <div class="summary-card">
                        <div class="summary-value"><%= cashClosing.toPlainString() %></div>
                        <div class="text-muted small">Closing Balance</div>
                    </div>
                </div>
            </div>

            <div class="card mst-card">
                <div class="card-body p-0">
                    <div class="table-responsive">
                        <table class="table mst-table table-hover mb-0">
                            <thead>
                                <tr>
                                    <th>Description</th>
                                    <th class="text-end">Cash In</th>
                                    <th class="text-end">Cash Out</th>
                                </tr>
                            </thead>
                            <tbody>
                                <tr class="balance-row">
                                    <td>Opening Balance</td>
                                    <td class="text-end"><%= cashOpening.toPlainString() %></td>
                                    <td class="text-end">0.0000</td>
                                </tr>
                                <% if (cashBookSummary.size() > 0) {
                                    for (int i = 0; i < cashBookSummary.size(); i++) {
                                        Vector row = (Vector) cashBookSummary.get(i);
                                        BigDecimal cashIn = (BigDecimal) row.elementAt(1);
                                        BigDecimal cashOut = (BigDecimal) row.elementAt(2);
                                %>
                                <tr>
                                    <td><%= row.elementAt(0) %></td>
                                    <td class="text-end"><%= cashIn.compareTo(BigDecimal.ZERO) > 0 ? cashIn.toPlainString() : "" %></td>
                                    <td class="text-end"><%= cashOut.compareTo(BigDecimal.ZERO) > 0 ? cashOut.toPlainString() : "" %></td>
                                </tr>
                                <%  } } else { %>
                                <tr><td colspan="3" class="text-center py-4 text-muted">No cash entries found</td></tr>
                                <% } %>
                                <tr class="balance-row">
                                    <td>Closing Balance</td>
                                    <td class="text-end"><%= cashClosing.toPlainString() %></td>
                                    <td class="text-end"></td>
                                </tr>
                            </tbody>
                        </table>
                    </div>
                </div>
            </div>

        </div>



        <!-- Bank Book -->

        <div class="report-section">

            <div class="report-section-title"><i class="fa-solid fa-building-columns me-2"></i>Bank Book</div>

            <div class="row g-2 mb-3 print-hide">
                <div class="col-md-3">
                    <div class="summary-card">
                        <div class="summary-value"><%= bankOpening.toPlainString() %></div>
                        <div class="text-muted small">Opening Balance</div>
                    </div>
                </div>
                <div class="col-md-3">
                    <div class="summary-card">
                        <div class="summary-value"><%= bankTotalIn.toPlainString() %></div>
                        <div class="text-muted small">Total Bank In</div>
                    </div>
                </div>
                <div class="col-md-3">
                    <div class="summary-card">
                        <div class="summary-value"><%= bankTotalOut.toPlainString() %></div>
                        <div class="text-muted small">Total Bank Out</div>
                    </div>
                </div>
                <div class="col-md-3">
                    <div class="summary-card">
                        <div class="summary-value"><%= bankClosing.toPlainString() %></div>
                        <div class="text-muted small">Closing Balance</div>
                    </div>
                </div>
            </div>

            <div class="card mst-card">
                <div class="card-body p-0">
                    <div class="table-responsive">
                        <table class="table mst-table table-hover mb-0">
                            <thead>
                                <tr>
                                    <th>Description</th>
                                    <th class="text-end">Bank In</th>
                                    <th class="text-end">Bank Out</th>
                                </tr>
                            </thead>
                            <tbody>
                                <tr class="balance-row">
                                    <td>Opening Balance</td>
                                    <td class="text-end"><%= bankOpening.toPlainString() %></td>
                                    <td class="text-end">0.0000</td>
                                </tr>
                                <% if (bankBookSummary.size() > 0) {
                                    for (int i = 0; i < bankBookSummary.size(); i++) {
                                        Vector row = (Vector) bankBookSummary.get(i);
                                        BigDecimal bankIn = (BigDecimal) row.elementAt(1);
                                        BigDecimal bankOut = (BigDecimal) row.elementAt(2);
                                %>
                                <tr>
                                    <td><%= row.elementAt(0) %></td>
                                    <td class="text-end"><%= bankIn.compareTo(BigDecimal.ZERO) > 0 ? bankIn.toPlainString() : "" %></td>
                                    <td class="text-end"><%= bankOut.compareTo(BigDecimal.ZERO) > 0 ? bankOut.toPlainString() : "" %></td>
                                </tr>
                                <%  } } else { %>
                                <tr><td colspan="3" class="text-center py-4 text-muted">No bank entries found</td></tr>
                                <% } %>
                                <tr class="balance-row">
                                    <td>Closing Balance</td>
                                    <td class="text-end"><%= bankClosing.toPlainString() %></td>
                                    <td class="text-end"></td>
                                </tr>
                            </tbody>
                        </table>
                    </div>
                </div>
            </div>

        </div>



        <!-- Day Book -->

        <div class="report-section">

            <div class="report-section-title"><i class="fa-solid fa-calendar-day me-2"></i>Day Book</div>

            <div class="row g-2 mb-3 print-hide">
                <div class="col-md-3">
                    <div class="summary-card">
                        <div class="summary-value"><%= dayOpening.toPlainString() %></div>
                        <div class="text-muted small">Opening Balance</div>
                    </div>
                </div>
                <div class="col-md-3">
                    <div class="summary-card">
                        <div class="summary-value"><%= dayTotalIn.toPlainString() %></div>
                        <div class="text-muted small">Total In</div>
                    </div>
                </div>
                <div class="col-md-3">
                    <div class="summary-card">
                        <div class="summary-value"><%= dayTotalOut.toPlainString() %></div>
                        <div class="text-muted small">Total Out</div>
                    </div>
                </div>
                <div class="col-md-3">
                    <div class="summary-card">
                        <div class="summary-value"><%= dayClosing.toPlainString() %></div>
                        <div class="text-muted small">Closing Balance</div>
                    </div>
                </div>
            </div>

            <div class="card mst-card">
                <div class="card-body p-0">
                    <div class="table-responsive">
                        <table class="table mst-table table-hover mb-0">
                            <thead>
                                <tr>
                                    <th>Description</th>
                                    <th class="text-end">Cash In</th>
                                    <th class="text-end">Cash Out</th>
                                </tr>
                            </thead>
                            <tbody>
                                <tr class="balance-row">
                                    <td>Opening Balance</td>
                                    <td class="text-end"><%= dayOpening.toPlainString() %></td>
                                    <td class="text-end">0.0000</td>
                                </tr>
                                <% if (dayBookSummary.size() > 0) {
                                    for (int i = 0; i < dayBookSummary.size(); i++) {
                                        Vector row = (Vector) dayBookSummary.get(i);
                                        BigDecimal dayIn = (BigDecimal) row.elementAt(1);
                                        BigDecimal dayOut = (BigDecimal) row.elementAt(2);
                                %>
                                <tr>
                                    <td><%= row.elementAt(0) %></td>
                                    <td class="text-end"><%= dayIn.compareTo(BigDecimal.ZERO) > 0 ? dayIn.toPlainString() : "" %></td>
                                    <td class="text-end"><%= dayOut.compareTo(BigDecimal.ZERO) > 0 ? dayOut.toPlainString() : "" %></td>
                                </tr>
                                <%  } } else { %>
                                <tr><td colspan="3" class="text-center py-4 text-muted">No entries found</td></tr>
                                <% } %>
                                <tr class="balance-row">
                                    <td>Closing Balance</td>
                                    <td class="text-end"><%= dayClosing.toPlainString() %></td>
                                    <td class="text-end"></td>
                                </tr>
                            </tbody>
                        </table>
                    </div>
                </div>
            </div>

        </div>



        <!-- All Transactions -->

        <div class="report-section">

            <div class="report-section-title"><i class="fa-solid fa-list me-2"></i>All Transactions</div>

            <div class="card mst-card">

                <div class="card-body p-0">

                    <div class="table-responsive">

                        <table class="table mst-table table-hover mb-0">

                            <thead>

                                <tr>

                                    <th>#</th>

                                    <th>Date/Time</th>

                                    <th>Customer</th>

                                    <th>Phone</th>

                                    <th>Type</th>

                                    <th class="text-end">Amount</th>

                                    <th>Payment</th>

                                    <th>Details</th>

                                    <th>User</th>

                                </tr>

                            </thead>

                            <tbody>

                                <% if (allTransactions.size() > 0) {

                                    for (int i = 0; i < allTransactions.size(); i++) {

                                        Vector row = (Vector) allTransactions.get(i);

                                %>

                                <tr>

                                    <td><%= row.elementAt(0) %></td>

                                    <td><%= row.elementAt(1) %></td>

                                    <td><%= row.elementAt(2) %></td>

                                    <td><%= row.elementAt(3) != null ? row.elementAt(3) : "-" %></td>

                                    <td><%= row.elementAt(4) %></td>

                                    <td class="text-end fw-semibold"><%= ((BigDecimal) row.elementAt(5)).toPlainString() %></td>

                                    <td><%= row.elementAt(6) != null ? row.elementAt(6) : "-" %></td>

                                    <td><%= row.elementAt(7) != null ? row.elementAt(7) : "-" %></td>

                                    <td><%= row.elementAt(8) != null ? row.elementAt(8) : "-" %></td>

                                </tr>

                                <%  } } else { %>

                                <tr><td colspan="9" class="text-center py-4 text-muted">No transactions found</td></tr>

                                <% } %>

                            </tbody>

                        </table>

                    </div>

                </div>

            </div>

        </div>

    </div>

</div>



<script>
    var ledgerFromDate = '<%= fromDate %>';
    var ledgerToDate = '<%= toDate %>';
    var ledgerTitle = 'Ledger Report (' + ledgerFromDate + ' to ' + ledgerToDate + ')';

    function getLedgerExportStyles() {
        return 'body,h1,h2,h3,h4,h5,h6,p,span,td,th,a,div{color:#000!important;}' +
            'h2{font-size:20px;margin:0 0 4px;}' +
            'p{margin:0 0 16px;color:#333!important;}' +
            '.report-section{margin-bottom:24px;page-break-inside:avoid;}' +
            '.report-section-title{font-size:16px;font-weight:700;margin:0 0 10px;padding-bottom:4px;border-bottom:1px solid #000;}' +
            'table{border-collapse:collapse!important;width:100%;font-size:11px;color:#000!important;margin-bottom:12px;}' +
            'table,th,td{border:1px solid black!important;padding:4px!important;color:#000!important;}' +
            'th{background:#ddd!important;}.balance-row td{background:#eee!important;font-weight:700;}' +
            '.group-header td{background:#eef2f7!important;font-weight:700;}' +
            '.text-end{text-align:right;}.text-center{text-align:center;}.print-hide,button{display:none!important;}';
    }

    function openLedgerExportWindow(keepOpen) {
        var table = document.getElementById('printTable');
        if (!table) return;
        var w = window.open('', '_blank');
        w.document.write('<html><head><title>' + ledgerTitle + '</title><style>' +
            getLedgerExportStyles() + '</style></head><body>' + table.outerHTML + '</body></html>');
        w.document.close();
        w.focus();
        setTimeout(function() {
            w.print();
            if (!keepOpen) w.close();
        }, 300);
    }

    function printLedgerReport() {
        openLedgerExportWindow(false);
    }

    function exportLedgerExcel() {
        exportTableToExcel('printTable', 'Ledger_Report_' + ledgerFromDate + '_' + ledgerToDate);
    }

    function exportLedgerPdf() {
        openLedgerExportWindow(true);
    }
</script>

</body>

</html>

