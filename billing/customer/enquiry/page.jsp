<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page language="java" import="java.util.*"%>
<jsp:useBean id="customer" class="currency.currencyBean" />
<%
Integer userId = (Integer) session.getAttribute("userId");
if (userId == null) {
    response.sendRedirect(request.getContextPath() + "/index.jsp");
    return;
}

Vector paymentMethods = customer.getPaymentMethods();
String selectedCustomerId = request.getParameter("customerId");
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
    <title>Customer Enquiry</title>
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <%@ include file="/assets/common/head.jsp" %>
    <style>
        .enquiry-top-row .enquiry-top-card .mst-card-header {
            padding: 0.45rem 0.85rem;
        }
        .enquiry-top-row .enquiry-top-card .mst-card-header h6 {
            font-size: 0.88rem;
        }
        .enquiry-top-row .enquiry-top-card .card-body {
            padding: 0.65rem 0.85rem;
        }
        .enquiry-top-row .enquiry-top-card .form-label {
            font-size: 0.82rem;
            margin-bottom: 0.25rem;
        }
        .enquiry-top-row .search-wrap { margin-bottom: 0.5rem !important; }
        .enquiry-top-row .enquiry-top-card .form-control {
            padding: 0.35rem 0.65rem;
            font-size: 0.85rem;
        }
        .enquiry-top-row .enquiry-top-card .bb {
            padding: 0.35rem 0.55rem;
            font-size: 0.82rem;
        }
        .balance-card {
            border-radius: 8px;
            padding: 10px 12px;
            color: #fff;
            display: flex;
            flex-direction: column;
            justify-content: space-between;
            gap: 4px;
        }
        .balance-card.advance {
            background: linear-gradient(135deg, #059669, #10b981);
        }
        .balance-card.due { background: linear-gradient(135deg, #dc2626, #ef4444); }
        .balance-label { font-size: 0.78rem; opacity: 0.9; }
        .balance-value { font-size: 1.2rem; font-weight: 700; margin: 2px 0; line-height: 1.2; }
        .balance-hint { font-size: 0.68rem; opacity: 0.85; }
        .due-actions, .advance-actions { display: flex; gap: 4px; margin-top: 2px; }
        .due-actions .btn, .advance-actions .btn { flex: 1; font-size: 0.72rem; padding: 3px 6px; line-height: 1.3; }
        .search-results {
            position: absolute;
            z-index: 1000;
            width: 100%;
            max-height: 240px;
            overflow-y: auto;
            background: #fff;
            border: 1px solid #dbe3ee;
            border-radius: 8px;
            box-shadow: 0 8px 20px rgba(0,0,0,0.08);
            display: none;
        }
        .search-results .item {
            padding: 10px 12px;
            cursor: pointer;
            border-bottom: 1px solid #f1f5f9;
        }
        .search-results .item:hover { background: #f8fafc; }
        .search-wrap { position: relative; }
        .entry-badge-advance { background: #d1fae5; color: #065f46; }
        .entry-badge-due { background: #fee2e2; color: #991b1b; }
        .entry-badge-collection { background: #dbeafe; color: #1e40af; }
        .entries-panel { max-height: 520px; overflow-y: auto; }
        .account-card-body { display: flex; flex-direction: row; gap: 8px; }
        .account-card-body .balance-card { flex: 1; min-width: 0; }
        .balance-list-table tbody tr { cursor: pointer; }
        .balance-list-table tbody tr:hover { background: #f8fafc; }
        .balance-list-panel { max-height: 420px; overflow-y: auto; }
    </style>
</head>
<body>
    <%@ include file="/assets/navbar/navbar.jsp" %>
<%
    request.setAttribute("pageTitle",    "Customer Enquiry");
    request.setAttribute("pageSubtitle", "Customer Management — Account Enquiry");
    request.setAttribute("pageIcon",     "fa-solid fa-magnifying-glass-dollar");
%>
<jsp:include page="/assets/common/pageHeader.jsp" />

<div class="container-fluid mt-3 mst-page">

    <input type="hidden" id="selectedCustomerId">

    <div class="row g-2 mb-2 enquiry-top-row">
        <div class="col-lg-6">
            <div class="card mst-card enquiry-top-card">
                <div class="mst-card-header">
                    <h6 class="mb-0"><i class="fa-solid fa-user-check me-2"></i>Select Customer</h6>
                </div>
                <div class="card-body">
                    <label class="form-label fw-semibold">Search by Name or Phone Number</label>
                    <div class="search-wrap mb-3">
                        <input type="text" id="customerSearch" class="form-control fg-inp" placeholder="Type customer name or phone number" autocomplete="off">
                        <div id="searchResults" class="search-results"></div>
                    </div>
                    <div class="d-flex gap-2">
                        <button type="button" class="bb bb-outline flex-fill" onclick="openBalanceListModal()">
                            <i class="fa-solid fa-users me-1"></i>Balance List
                        </button>
                        <button type="button" id="customerDetailBtn" class="bb bb-primary flex-fill" onclick="showCustomerDetailModal()" disabled>
                            <i class="fa-solid fa-id-card me-1"></i>Detail
                        </button>
                        <button type="button" class="bb bb-outline flex-fill" onclick="clearCustomer()">
                            <i class="fa-solid fa-rotate-left me-1"></i>Clear
                        </button>
                    </div>
                </div>
            </div>
        </div>

        <div class="col-lg-6" id="customerAccountSection" style="display:none;">
            <div class="card mst-card enquiry-top-card">
                <div class="mst-card-header">
                    <h6 class="mb-0"><i class="fa-solid fa-wallet me-2"></i>Customer Account</h6>
                </div>
                <div class="card-body account-card-body">
                    <div class="balance-card advance">
                        <div>
                            <div class="balance-label">Purchase balance to pay</div>
                            <div class="balance-value" id="advanceBalance">0.0000</div>
                        </div>
                        <div class="advance-actions">
                            <button type="button" class="btn btn-light btn-sm" onclick="openAdvanceModal()">
                                <i class="fa-solid fa-plus me-1"></i>Add
                            </button>
                            <button type="button" class="btn btn-light btn-sm" id="payAdvanceBtn" onclick="openPayAdvanceModal()" disabled>
                                <i class="fa-solid fa-money-bill-wave me-1"></i>Pay
                            </button>
                        </div>
                    </div>
                    <div class="balance-card due">
                        <div>
                            <div class="balance-label">Due Balance</div>
                            <div class="balance-value" id="dueBalance">0.0000</div>
                        </div>
                        <div class="due-actions">
                            <button type="button" class="btn btn-light btn-sm" onclick="openAddDueModal()">
                                <i class="fa-solid fa-plus me-1"></i>Add Due
                            </button>
                            <button type="button" class="btn btn-light btn-sm" id="collectDueBtn" onclick="openCollectDueModal()" disabled>
                                <i class="fa-solid fa-money-bill-wave me-1"></i>Collect Due
                            </button>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <div class="row g-3" id="customerEntriesSection" style="display:none;">
        <div class="col-12">
            <div class="card mst-card h-100">
                <div class="mst-card-header">
                    <h6 class="mb-0"><i class="fa-solid fa-list me-2"></i>Account Entries</h6>
                </div>
                <div class="card-body p-0 entries-panel">
                    <table class="table mst-table table-hover mb-0">
                        <thead>
                            <tr>
                                <th>Date</th>
                                <th>Type</th>
                                <th>Payment</th>
                                <th class="text-end">Amount</th>
                                <th class="text-end">Final Adv</th>
                                <th class="text-end">Final Due</th>
                                <th>Notes</th>
                            </tr>
                        </thead>
                        <tbody id="entriesBody">
                            <tr>
                                <td colspan="7" class="text-center py-4 text-muted">No entries found</td>
                            </tr>
                        </tbody>
                    </table>
                </div>
            </div>
        </div>
    </div>
</div>

<div class="modal fade" id="balanceListModal" tabindex="-1" aria-hidden="true">
    <div class="modal-dialog modal-dialog-centered modal-lg">
        <div class="modal-content">
            <div class="modal-header mst-card-header">
                <h6 class="modal-title mb-0"><i class="fa-solid fa-users me-2"></i>Customers with Balance</h6>
                <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal" aria-label="Close"></button>
            </div>
            <div class="modal-body p-3">
                <div class="row g-2 mb-3 align-items-end">
                    <div class="col-md-4">
                        <label class="form-label fw-semibold">Filter</label>
                        <select id="balanceListFilter" class="form-select fg-inp">
                            <option value="all">All (Due or Purchase Balance)</option>
                            <option value="advance">Purchase Balance only</option>
                            <option value="due">Due only</option>
                        </select>
                    </div>
                    <div class="col-md-5">
                        <label class="form-label fw-semibold">Search Name / Phone</label>
                        <input type="text" id="balanceListKeyword" class="form-control fg-inp" placeholder="Type to filter..." autocomplete="off">
                    </div>
                    <div class="col-md-3">
                        <button type="button" class="bb bb-primary w-100" onclick="loadBalanceCustomers()">
                            <i class="fa-solid fa-filter me-1"></i>Apply
                        </button>
                    </div>
                </div>
                <div class="balance-list-panel">
                    <table class="table mst-table table-hover mb-0 balance-list-table">
                        <thead>
                            <tr>
                                <th>Customer</th>
                                <th>Phone</th>
                                <th class="text-end">Purchase Balance</th>
                                <th class="text-end">Due</th>
                            </tr>
                        </thead>
                        <tbody id="balanceListBody">
                            <tr><td colspan="4" class="text-center py-4 text-muted">Loading...</td></tr>
                        </tbody>
                    </table>
                </div>
                <div class="d-flex justify-content-between align-items-center mt-3">
                    <small class="text-muted" id="balanceListCount">0 customers</small>
                    <button type="button" class="bb bb-outline" data-bs-dismiss="modal">Close</button>
                </div>
            </div>
        </div>
    </div>
</div>

<div class="modal fade" id="customerDetailModal" tabindex="-1" aria-hidden="true">
    <div class="modal-dialog modal-dialog-centered">
        <div class="modal-content">
            <div class="modal-header mst-card-header">
                <h6 class="modal-title mb-0"><i class="fa-solid fa-id-card me-2"></i>Customer Details</h6>
                <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal" aria-label="Close"></button>
            </div>
            <div class="modal-body p-3">
                <div class="row g-3">
                    <div class="col-md-6"><strong>Name:</strong> <span id="detailName">-</span></div>
                    <div class="col-md-6"><strong>Phone:</strong> <span id="detailPhone">-</span></div>
                    <div class="col-md-12"><strong>Address:</strong> <span id="detailAddress">-</span></div>
                    <div class="col-md-12"><strong>Notes:</strong> <span id="detailNotes">-</span></div>
                </div>
                <div class="d-flex justify-content-end mt-3">
                    <button type="button" class="bb bb-outline" data-bs-dismiss="modal">Close</button>
                </div>
            </div>
        </div>
    </div>
</div>

<div class="modal fade" id="advanceModal" tabindex="-1" aria-hidden="true">
    <div class="modal-dialog modal-dialog-centered">
        <div class="modal-content">
            <div class="modal-header mst-card-header">
                <h6 class="modal-title mb-0"><i class="fa-solid fa-hand-holding-dollar me-2"></i>Add Purchase Balance</h6>
                <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal" aria-label="Close"></button>
            </div>
            <div class="modal-body p-3">
                <form action="<%=request.getContextPath()%>/customer/enquiry/addAdvance.jsp" method="post">
                    <input type="hidden" name="customerId" class="formCustomerId">
                    <div class="mb-3">
                        <label class="form-label fw-semibold">Amount</label>
                        <input type="number" step="0.0001" min="0.0001" name="amount" class="form-control fg-inp" required>
                    </div>
                    <div class="mb-3">
                        <label class="form-label fw-semibold">Payment Method</label>
                        <select name="paymentId" class="form-select fg-inp" required>
                            <option value="">Select payment method</option>
                            <% for (int i = 0; i < paymentMethods.size(); i++) {
                                Vector pm = (Vector) paymentMethods.get(i);
                            %>
                            <option value="<%= pm.elementAt(0) %>"><%= pm.elementAt(1) %></option>
                            <% } %>
                        </select>
                    </div>
                    <div class="mb-3">
                        <label class="form-label fw-semibold">Notes</label>
                        <textarea name="notes" class="form-control fg-inp" rows="2" placeholder="Optional"></textarea>
                    </div>
                    <div class="d-flex gap-2 justify-content-end">
                        <button type="button" class="bb bb-outline" data-bs-dismiss="modal">Cancel</button>
                        <button type="submit" class="bb bb-primary">Add</button>
                    </div>
                </form>
            </div>
        </div>
    </div>
</div>

<div class="modal fade" id="payAdvanceModal" tabindex="-1" aria-hidden="true">
    <div class="modal-dialog modal-dialog-centered">
        <div class="modal-content">
            <div class="modal-header mst-card-header">
                <h6 class="modal-title mb-0"><i class="fa-solid fa-money-bill-wave me-2"></i>Pay Purchase Balance</h6>
                <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal" aria-label="Close"></button>
            </div>
            <div class="modal-body p-3">
                <form action="<%=request.getContextPath()%>/customer/enquiry/payAdvance.jsp" method="post">
                    <input type="hidden" name="customerId" class="formCustomerId">
                    <div class="mb-3">
                        <label class="form-label fw-semibold">Current Purchase Balance</label>
                        <input type="text" id="currentAdvanceDisplay" class="form-control fg-inp" disabled>
                    </div>
                    <div class="mb-3">
                        <label class="form-label fw-semibold">Pay Amount</label>
                        <input type="number" step="0.0001" min="0.0001" name="amount" id="payAdvanceAmount" class="form-control fg-inp" required>
                    </div>
                    <div class="mb-3">
                        <label class="form-label fw-semibold">Payment Method</label>
                        <select name="paymentId" class="form-select fg-inp" required>
                            <option value="">Select payment method</option>
                            <% for (int i = 0; i < paymentMethods.size(); i++) {
                                Vector pm = (Vector) paymentMethods.get(i);
                            %>
                            <option value="<%= pm.elementAt(0) %>"><%= pm.elementAt(1) %></option>
                            <% } %>
                        </select>
                    </div>
                    <div class="mb-3">
                        <label class="form-label fw-semibold">Notes</label>
                        <textarea name="notes" class="form-control fg-inp" rows="2" placeholder="Optional"></textarea>
                    </div>
                    <div class="d-flex gap-2 justify-content-end">
                        <button type="button" class="bb bb-outline" data-bs-dismiss="modal">Cancel</button>
                        <button type="submit" class="bb bb-primary">Pay</button>
                    </div>
                </form>
            </div>
        </div>
    </div>
</div>

<div class="modal fade" id="addDueModal" tabindex="-1" aria-hidden="true">
    <div class="modal-dialog modal-dialog-centered">
        <div class="modal-content">
            <div class="modal-header mst-card-header">
                <h6 class="modal-title mb-0"><i class="fa-solid fa-file-invoice-dollar me-2"></i>Add Due</h6>
                <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal" aria-label="Close"></button>
            </div>
            <div class="modal-body p-3">
                <form action="<%=request.getContextPath()%>/customer/enquiry/addDue.jsp" method="post">
                    <input type="hidden" name="customerId" class="formCustomerId">
                    <div class="mb-3">
                        <label class="form-label fw-semibold">Amount</label>
                        <input type="number" step="0.0001" min="0.0001" name="amount" class="form-control fg-inp" required>
                    </div>
                    <div class="mb-3">
                        <label class="form-label fw-semibold">Payment Method</label>
                        <select name="paymentId" class="form-select fg-inp" required>
                            <option value="">Select payment method</option>
                            <% for (int i = 0; i < paymentMethods.size(); i++) {
                                Vector pm = (Vector) paymentMethods.get(i);
                            %>
                            <option value="<%= pm.elementAt(0) %>"><%= pm.elementAt(1) %></option>
                            <% } %>
                        </select>
                    </div>
                    <div class="mb-3">
                        <label class="form-label fw-semibold">Notes</label>
                        <textarea name="notes" class="form-control fg-inp" rows="2" placeholder="Optional"></textarea>
                    </div>
                    <div class="d-flex gap-2 justify-content-end">
                        <button type="button" class="bb bb-outline" data-bs-dismiss="modal">Cancel</button>
                        <button type="submit" class="bb bb-outline">Add Due</button>
                    </div>
                </form>
            </div>
        </div>
    </div>
</div>

<div class="modal fade" id="collectDueModal" tabindex="-1" aria-hidden="true">
    <div class="modal-dialog modal-dialog-centered">
        <div class="modal-content">
            <div class="modal-header mst-card-header">
                <h6 class="modal-title mb-0"><i class="fa-solid fa-money-bill-wave me-2"></i>Due Collection</h6>
                <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal" aria-label="Close"></button>
            </div>
            <div class="modal-body p-3">
                <form action="<%=request.getContextPath()%>/customer/enquiry/collectDue.jsp" method="post">
                    <input type="hidden" name="customerId" class="formCustomerId">
                    <div class="mb-3">
                        <label class="form-label fw-semibold">Current Due</label>
                        <input type="text" id="currentDueDisplay" class="form-control fg-inp" disabled>
                    </div>
                    <div class="mb-3">
                        <label class="form-label fw-semibold">Collection Amount</label>
                        <input type="number" step="0.0001" min="0.0001" name="amount" id="collectionAmount" class="form-control fg-inp" required>
                    </div>
                    <div class="mb-3">
                        <label class="form-label fw-semibold">Payment Method</label>
                        <select name="paymentId" class="form-select fg-inp" required>
                            <option value="">Select payment method</option>
                            <% for (int i = 0; i < paymentMethods.size(); i++) {
                                Vector pm = (Vector) paymentMethods.get(i);
                            %>
                            <option value="<%= pm.elementAt(0) %>"><%= pm.elementAt(1) %></option>
                            <% } %>
                        </select>
                    </div>
                    <div class="mb-3">
                        <label class="form-label fw-semibold">Notes</label>
                        <textarea name="notes" class="form-control fg-inp" rows="2" placeholder="Optional"></textarea>
                    </div>
                    <div class="d-flex gap-2 justify-content-end">
                        <button type="button" class="bb bb-outline" data-bs-dismiss="modal">Cancel</button>
                        <button type="submit" class="bb bb-primary">Collect Due</button>
                    </div>
                </form>
            </div>
        </div>
    </div>
</div>

<script>
    const contextPath = '<%=request.getContextPath()%>';
    const searchInput = document.getElementById('customerSearch');
    const searchResults = document.getElementById('searchResults');
    let searchTimer = null;
    let currentDueAmount = 0;
    let currentAdvanceAmount = 0;
    let balanceListTimer = null;
    let balanceListModalInstance = null;

    function openBalanceListModal() {
        if (!balanceListModalInstance) {
            balanceListModalInstance = new bootstrap.Modal(document.getElementById('balanceListModal'));
        }
        document.getElementById('balanceListFilter').value = 'all';
        document.getElementById('balanceListKeyword').value = '';
        balanceListModalInstance.show();
        loadBalanceCustomers();
    }

    function loadBalanceCustomers() {
        const filterType = document.getElementById('balanceListFilter').value;
        const keyword = document.getElementById('balanceListKeyword').value.trim();
        const tbody = document.getElementById('balanceListBody');
        tbody.innerHTML = '<tr><td colspan="4" class="text-center py-4 text-muted">Loading...</td></tr>';

        const url = contextPath + '/customer/enquiry/listBalanceCustomers.jsp'
            + '?filterType=' + encodeURIComponent(filterType)
            + '&keyword=' + encodeURIComponent(keyword);

        fetch(url)
            .then(function(res) { return res.json(); })
            .then(function(data) {
                tbody.innerHTML = '';
                const list = (data && data.customers) ? data.customers : [];
                document.getElementById('balanceListCount').textContent = list.length + ' customer' + (list.length === 1 ? '' : 's');

                if (!data.success) {
                    tbody.innerHTML = '<tr><td colspan="4" class="text-center py-4 text-danger">'
                        + (data.message || 'Unable to load') + '</td></tr>';
                    return;
                }

                if (list.length === 0) {
                    tbody.innerHTML = '<tr><td colspan="4" class="text-center py-4 text-muted">No customers found</td></tr>';
                    return;
                }

                list.forEach(function(item) {
                    const tr = document.createElement('tr');
                    const phoneText = item.phone ? item.phone : '-';
                    tr.innerHTML =
                        '<td class="fw-semibold">' + escapeHtml(item.name || '-') + '</td>' +
                        '<td>' + escapeHtml(phoneText) + '</td>' +
                        '<td class="text-end text-success">' + (item.advance || '0') + '</td>' +
                        '<td class="text-end text-danger">' + (item.due || '0') + '</td>';
                    tr.addEventListener('click', function() {
                        if (balanceListModalInstance) balanceListModalInstance.hide();
                        selectCustomer(item.id, (item.name || '') + ' - ' + (item.phone ? item.phone : 'No phone'));
                    });
                    tbody.appendChild(tr);
                });
            })
            .catch(function(err) {
                console.error(err);
                tbody.innerHTML = '<tr><td colspan="4" class="text-center py-4 text-danger">Unable to load customers</td></tr>';
                document.getElementById('balanceListCount').textContent = '0 customers';
            });
    }

    function escapeHtml(text) {
        return String(text)
            .replace(/&/g, '&amp;')
            .replace(/</g, '&lt;')
            .replace(/>/g, '&gt;')
            .replace(/"/g, '&quot;');
    }

    function openAdvanceModal() {
        if (!document.getElementById('selectedCustomerId').value) return;
        new bootstrap.Modal(document.getElementById('advanceModal')).show();
    }

    function openPayAdvanceModal() {
        if (!document.getElementById('selectedCustomerId').value || currentAdvanceAmount <= 0) return;
        document.getElementById('currentAdvanceDisplay').value = currentAdvanceAmount.toFixed(4);
        document.getElementById('payAdvanceAmount').max = currentAdvanceAmount;
        document.getElementById('payAdvanceAmount').value = '';
        new bootstrap.Modal(document.getElementById('payAdvanceModal')).show();
    }

    function openAddDueModal() {
        if (!document.getElementById('selectedCustomerId').value) return;
        new bootstrap.Modal(document.getElementById('addDueModal')).show();
    }

    function openCollectDueModal() {
        if (!document.getElementById('selectedCustomerId').value || currentDueAmount <= 0) return;
        document.getElementById('currentDueDisplay').value = currentDueAmount.toFixed(4);
        document.getElementById('collectionAmount').max = currentDueAmount;
        document.getElementById('collectionAmount').value = '';
        new bootstrap.Modal(document.getElementById('collectDueModal')).show();
    }

    function renderEntries(entries) {
        const tbody = document.getElementById('entriesBody');
        tbody.innerHTML = '';

        if (!entries || entries.length === 0) {
            tbody.innerHTML = '<tr><td colspan="7" class="text-center py-4 text-muted">No entries found</td></tr>';
            return;
        }

        entries.forEach(function(entry) {
            let badgeClass = 'entry-badge-collection';
            const typeText = (entry.type || '').toLowerCase();
            if (typeText === 'advance' || typeText.indexOf('purchase') >= 0) badgeClass = 'entry-badge-advance';
            else if (typeText === 'due') badgeClass = 'entry-badge-due';

            const tr = document.createElement('tr');
            tr.innerHTML =
                '<td>' + (entry.date || '-') + '</td>' +
                '<td><span class="badge ' + badgeClass + '">' + entry.type + '</span></td>' +
                '<td>' + (entry.paymentMethod || '-') + '</td>' +
                '<td class="text-end fw-semibold">' + entry.amount + '</td>' +
                '<td class="text-end">' + (entry.finalAdvance || '0') + '</td>' +
                '<td class="text-end">' + (entry.finalDue || '0') + '</td>' +
                '<td>' + (entry.notes ? entry.notes : '-') + '</td>';
            tbody.appendChild(tr);
        });
    }

    searchInput.addEventListener('input', function() {
        clearTimeout(searchTimer);
        const query = this.value.trim();
        if (query.length < 1) {
            searchResults.style.display = 'none';
            searchResults.innerHTML = '';
            return;
        }

        searchTimer = setTimeout(function() {
            fetch(contextPath + '/customer/enquiry/searchCustomer.jsp?query=' + encodeURIComponent(query))
                .then(function(res) { return res.json(); })
                .then(function(data) {
                    searchResults.innerHTML = '';
                    if (!data || data.length === 0) {
                        searchResults.innerHTML = '<div class="item text-muted">No customers found</div>';
                    } else {
                        data.forEach(function(item) {
                            const div = document.createElement('div');
                            div.className = 'item';
                            const phoneText = item.phone ? item.phone : 'No phone';
                            div.textContent = item.name + ' - ' + phoneText;
                            div.addEventListener('click', function() {
                                selectCustomer(item.id, item.name + ' - ' + phoneText);
                            });
                            searchResults.appendChild(div);
                        });
                    }
                    searchResults.style.display = 'block';
                })
                .catch(function(err) {
                    console.error(err);
                });
        }, 250);
    });

    document.getElementById('balanceListFilter').addEventListener('change', loadBalanceCustomers);
    document.getElementById('balanceListKeyword').addEventListener('input', function() {
        clearTimeout(balanceListTimer);
        balanceListTimer = setTimeout(loadBalanceCustomers, 300);
    });
    document.getElementById('balanceListKeyword').addEventListener('keydown', function(e) {
        if (e.key === 'Enter') {
            e.preventDefault();
            clearTimeout(balanceListTimer);
            loadBalanceCustomers();
        }
    });

    document.addEventListener('click', function(e) {
        if (!searchResults.contains(e.target) && e.target !== searchInput) {
            searchResults.style.display = 'none';
        }
    });

    function selectCustomer(customerId, label) {
        searchInput.value = label;
        searchResults.style.display = 'none';
        loadCustomerAccount(customerId);
    }

    function loadCustomerAccount(customerId) {
        fetch(contextPath + '/customer/enquiry/getAccount.jsp?customerId=' + encodeURIComponent(customerId))
            .then(function(res) { return res.json(); })
            .then(function(data) {
                if (!data.success) {
                    alert(data.message || 'Unable to load customer account');
                    return;
                }

                document.getElementById('selectedCustomerId').value = data.customerId;
                document.querySelectorAll('.formCustomerId').forEach(function(el) {
                    el.value = data.customerId;
                });

                document.getElementById('detailName').textContent = data.name || '-';
                document.getElementById('detailPhone').textContent = data.phone || '-';
                document.getElementById('detailAddress').textContent = data.address || '-';
                document.getElementById('detailNotes').textContent = data.notes || '-';
                document.getElementById('advanceBalance').textContent = data.advance;
                document.getElementById('dueBalance').textContent = data.due;
                searchInput.value = data.name + ' - ' + (data.phone ? data.phone : 'No phone');

                currentDueAmount = parseFloat(data.due || '0');
                currentAdvanceAmount = parseFloat(data.advance || '0');
                document.getElementById('collectDueBtn').disabled = currentDueAmount <= 0;
                document.getElementById('payAdvanceBtn').disabled = currentAdvanceAmount <= 0;

                renderEntries(data.entries || []);
                document.getElementById('customerAccountSection').style.display = 'block';
                document.getElementById('customerEntriesSection').style.display = 'flex';
                document.getElementById('customerDetailBtn').disabled = false;
            })
            .catch(function(err) {
                console.error(err);
                alert('Unable to load customer account');
            });
    }

    function showCustomerDetailModal() {
        const customerId = document.getElementById('selectedCustomerId').value;
        if (!customerId) {
            return;
        }
        new bootstrap.Modal(document.getElementById('customerDetailModal')).show();
    }

    function clearCustomer() {
        searchInput.value = '';
        searchResults.innerHTML = '';
        searchResults.style.display = 'none';
        document.getElementById('customerAccountSection').style.display = 'none';
        document.getElementById('customerEntriesSection').style.display = 'none';
        document.getElementById('selectedCustomerId').value = '';
        document.getElementById('detailName').textContent = '-';
        document.getElementById('detailPhone').textContent = '-';
        document.getElementById('detailAddress').textContent = '-';
        document.getElementById('detailNotes').textContent = '-';
        document.getElementById('customerDetailBtn').disabled = true;
        currentDueAmount = 0;
        currentAdvanceAmount = 0;
        renderEntries([]);
    }

    <% if (selectedCustomerId != null && !selectedCustomerId.trim().isEmpty()) { %>
    document.addEventListener('DOMContentLoaded', function() {
        loadCustomerAccount('<%= selectedCustomerId %>');
    });
    <% } %>

    <% if (msg != null && !msg.trim().isEmpty()) { %>
    document.addEventListener('DOMContentLoaded', function() {
        var alertType = '<%= (type != null ? type : "info") %>';
        var swalIcon = 'info';
        var swalTitle = 'Information';

        if (alertType === 'success') {
            swalIcon = 'success';
            swalTitle = 'Success';
        } else if (alertType === 'danger') {
            swalIcon = 'error';
            swalTitle = 'Error';
        } else if (alertType === 'warning') {
            swalIcon = 'warning';
            swalTitle = 'Warning';
        }

        Swal.fire({
            icon: swalIcon,
            title: swalTitle,
            text: '<%= jsMsg %>',
            confirmButtonText: 'OK'
        });

        if (window.history.replaceState) {
            var cleanUrl = window.location.pathname;
            <% if (selectedCustomerId != null && !selectedCustomerId.trim().isEmpty()) { %>
            cleanUrl += '?customerId=<%= selectedCustomerId %>';
            <% } %>
            window.history.replaceState({}, document.title, cleanUrl);
        }
    });
    <% } %>
</script>
</body>
</html>
