<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page language="java" import="java.util.*, java.math.BigDecimal, java.text.SimpleDateFormat, java.util.Date" %>
<jsp:useBean id="exchange" class="currency.exchangeBean" />
<jsp:useBean id="currency" class="currency.currencyBean" />
<%!
    private String formatReportCell(BigDecimal value) {
        if (value == null || value.compareTo(BigDecimal.ZERO) == 0) {
            return "";
        }
        return value.setScale(2, BigDecimal.ROUND_HALF_UP).toPlainString();
    }

    private String formatReportAdjusted(BigDecimal dueAdjusted, BigDecimal advanceAdjusted) {
        BigDecimal due = dueAdjusted != null ? dueAdjusted : BigDecimal.ZERO;
        BigDecimal adv = advanceAdjusted != null ? advanceAdjusted : BigDecimal.ZERO;
        if (due.compareTo(BigDecimal.ZERO) > 0) {
            return "Due " + due.setScale(2, BigDecimal.ROUND_HALF_UP).toPlainString();
        }
        if (adv.compareTo(BigDecimal.ZERO) > 0) {
            return "Adv " + adv.setScale(2, BigDecimal.ROUND_HALF_UP).toPlainString();
        }
        return "";
    }
%>
<%
Integer userId = (Integer) session.getAttribute("userId");
if (userId == null) {
    response.sendRedirect(request.getContextPath() + "/index.jsp");
    return;
}

String today = new SimpleDateFormat("yyyy-MM-dd").format(new Date());
String fromDate = request.getParameter("fromDate");
String toDate = request.getParameter("toDate");
String exchangeTypeFilter = request.getParameter("exchangeType");
String currencyFilter = request.getParameter("currencyId");
if (fromDate == null || fromDate.isEmpty()) fromDate = today;
if (toDate == null || toDate.isEmpty()) toDate = today;
if (exchangeTypeFilter == null || exchangeTypeFilter.isEmpty()) exchangeTypeFilter = "0";
if (currencyFilter == null || currencyFilter.isEmpty()) currencyFilter = "0";

Vector currencies = currency.getActiveCurrencyList();
Vector reportData = exchange.getCurrencyExchangeReport(fromDate, toDate,
    Integer.parseInt(exchangeTypeFilter), Integer.parseInt(currencyFilter));
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Currency Exchange Report</title>
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <%@ include file="/assets/common/head.jsp" %>
</head>
<body>
    <%@ include file="/assets/navbar/navbar.jsp" %>
<%
    request.setAttribute("pageTitle", "Currency Exchange Report");
    request.setAttribute("pageSubtitle", "Purchase / Sale Transactions");
    request.setAttribute("pageIcon", "fa-solid fa-right-left");
%>
<jsp:include page="/assets/common/pageHeader.jsp" />

<div class="container-fluid mt-3 mst-page">
    <div class="mb-3">
        <a href="<%=request.getContextPath()%>/exchange/page.jsp" class="bb bb-outline btn-sm">
            <i class="fa-solid fa-arrow-left me-1"></i>Back to Exchange
        </a>
    </div>

    <div class="card mst-card mb-3">
        <div class="card-body p-3">
            <form method="get" class="row g-2 align-items-end">
                <div class="col-md-2">
                    <label class="form-label fw-semibold">From Date</label>
                    <input type="date" name="fromDate" class="form-control fg-inp" value="<%= fromDate %>">
                </div>
                <div class="col-md-2">
                    <label class="form-label fw-semibold">To Date</label>
                    <input type="date" name="toDate" class="form-control fg-inp" value="<%= toDate %>">
                </div>
                <div class="col-md-2">
                    <label class="form-label fw-semibold">Type</label>
                    <select name="exchangeType" class="form-select fg-inp">
                        <option value="0" <%= "0".equals(exchangeTypeFilter) ? "selected" : "" %>>All</option>
                        <option value="1" <%= "1".equals(exchangeTypeFilter) ? "selected" : "" %>>Purchase</option>
                        <option value="2" <%= "2".equals(exchangeTypeFilter) ? "selected" : "" %>>Sale</option>
                    </select>
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
                <table class="table mst-table table-hover mb-0" id="printTable">
                    <thead>
                        <tr>
                            <th>#</th>
                            <th>Date</th>
                            <th>Customer</th>
                            <th>Phone</th>
                            <th>Type</th>
                            <th>Currency</th>
                            <th class="text-end">Amount</th>
                            <th>Base</th>
                            <th class="text-end">Base Amount</th>
                            <th class="text-end">Rate</th>
                            <th class="text-end">Adjusted</th>
                            <th class="text-end">Paid</th>
                            <th class="text-end">Balance</th>
                            <th>Payment</th>
                            <th>User</th>
                            <th>Notes</th>
                        </tr>
                    </thead>
                    <tbody>
                        <% if (reportData != null && reportData.size() > 0) {
                            for (int i = 0; i < reportData.size(); i++) {
                                Vector row = (Vector) reportData.get(i);
                        %>
                        <tr>
                            <td><%= row.elementAt(0) %></td>
                            <td><%= row.elementAt(1) %></td>
                            <td><%= row.elementAt(3) %></td>
                            <td><%= row.elementAt(4) != null ? row.elementAt(4) : "-" %></td>
                            <td><%= row.elementAt(5) %></td>
                            <td class="fw-semibold"><%= row.elementAt(6) %></td>
                            <td class="text-end fw-semibold"><%= ((BigDecimal) row.elementAt(7)).toPlainString() %></td>
                            <td class="fw-semibold"><%= row.elementAt(8) %></td>
                            <td class="text-end fw-semibold"><%= ((BigDecimal) row.elementAt(9)).toPlainString() %></td>
                            <td class="text-end"><%= ((BigDecimal) row.elementAt(10)).toPlainString() %></td>
                            <td class="text-end"><%= formatReportAdjusted((BigDecimal) row.elementAt(13), (BigDecimal) row.elementAt(14)) %></td>
                            <td class="text-end"><%= formatReportCell((BigDecimal) row.elementAt(11)) %></td>
                            <td class="text-end"><%= formatReportCell((BigDecimal) row.elementAt(12)) %></td>
                            <td><%= row.elementAt(15) != null ? row.elementAt(15) : "-" %></td>
                            <td><%= row.elementAt(17) != null ? row.elementAt(17) : "-" %></td>
                            <td><%= row.elementAt(16) != null ? row.elementAt(16) : "-" %></td>
                        </tr>
                        <%  }
                           } else { %>
                        <tr><td colspan="16" class="text-center py-4 text-muted">No exchange transactions found</td></tr>
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
