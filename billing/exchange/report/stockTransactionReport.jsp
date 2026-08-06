<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page language="java" import="java.util.*, java.math.BigDecimal, java.text.SimpleDateFormat, java.util.Date" %>
<jsp:useBean id="exchange" class="currency.exchangeBean" />
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
String currencyFilter = request.getParameter("currencyId");
if (fromDate == null || fromDate.isEmpty()) fromDate = today;
if (toDate == null || toDate.isEmpty()) toDate = today;
if (currencyFilter == null) currencyFilter = "0";

Vector currencies = currency.getActiveCurrencyList();
Vector reportData = exchange.getStockTransactionReport(fromDate, toDate, Integer.parseInt(currencyFilter));
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Stock Transaction Report</title>
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <%@ include file="/assets/common/head.jsp" %>
</head>
<body>
    <%@ include file="/assets/navbar/navbar.jsp" %>
<%
    request.setAttribute("pageTitle", "Stock Transaction Report");
    request.setAttribute("pageSubtitle", "Currency Exchange — Stock Movements");
    request.setAttribute("pageIcon", "fa-solid fa-arrows-rotate");
%>
<jsp:include page="/assets/common/pageHeader.jsp" />

<div class="container-fluid mt-3 mst-page">
    <div class="mb-3 d-flex gap-2 flex-wrap">
        <a href="<%=request.getContextPath()%>/exchange/page.jsp" class="bb bb-outline btn-sm">
            <i class="fa-solid fa-arrow-left me-1"></i>Back to Exchange
        </a>
        <a href="<%=request.getContextPath()%>/exchange/report/stockReport.jsp" class="bb bb-primary btn-sm">
            <i class="fa-solid fa-sliders me-1"></i>Add / Remove Stock
        </a>
    </div>

    <div class="card mst-card mb-3">
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
                    <label class="form-label fw-semibold">Currency</label>
                    <select name="currencyId" class="form-select fg-inp">
                        <option value="0">All Currencies</option>
                        <% for (int i = 0; i < currencies.size(); i++) {
                            Vector c = (Vector) currencies.get(i);
                            int cid = Integer.parseInt(c.elementAt(0).toString());
                        %>
                        <option value="<%= cid %>" <%= currencyFilter.equals(String.valueOf(cid)) ? "selected" : "" %>><%= c.elementAt(1) %></option>
                        <% } %>
                    </select>
                </div>
                <div class="col-md-3">
                    <button type="submit" class="bb bb-primary w-100"><i class="fa-solid fa-filter me-1"></i>Filter</button>
                </div>
            </form>
        </div>
    </div>

    <div class="card mst-card">
        <div class="card-body p-0">
            <div class="table-responsive">
                <table class="table mst-table table-hover mb-0">
                    <thead>
                        <tr>
                            <th>Date</th>
                            <th>Currency</th>
                            <th>Type</th>
                            <th class="text-end">Qty</th>
                            <th class="text-end">Before</th>
                            <th class="text-end">After</th>
                            <th>Customer</th>
                            <th>Reference</th>
                            <th>Reason</th>
                        </tr>
                    </thead>
                    <tbody>
                        <% if (reportData != null && reportData.size() > 0) {
                            for (int i = 0; i < reportData.size(); i++) {
                                Vector row = (Vector) reportData.get(i);
                        %>
                        <tr>
                            <td><%= row.elementAt(0) %></td>
                            <td class="fw-semibold"><%= row.elementAt(1) %></td>
                            <td><%= row.elementAt(2) %></td>
                            <td class="text-end"><%= ((BigDecimal) row.elementAt(3)).toPlainString() %></td>
                            <td class="text-end"><%= ((BigDecimal) row.elementAt(4)).toPlainString() %></td>
                            <td class="text-end"><%= ((BigDecimal) row.elementAt(5)).toPlainString() %></td>
                            <td><%= row.elementAt(6) %></td>
                            <td><%= row.elementAt(7) %></td>
                            <td><%= row.elementAt(8) != null && !"-".equals(row.elementAt(8).toString()) ? row.elementAt(8) : "-" %></td>
                        </tr>
                        <%  }
                           } else { %>
                        <tr><td colspan="9" class="text-center py-4 text-muted">No transactions found</td></tr>
                        <% } %>
                    </tbody>
                </table>
            </div>
        </div>
    </div>
</div>
<br><br><br><br><br>
</body>
</html>
