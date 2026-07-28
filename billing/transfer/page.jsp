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
Vector currencies = exchange.getCurrenciesWithLimits();
Vector giveList = exchange.getCurrencyTransferList(1);
Vector getList = exchange.getCurrencyTransferList(2);

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
    <title>Currency Transfer</title>
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <%@ include file="/assets/common/head.jsp" %>
    <style>
        .currency-pick-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(140px, 1fr)); gap: 10px; }
        .currency-pick-card {
            border: 1px solid #dbe3ee; border-radius: 10px; padding: 12px; cursor: pointer;
            background: #fff; transition: box-shadow .15s, border-color .15s;
        }
        .currency-pick-card:hover { border-color: var(--bill-gold, #c9a227); box-shadow: 0 6px 16px rgba(0,0,0,.08); }
        .currency-pick-code { font-weight: 700; font-size: 1rem; color: var(--bill-navy, #1e3a5f); }
        .currency-pick-stock { font-size: 0.78rem; color: #64748b; margin-top: 4px; }
        .search-results {
            position: absolute; z-index: 1050; width: 100%; max-height: 220px;
            overflow-y: auto; background: #fff; border: 1px solid #dbe3ee;
            border-radius: 8px; box-shadow: 0 8px 20px rgba(0,0,0,0.08); display: none;
        }
        .search-results .item { padding: 10px 12px; cursor: pointer; border-bottom: 1px solid #f1f5f9; }
        .search-results .item:hover { background: #f8fafc; }
        .search-wrap { position: relative; }
        .transfer-list-panel { max-height: 360px; overflow-y: auto; }
    </style>
</head>
<body>
    <%@ include file="/assets/navbar/navbar.jsp" %>
<%
    request.setAttribute("pageTitle", "Currency Transfer");
    request.setAttribute("pageSubtitle", "Give / Get currency with customer");
    request.setAttribute("pageIcon", "fa-solid fa-truck-ramp-box");
%>
<jsp:include page="/assets/common/pageHeader.jsp" />

<div class="container-fluid mt-3 mst-page">
    <div class="row g-3 mb-3">
        <div class="col-12">
            <div class="card mst-card">
                <div class="mst-card-header d-flex justify-content-between align-items-center flex-wrap gap-2">
                    <h6 class="mb-0"><i class="fa-solid fa-coins me-2"></i>Select Currency</h6>
                    <a href="<%=request.getContextPath()%>/transfer/report/transferReport.jsp" class="bb bb-outline btn-sm">
                        <i class="fa-solid fa-chart-line me-1"></i>Transfer Report
                    </a>
                </div>
                <div class="card-body p-3">
                    <div class="currency-pick-grid">
                        <% if (currencies != null && currencies.size() > 0) {
                            for (int i = 0; i < currencies.size(); i++) {
                                Vector c = (Vector) currencies.get(i);
                                int cid = Integer.parseInt(c.elementAt(0).toString());
                                String code = c.elementAt(1).toString();
                                String name = c.elementAt(2).toString();
                                BigDecimal stock = (BigDecimal) c.elementAt(5);
                        %>
                        <div class="currency-pick-card" role="button" tabindex="0"
                             onclick="openTransferModal(<%= cid %>, '<%= code.replace("'", "\\'") %>', '<%= name.replace("'", "\\'") %>', '<%= stock.toPlainString() %>')"
                             onkeydown="if(event.key==='Enter'){openTransferModal(<%= cid %>, '<%= code.replace("'", "\\'") %>', '<%= name.replace("'", "\\'") %>', '<%= stock.toPlainString() %>');}">
                            <div class="currency-pick-code"><%= code %></div>
                            <div class="small text-muted"><%= name %></div>
                            <div class="currency-pick-stock">Stock: <%= stock.toPlainString() %></div>
                        </div>
                        <%  }
                           } else { %>
                        <div class="text-muted">No active currencies. Add currencies in Currency Master.</div>
                        <% } %>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <div class="row g-3">
        <div class="col-lg-6">
            <div class="card mst-card h-100">
                <div class="mst-card-header">
                    <h6 class="mb-0"><i class="fa-solid fa-arrow-up-from-bracket me-2"></i>Give List</h6>
                </div>
                <div class="card-body p-0 transfer-list-panel">
                    <table class="table mst-table table-hover mb-0">
                        <thead>
                            <tr>
                                <th>Date</th>
                                <th>Customer</th>
                                <th>Curr</th>
                                <th class="text-end">Qty</th>
                                <th>Status</th>
                                <th></th>
                            </tr>
                        </thead>
                        <tbody>
                            <% if (giveList != null && giveList.size() > 0) {
                                for (int i = 0; i < giveList.size(); i++) {
                                    Vector row = (Vector) giveList.get(i);
                                    int tid = Integer.parseInt(row.elementAt(0).toString());
                                    int status = Integer.parseInt(row.elementAt(9).toString());
                            %>
                            <tr>
                                <td><%= row.elementAt(1) %></td>
                                <td><%= row.elementAt(3) %></td>
                                <td><%= row.elementAt(6) %></td>
                                <td class="text-end"><%= ((BigDecimal) row.elementAt(7)).toPlainString() %></td>
                                <td><%= status == 0 ? "Open" : "Taken " + (row.elementAt(10) != null ? row.elementAt(10) : "") %></td>
                                <td class="text-end">
                                    <% if (status == 0) { %>
                                    <button type="button" class="btn btn-sm btn-outline-primary"
                                        onclick="openReturnModal(<%= tid %>, 'give')">Take Back</button>
                                    <% } else { %>—<% } %>
                                </td>
                            </tr>
                            <%  }
                               } else { %>
                            <tr><td colspan="6" class="text-center py-3 text-muted">No give transfers</td></tr>
                            <% } %>
                        </tbody>
                    </table>
                </div>
            </div>
        </div>
        <div class="col-lg-6">
            <div class="card mst-card h-100">
                <div class="mst-card-header">
                    <h6 class="mb-0"><i class="fa-solid fa-arrow-down-to-bracket me-2"></i>Get List</h6>
                </div>
                <div class="card-body p-0 transfer-list-panel">
                    <table class="table mst-table table-hover mb-0">
                        <thead>
                            <tr>
                                <th>Date</th>
                                <th>Customer</th>
                                <th>Curr</th>
                                <th class="text-end">Qty</th>
                                <th>Status</th>
                                <th></th>
                            </tr>
                        </thead>
                        <tbody>
                            <% if (getList != null && getList.size() > 0) {
                                for (int i = 0; i < getList.size(); i++) {
                                    Vector row = (Vector) getList.get(i);
                                    int tid = Integer.parseInt(row.elementAt(0).toString());
                                    int status = Integer.parseInt(row.elementAt(9).toString());
                            %>
                            <tr>
                                <td><%= row.elementAt(1) %></td>
                                <td><%= row.elementAt(3) %></td>
                                <td><%= row.elementAt(6) %></td>
                                <td class="text-end"><%= ((BigDecimal) row.elementAt(7)).toPlainString() %></td>
                                <td><%= status == 0 ? "Open" : "Given " + (row.elementAt(10) != null ? row.elementAt(10) : "") %></td>
                                <td class="text-end">
                                    <% if (status == 0) { %>
                                    <button type="button" class="btn btn-sm btn-outline-primary"
                                        onclick="openReturnModal(<%= tid %>, 'get')">Give Back</button>
                                    <% } else { %>—<% } %>
                                </td>
                            </tr>
                            <%  }
                               } else { %>
                            <tr><td colspan="6" class="text-center py-3 text-muted">No get transfers</td></tr>
                            <% } %>
                        </tbody>
                    </table>
                </div>
            </div>
        </div>
    </div>
</div>

<div class="modal fade" id="transferModal" tabindex="-1" aria-hidden="true">
    <div class="modal-dialog modal-dialog-centered">
        <div class="modal-content">
            <div class="modal-header mst-card-header">
                <h6 class="modal-title mb-0"><i class="fa-solid fa-truck-ramp-box me-2"></i>Currency Transfer</h6>
                <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal"></button>
            </div>
            <div class="modal-body p-3">
                <form action="<%=request.getContextPath()%>/transfer/save.jsp" method="post" id="transferForm">
                    <input type="hidden" name="customerId" id="customerId" value="">
                    <input type="hidden" name="customerName" id="customerName">
                    <input type="hidden" name="currencyId" id="currencyId">
                    <input type="hidden" name="transferType" id="transferType" value="1">

                    <div class="mb-2 p-2 rounded bg-light">
                        <strong id="selectedCurrencyLabel">—</strong>
                        <div class="small text-muted">Available stock: <span id="selectedCurrencyStock">0</span></div>
                    </div>

                    <div class="mb-3">
                        <label class="form-label fw-semibold">Customer (Name or Phone)</label>
                        <div class="search-wrap">
                            <input type="text" id="customerSearch" class="form-control fg-inp"
                                placeholder="Search existing or type new customer name" autocomplete="off" required>
                            <div id="searchResults" class="search-results"></div>
                        </div>
                        <small class="text-muted">If not found, enter name and phone — new customer on save.</small>
                    </div>
                    <div class="mb-3">
                        <label class="form-label fw-semibold">Phone (for new customer)</label>
                        <input type="text" name="customerPhone" id="customerPhone" class="form-control fg-inp" placeholder="Optional">
                    </div>

                    <div class="mb-3">
                        <label class="form-label fw-semibold d-block">Type</label>
                        <div class="btn-group type-toggle w-100" role="group">
                            <input type="radio" class="btn-check" name="transferTypeUi" id="typeGive" value="1" checked>
                            <label class="btn btn-outline-secondary" for="typeGive"><i class="fa-solid fa-arrow-up-from-bracket me-1"></i>Give</label>
                            <input type="radio" class="btn-check" name="transferTypeUi" id="typeGet" value="2">
                            <label class="btn btn-outline-secondary" for="typeGet"><i class="fa-solid fa-arrow-down-to-bracket me-1"></i>Get</label>
                        </div>
                    </div>

                    <div class="row g-2 mb-3">
                        <div class="col-md-6">
                            <label class="form-label fw-semibold">Date</label>
                            <input type="date" name="transferDate" class="form-control fg-inp" value="<%= today %>" required>
                        </div>
                        <div class="col-md-6">
                            <label class="form-label fw-semibold">Quantity</label>
                            <input type="number" step="0.0001" min="0.0001" name="quantity" id="quantity" class="form-control fg-inp" placeholder="0.0000" required>
                        </div>
                    </div>

                    <div class="mb-3">
                        <label class="form-label fw-semibold">Notes</label>
                        <textarea name="notes" class="form-control fg-inp" rows="2" placeholder="Optional"></textarea>
                    </div>

                    <div class="d-flex gap-2 justify-content-end">
                        <button type="button" class="bb bb-outline" data-bs-dismiss="modal">Cancel</button>
                        <button type="submit" class="bb bb-primary"><i class="fa-solid fa-floppy-disk me-1"></i>Save</button>
                    </div>
                </form>
            </div>
        </div>
    </div>
</div>

<div class="modal fade" id="returnModal" tabindex="-1" aria-hidden="true">
    <div class="modal-dialog modal-dialog-centered">
        <div class="modal-content">
            <div class="modal-header mst-card-header">
                <h6 class="modal-title mb-0" id="returnModalTitle">Return</h6>
                <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal"></button>
            </div>
            <div class="modal-body p-3">
                <form action="<%=request.getContextPath()%>/transfer/returnTransfer.jsp" method="post">
                    <input type="hidden" name="transferId" id="returnTransferId">
                    <div class="mb-3">
                        <label class="form-label fw-semibold" id="returnDateLabel">Date</label>
                        <input type="date" name="returnDate" class="form-control fg-inp" value="<%= today %>" required>
                    </div>
                    <div class="d-flex gap-2 justify-content-end">
                        <button type="button" class="bb bb-outline" data-bs-dismiss="modal">Cancel</button>
                        <button type="submit" class="bb bb-primary">Save</button>
                    </div>
                </form>
            </div>
        </div>
    </div>
</div>

<script>
    const contextPath = '<%=request.getContextPath()%>';
    let selectedStock = 0;
    let transferModal;
    let returnModal;
    let searchTimer = null;

    const searchInput = document.getElementById('customerSearch');
    const searchResults = document.getElementById('searchResults');

    document.addEventListener('DOMContentLoaded', function() {
        transferModal = new bootstrap.Modal(document.getElementById('transferModal'));
        returnModal = new bootstrap.Modal(document.getElementById('returnModal'));

        document.querySelectorAll('input[name="transferTypeUi"]').forEach(function(el) {
            el.addEventListener('change', function() {
                document.getElementById('transferType').value = this.value;
            });
        });

        document.getElementById('transferForm').addEventListener('submit', function(e) {
            const type = parseInt(document.getElementById('transferType').value, 10);
            const qty = parseFloat(document.getElementById('quantity').value) || 0;
            if (type === 1 && qty > selectedStock) {
                e.preventDefault();
                alert('Insufficient stock for Give. Available: ' + selectedStock.toFixed(4));
                return;
            }
            if (!document.getElementById('customerId').value) {
                document.getElementById('customerName').value = searchInput.value.trim();
            }
        });
    });

    function openTransferModal(currencyId, code, name, stock) {
        document.getElementById('currencyId').value = currencyId;
        document.getElementById('selectedCurrencyLabel').textContent = code + ' — ' + name;
        selectedStock = parseFloat(stock) || 0;
        document.getElementById('selectedCurrencyStock').textContent = selectedStock.toFixed(4);
        document.getElementById('customerId').value = '';
        document.getElementById('customerName').value = '';
        document.getElementById('customerPhone').value = '';
        searchInput.value = '';
        document.getElementById('quantity').value = '';
        document.getElementById('typeGive').checked = true;
        document.getElementById('transferType').value = '1';
        transferModal.show();
    }

    function openReturnModal(transferId, kind) {
        document.getElementById('returnTransferId').value = transferId;
        if (kind === 'give') {
            document.getElementById('returnModalTitle').textContent = 'Take Back (Given currency returned)';
            document.getElementById('returnDateLabel').textContent = 'Taken Date';
        } else {
            document.getElementById('returnModalTitle').textContent = 'Give Back (Received currency returned)';
            document.getElementById('returnDateLabel').textContent = 'Given Date';
        }
        returnModal.show();
    }

    searchInput.addEventListener('input', function() {
        clearTimeout(searchTimer);
        document.getElementById('customerId').value = '';
        document.getElementById('customerName').value = this.value.trim();
        const query = this.value.trim();
        if (query.length < 1) {
            searchResults.style.display = 'none';
            return;
        }
        searchTimer = setTimeout(function() {
            fetch(contextPath + '/customer/enquiry/searchCustomer.jsp?query=' + encodeURIComponent(query))
                .then(function(res) { return res.json(); })
                .then(function(data) {
                    searchResults.innerHTML = '';
                    if (!data || data.length === 0) {
                        searchResults.innerHTML = '<div class="item text-muted">No match — new customer on save</div>';
                    } else {
                        data.forEach(function(item) {
                            const div = document.createElement('div');
                            div.className = 'item';
                            div.textContent = item.name + ' - ' + (item.phone || 'No phone');
                            div.addEventListener('click', function() {
                                document.getElementById('customerId').value = item.id;
                                document.getElementById('customerName').value = item.name;
                                searchInput.value = item.name;
                                document.getElementById('customerPhone').value = item.phone || '';
                                searchResults.style.display = 'none';
                            });
                            searchResults.appendChild(div);
                        });
                    }
                    searchResults.style.display = 'block';
                });
        }, 250);
    });

    document.addEventListener('click', function(e) {
        if (searchResults && !searchResults.contains(e.target) && e.target !== searchInput) {
            searchResults.style.display = 'none';
        }
    });

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
