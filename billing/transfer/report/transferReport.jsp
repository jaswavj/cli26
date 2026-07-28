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
String customerFilter = request.getParameter("customerId");
if (fromDate == null || fromDate.isEmpty()) fromDate = today;
if (toDate == null || toDate.isEmpty()) toDate = today;
if (customerFilter == null || customerFilter.isEmpty()) customerFilter = "0";

Vector customers = currency.getCustomerList();
Vector reportData = exchange.getCurrencyTransferReport(fromDate, toDate, Integer.parseInt(customerFilter));
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Currency Transfer Report</title>
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <%@ include file="/assets/common/head.jsp" %>
</head>
<body>
    <%@ include file="/assets/navbar/navbar.jsp" %>
<%
    request.setAttribute("pageTitle", "Currency Transfer Report");
    request.setAttribute("pageSubtitle", "Give / Get transfers by date and customer");
    request.setAttribute("pageIcon", "fa-solid fa-truck-ramp-box");
%>
<jsp:include page="/assets/common/pageHeader.jsp" />

<div class="container-fluid mt-3 mst-page">
    <div class="mb-3">
        <a href="<%=request.getContextPath()%>/transfer/page.jsp" class="bb bb-outline btn-sm">
            <i class="fa-solid fa-arrow-left me-1"></i>Back to Transfer
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
                <div class="col-md-4">
                    <label class="form-label fw-semibold">Customer</label>
                    <select name="customerId" class="form-select fg-inp">
                        <option value="0">All Customers</option>
                        <% for (int i = 0; i < customers.size(); i++) {
                            Vector c = (Vector) customers.get(i);
                            int cid = Integer.parseInt(c.elementAt(0).toString());
                            String cname = c.elementAt(1).toString();
                        %>
                        <option value="<%= cid %>" <%= customerFilter.equals(String.valueOf(cid)) ? "selected" : "" %>><%= cname %></option>
                        <% } %>
                    </select>
                </div>
                <div class="col-md-2">
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
                            <th>#</th>
                            <th>Date</th>
                            <th>Customer</th>
                            <th>Phone</th>
                            <th>Type</th>
                            <th>Currency</th>
                            <th class="text-end">Qty</th>
                            <th>Status</th>
                            <th>Return Date</th>
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
                            <td><%= row.elementAt(9) %></td>
                            <td><%= row.elementAt(10) != null ? row.elementAt(10) : "-" %></td>
                            <td><%= row.elementAt(11) != null ? row.elementAt(11) : "-" %></td>
                            <td><%= row.elementAt(8) != null ? row.elementAt(8) : "-" %></td>
                        </tr>
                        <%  }
                           } else { %>
                        <tr><td colspan="11" class="text-center py-4 text-muted">No transfers found</td></tr>
                        <% } %>
                    </tbody>
                </table>
            </div>
        </div>
    </div>
</div>
</body>
</html>
