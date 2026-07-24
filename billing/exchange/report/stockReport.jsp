<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page language="java" import="java.util.*, java.math.BigDecimal" %>
<jsp:useBean id="exchange" class="currency.exchangeBean" />
<jsp:useBean id="currency" class="currency.currencyBean" />
<%
Integer userId = (Integer) session.getAttribute("userId");
if (userId == null) {
    response.sendRedirect(request.getContextPath() + "/index.jsp");
    return;
}
Vector stockData = exchange.getCurrentStockReport();
Vector currencies = currency.getActiveCurrencyList();
String msg = request.getParameter("msg");
String type = request.getParameter("type");
String jsMsg = "";
if (msg != null) {
    jsMsg = msg.replace("\\", "\\\\").replace("'", "\\'").replace("\"", "\\\"").replace("\r", "").replace("\n", "\\n");
}
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Current Stock Report</title>
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <%@ include file="/assets/common/head.jsp" %>
</head>
<body>
    <%@ include file="/assets/navbar/navbar.jsp" %>
<%
    request.setAttribute("pageTitle", "Current Stock Report");
    request.setAttribute("pageSubtitle", "Currency Exchange — Stock on Hand");
    request.setAttribute("pageIcon", "fa-solid fa-boxes-stacked");
%>
<jsp:include page="/assets/common/pageHeader.jsp" />

<div class="container-fluid mt-3 mst-page">
    <div class="mb-3 d-flex gap-2 flex-wrap">
        <a href="<%=request.getContextPath()%>/exchange/page.jsp" class="bb bb-outline btn-sm">
            <i class="fa-solid fa-arrow-left me-1"></i>Back to Exchange
        </a>
        <button type="button" class="bb bb-primary btn-sm" onclick="openAdjustModal()">
            <i class="fa-solid fa-sliders me-1"></i>Add / Remove Stock
        </button>
    </div>
    <div class="card mst-card">
        <div class="card-body p-0">
            <div class="table-responsive">
                <table class="table mst-table table-hover mb-0">
                    <thead>
                        <tr>
                            <th>#</th>
                            <th>Code</th>
                            <th>Currency</th>
                            <th class="text-end">Stock Qty</th>
                            <th>Last Updated</th>
                            <th class="text-center">Action</th>
                        </tr>
                    </thead>
                    <tbody>
                        <% if (stockData != null && stockData.size() > 0) {
                            for (int i = 0; i < stockData.size(); i++) {
                                Vector row = (Vector) stockData.get(i);
                                int cid = Integer.parseInt(row.elementAt(0).toString());
                                BigDecimal qty = (BigDecimal) row.elementAt(3);
                        %>
                        <tr>
                            <td><%= i + 1 %></td>
                            <td class="fw-semibold"><%= row.elementAt(1) %></td>
                            <td><%= row.elementAt(2) %></td>
                            <td class="text-end fw-semibold"><%= qty != null ? qty.toPlainString() : "0" %></td>
                            <td><%= row.elementAt(4) != null ? row.elementAt(4).toString() : "-" %></td>
                            <td class="text-center">
                                <button type="button" class="btn btn-sm bb bb-outline"
                                    onclick="openAdjustModal(<%= cid %>, '<%= row.elementAt(1).toString().replace("'", "\\'") %>', '<%= qty != null ? qty.toPlainString() : "0" %>')">
                                    <i class="fa-solid fa-sliders"></i>
                                </button>
                            </td>
                        </tr>
                        <%  }
                           } else { %>
                        <tr><td colspan="6" class="text-center py-4 text-muted">No stock data found</td></tr>
                        <% } %>
                    </tbody>
                </table>
            </div>
        </div>
    </div>
</div>

<div class="modal fade" id="adjustStockModal" tabindex="-1" aria-hidden="true">
    <div class="modal-dialog modal-dialog-centered">
        <div class="modal-content">
            <div class="modal-header mst-card-header">
                <h6 class="modal-title mb-0"><i class="fa-solid fa-sliders me-2"></i>Adjust Stock</h6>
                <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal"></button>
            </div>
            <div class="modal-body p-3">
                <form action="<%=request.getContextPath()%>/exchange/saveStockAdjustment.jsp" method="post" id="adjustForm">
                    <div class="mb-3">
                        <label class="form-label fw-semibold">Currency</label>
                        <select name="currencyId" id="adjCurrencyId" class="form-select fg-inp" required>
                            <option value="">Select currency</option>
                            <% for (int i = 0; i < currencies.size(); i++) {
                                Vector c = (Vector) currencies.get(i);
                            %>
                            <option value="<%= c.elementAt(0) %>"><%= c.elementAt(1) %> — <%= c.elementAt(2) %></option>
                            <% } %>
                        </select>
                        <div id="currentStockHint" class="text-muted small mt-1"></div>
                    </div>
                    <div class="mb-3">
                        <label class="form-label fw-semibold d-block">Action</label>
                        <div class="btn-group w-100" role="group">
                            <input type="radio" class="btn-check" name="adjustmentType" id="adjAdd" value="1" checked>
                            <label class="btn btn-outline-success" for="adjAdd"><i class="fa-solid fa-plus me-1"></i>Add Stock</label>
                            <input type="radio" class="btn-check" name="adjustmentType" id="adjRemove" value="2">
                            <label class="btn btn-outline-danger" for="adjRemove"><i class="fa-solid fa-minus me-1"></i>Remove Stock</label>
                        </div>
                    </div>
                    <div class="mb-3">
                        <label class="form-label fw-semibold">Quantity</label>
                        <input type="number" step="0.0001" min="0.0001" name="quantity" id="adjQuantity" class="form-control fg-inp" required>
                    </div>
                    <div class="mb-3">
                        <label class="form-label fw-semibold">Reason</label>
                        <textarea name="reason" class="form-control fg-inp" rows="3" placeholder="Enter reason for this adjustment" required></textarea>
                    </div>
                    <div class="d-flex gap-2 justify-content-end">
                        <button type="button" class="bb bb-outline" data-bs-dismiss="modal">Cancel</button>
                        <button type="submit" class="bb bb-primary">Save Adjustment</button>
                    </div>
                </form>
            </div>
        </div>
    </div>
</div>

<script>
    const stockMap = {
        <% if (stockData != null) {
            for (int i = 0; i < stockData.size(); i++) {
                Vector row = (Vector) stockData.get(i);
                if (i > 0) out.print(",");
                out.print(row.elementAt(0) + ": '" + ((BigDecimal) row.elementAt(3)).toPlainString() + "'");
            }
        } %>
    };

    function updateStockHint() {
        const cid = document.getElementById('adjCurrencyId').value;
        const hint = document.getElementById('currentStockHint');
        if (cid && stockMap[cid] !== undefined) {
            hint.textContent = 'Current stock: ' + stockMap[cid];
        } else {
            hint.textContent = '';
        }
    }

    function openAdjustModal(currencyId, code, qty) {
        const modal = new bootstrap.Modal(document.getElementById('adjustStockModal'));
        if (currencyId) {
            document.getElementById('adjCurrencyId').value = currencyId;
            document.getElementById('currentStockHint').textContent = 'Current stock: ' + (qty || stockMap[currencyId] || '0');
        } else {
            document.getElementById('adjCurrencyId').value = '';
            document.getElementById('currentStockHint').textContent = '';
        }
        document.getElementById('adjQuantity').value = '';
        document.querySelector('#adjustForm textarea[name="reason"]').value = '';
        document.getElementById('adjAdd').checked = true;
        modal.show();
    }

    document.getElementById('adjCurrencyId').addEventListener('change', updateStockHint);

    <% if (msg != null && !msg.trim().isEmpty()) { %>
    document.addEventListener('DOMContentLoaded', function() {
        Swal.fire({
            icon: '<%= (type != null && type.equals("success")) ? "success" : "error" %>',
            title: '<%= (type != null && type.equals("success")) ? "Success" : "Error" %>',
            text: '<%= jsMsg %>'
        });
        if (window.history.replaceState) {
            window.history.replaceState({}, document.title, window.location.pathname);
        }
    });
    <% } %>
</script>
</body>
</html>
