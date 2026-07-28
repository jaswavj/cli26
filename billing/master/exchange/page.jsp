<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page language="java" import="java.util.*"%>
<%@ page language="java" import="java.math.BigDecimal"%>
<jsp:useBean id="currency" class="currency.currencyBean" />
<%
Integer userId = (Integer) session.getAttribute("userId");
if (userId == null) {
    response.sendRedirect(request.getContextPath() + "/index.jsp");
    return;
}

Vector allCurrencies = currency.getCurrencyList();
boolean hasBaseCurrency = currency.hasBaseCurrency();
int baseCurrencyId = currency.getBaseCurrencyId();
String baseCurrencyCode = "";
String baseCurrencyName = "";
if (allCurrencies != null) {
    for (int i = 0; i < allCurrencies.size(); i++) {
        Vector row = (Vector) allCurrencies.get(i);
        if (Integer.parseInt(row.elementAt(0).toString()) == baseCurrencyId) {
            baseCurrencyCode = row.elementAt(1).toString();
            baseCurrencyName = row.elementAt(2).toString();
            break;
        }
    }
}
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Currency Master - Currency Exchange</title>
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <%@ include file="/assets/common/head.jsp" %>
    <style>
        .table td, .table th { vertical-align: middle; }
        .badge { padding: 0.35em 0.65em; }
        .limit-block {
            border: 1px solid #e2e8f0;
            border-radius: 8px;
            padding: 12px;
            margin-bottom: 12px;
            background: #f8fafc;
        }
        .limit-block-title {
            font-weight: 600;
            font-size: 0.9rem;
            margin-bottom: 8px;
            color: var(--bill-navy, #1e3a5f);
        }
        .limit-direction {
            font-size: 0.8rem;
            font-weight: 600;
            color: #64748b;
            margin: 10px 0 6px;
        }
        .limit-direction:first-of-type {
            margin-top: 0;
        }
    </style>
</head>
<body>
    <%@ include file="/assets/navbar/navbar.jsp" %>
<%
    request.setAttribute("pageTitle",    "Currency Master");
    request.setAttribute("pageSubtitle", "Master — Exchange Currencies");
    request.setAttribute("pageIcon",     "fa-solid fa-coins");
%>
<jsp:include page="/assets/common/pageHeader.jsp" />

<%
String msg = request.getParameter("msg");
String type = request.getParameter("type");
%>

<div class="container-fluid mt-3 mst-page">
<% if (msg != null) { %>
<div class="alert alert-<%= (type != null ? type : "info") %> alert-dismissible fade show mb-3" role="alert">
  <%= msg %>
  <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Close"></button>
</div>
<% } %>

    <div class="row g-3">
        <div class="col-lg-4">
            <div class="card mst-card h-100">
                <div class="mst-card-header">
                    <h6 class="mb-0"><i class="fa-solid fa-plus-circle me-2"></i>Add Currency</h6>
                </div>
                <div class="card-body p-3">
                    <form action="<%=contextPath%>/master/exchange/save.jsp" method="post" id="addCurrencyForm">
                        <div class="mb-3">
                            <label class="form-label fw-semibold">Currency Code</label>
                            <input type="text" name="currencyCode" class="form-control fg-inp text-uppercase" placeholder="e.g. INR" maxlength="10" required>
                        </div>
                        <div class="mb-3">
                            <label class="form-label fw-semibold">Currency Name</label>
                            <input type="text" name="currencyName" class="form-control fg-inp" placeholder="e.g. Indian Rupee" maxlength="100" required>
                        </div>
                        <div class="mb-3">
                            <div class="form-check">
                                <input type="checkbox" class="form-check-input" name="isBase" id="addIsBase" value="1"
                                    <%= hasBaseCurrency ? "disabled" : "" %>>
                                <label class="form-check-label fw-semibold" for="addIsBase">Base Currency</label>
                            </div>
                            <% if (hasBaseCurrency) { %>
                            <small class="text-muted d-block mt-1">A base currency is already set. Only one base currency is allowed.</small>
                            <% } else { %>
                            <small class="text-muted d-block mt-1">Mark this as the base currency for exchange transactions.</small>
                            <% } %>
                        </div>

                        <% if (hasBaseCurrency && baseCurrencyId > 0) { %>
                        <div class="mb-3" id="addBaseLimitSection">
                            <label class="form-label fw-semibold">Exchange Limit vs Base Currency</label>
                            <small class="text-muted d-block mb-2">Set min / max rate for this currency against <%= baseCurrencyCode %> (base).</small>
                            <div class="limit-block">
                                <div class="limit-block-title"><%= baseCurrencyCode %> — <%= baseCurrencyName %></div>
                                <input type="hidden" name="refCurrencyId" value="<%= baseCurrencyId %>">

                                <div class="limit-direction new-to-ref-label" data-ref-code="<%= baseCurrencyCode %>">New Currency &rarr; <%= baseCurrencyCode %></div>
                                <div class="row g-2">
                                    <div class="col-6">
                                        <label class="form-label small mb-1">Min Value</label>
                                        <input type="number" step="0.0001" min="0" name="refMin" class="form-control fg-inp ref-limit-input" placeholder="0.0000" required>
                                    </div>
                                    <div class="col-6">
                                        <label class="form-label small mb-1">Max Value</label>
                                        <input type="number" step="0.0001" min="0" name="refMax" class="form-control fg-inp ref-limit-input" placeholder="0.0000" required>
                                    </div>
                                </div>
                            </div>
                        </div>
                        <% } else { %>
                        <div class="mb-3">
                            <small class="text-muted">Set a base currency first. Then new currencies will ask only for min / max vs that base.</small>
                        </div>
                        <% } %>

                        <button type="submit" class="bb bb-primary w-100">
                            <i class="fa-solid fa-floppy-disk me-1"></i>Save Currency
                        </button>
                    </form>
                </div>
            </div>
        </div>

        <div class="col-lg-8">
            <div class="card mst-card">
                <div class="mst-card-header">
                    <h6 class="mb-0"><i class="fa-solid fa-list me-2"></i>Available Currencies</h6>
                </div>
                <div class="card-body p-0">
                    <div class="table-responsive">
                        <table class="table mst-table table-hover mb-0">
                            <thead>
                                <tr>
                                    <th>#</th>
                                    <th>Code</th>
                                    <th>Name</th>
                                    <th>Base</th>
                                    <th>Exchange Limits</th>
                                    <th>Status</th>
                                    <th class="text-center">Actions</th>
                                </tr>
                            </thead>
                            <tbody>
                                <%
                                try {
                                    if (allCurrencies != null && allCurrencies.size() > 0) {
                                        for (int i = 0; i < allCurrencies.size(); i++) {
                                            Vector row = (Vector) allCurrencies.get(i);
                                            int id = Integer.parseInt(row.elementAt(0).toString());
                                            String code = row.elementAt(1).toString();
                                            String name = row.elementAt(2).toString();
                                            int isActive = Integer.parseInt(row.elementAt(3).toString());
                                            int isBase = Integer.parseInt(row.elementAt(4).toString());
                                            String limitsSummary = currency.getCurrencyLimitsSummary(id);

                                            StringBuilder limitsJson = new StringBuilder("[");
                                            Vector limits = currency.getCurrencyLimits(id);
                                            boolean firstLimit = true;
                                            for (int j = 0; j < limits.size(); j++) {
                                                Vector limitRow = (Vector) limits.get(j);
                                                int refId = Integer.parseInt(limitRow.elementAt(0).toString());
                                                if (baseCurrencyId > 0 && refId != baseCurrencyId) {
                                                    continue;
                                                }
                                                if (!firstLimit) limitsJson.append(",");
                                                firstLimit = false;
                                                limitsJson.append("{")
                                                    .append("\"refId\":").append(refId)
                                                    .append(",\"refCode\":\"").append(limitRow.elementAt(1).toString().replace("\"", "\\\""))
                                                    .append("\",\"min\":\"").append(((BigDecimal) limitRow.elementAt(3)).toPlainString())
                                                    .append("\",\"max\":\"").append(((BigDecimal) limitRow.elementAt(4)).toPlainString())
                                                    .append("\"}");
                                            }
                                            limitsJson.append("]");
                                %>
                                <tr>
                                    <td><%= i + 1 %></td>
                                    <td class="fw-semibold"><%= code %></td>
                                    <td><%= name %></td>
                                    <td>
                                        <% if (isBase == 1) { %>
                                            <span class="badge bg-primary"><i class="fa-solid fa-star me-1"></i>Base</span>
                                        <% } else { %>
                                            <span class="text-muted">—</span>
                                        <% } %>
                                    </td>
                                    <td><%= limitsSummary %></td>
                                    <td>
                                        <% if (isActive == 1) { %>
                                            <span class="badge bg-success">Active</span>
                                        <% } else { %>
                                            <span class="badge bg-danger">Blocked</span>
                                        <% } %>
                                    </td>
                                    <td class="text-center">
                                        <button type="button" class="btn btn-sm bb bb-outline me-1"
                                            onclick='openEditModal(<%= id %>, <%= limitsJson.toString() %>)'>
                                            <i class="fa-solid fa-pen-to-square me-1"></i>Edit
                                        </button>
                                        <% if (isActive == 1) { %>
                                            <a href="<%=contextPath%>/master/exchange/block.jsp?id=<%= id %>&action=block"
                                               class="btn btn-sm btn-outline-danger"
                                               onclick="return confirm('Block this currency?')">
                                                <i class="fa-solid fa-ban me-1"></i>Block
                                            </a>
                                        <% } else { %>
                                            <a href="<%=contextPath%>/master/exchange/block.jsp?id=<%= id %>&action=unblock"
                                               class="btn btn-sm btn-outline-success"
                                               onclick="return confirm('Unblock this currency?')">
                                                <i class="fa-solid fa-circle-check me-1"></i>Unblock
                                            </a>
                                        <% } %>
                                    </td>
                                </tr>
                                <%
                                        }
                                    } else {
                                %>
                                <tr>
                                    <td colspan="7" class="text-center py-4 text-muted">
                                        <i class="fa-solid fa-inbox fa-2x mb-2 d-block opacity-50"></i>
                                        No currencies found. Add your first currency on the left.
                                    </td>
                                </tr>
                                <%
                                    }
                                } catch (Exception e) {
                                    out.println("<tr><td colspan='7' class='text-center text-danger'>Error loading currencies: " + e.getMessage() + "</td></tr>");
                                    e.printStackTrace();
                                }
                                %>
                            </tbody>
                        </table>
                    </div>
                </div>
            </div>
        </div>
    </div>
</div>

<div class="modal fade" id="editModal" tabindex="-1" aria-hidden="true">
    <div class="modal-dialog modal-dialog-centered modal-lg">
        <div class="modal-content">
            <div class="modal-header mst-card-header">
                <h6 class="modal-title mb-0"><i class="fa-solid fa-pen-to-square me-2"></i>Edit Currency</h6>
                <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal" aria-label="Close"></button>
            </div>
            <div class="modal-body p-3">
                <form id="editForm" action="<%=contextPath%>/master/exchange/update.jsp" method="post">
                    <input type="hidden" name="currencyId" id="editCurrencyId">

                    <div class="row g-3">
                        <div class="col-md-6">
                            <label class="form-label fw-semibold">Currency Code</label>
                            <input type="text" name="currencyCode" id="editCurrencyCode" class="form-control fg-inp text-uppercase" maxlength="10" required>
                        </div>
                        <div class="col-md-6">
                            <label class="form-label fw-semibold">Currency Name</label>
                            <input type="text" name="currencyName" id="editCurrencyName" class="form-control fg-inp" maxlength="100" required>
                        </div>
                    </div>

                    <div class="mb-3 mt-3">
                        <div class="form-check">
                            <input type="checkbox" class="form-check-input" name="isBase" id="editIsBase" value="1">
                            <label class="form-check-label fw-semibold" for="editIsBase">Base Currency</label>
                        </div>
                        <small class="text-muted d-block mt-1" id="editBaseHint"></small>
                    </div>

                    <div id="editLimitsContainer" class="mt-3"></div>

                    <div class="d-flex gap-2 justify-content-end mt-3">
                        <button type="button" class="bb bb-outline" data-bs-dismiss="modal">
                            <i class="fa-solid fa-xmark me-1"></i>Cancel
                        </button>
                        <button type="submit" class="bb bb-primary">
                            <i class="fa-solid fa-floppy-disk me-1"></i>Update
                        </button>
                    </div>
                </form>
            </div>
        </div>
    </div>
</div>

<script>
    const allCurrenciesData = [
        <%
        if (allCurrencies != null) {
            for (int i = 0; i < allCurrencies.size(); i++) {
                Vector row = (Vector) allCurrencies.get(i);
                if (i > 0) out.print(",");
                out.print("{");
                out.print("\"id\":" + row.elementAt(0) + ",");
                out.print("\"code\":\"" + row.elementAt(1).toString().replace("\"", "\\\"") + "\",");
                out.print("\"name\":\"" + row.elementAt(2).toString().replace("\"", "\\\"") + "\",");
                out.print("\"isBase\":" + row.elementAt(4));
                out.print("}");
            }
        }
        %>
    ];

    const hasBaseCurrency = <%= hasBaseCurrency ? "true" : "false" %>;
    const baseCurrencyId = <%= baseCurrencyId %>;
    const baseCurrencyCode = '<%= baseCurrencyCode.replace("'", "\\'") %>';
    const baseCurrencyName = '<%= baseCurrencyName.replace("'", "\\'") %>';

    function toggleAddBaseLimitSection() {
        const section = document.getElementById('addBaseLimitSection');
        if (!section) return;
        const isBaseChecked = document.getElementById('addIsBase') && document.getElementById('addIsBase').checked;
        section.style.display = isBaseChecked ? 'none' : 'block';
        section.querySelectorAll('.ref-limit-input').forEach(function(inp) {
            inp.required = !isBaseChecked;
            inp.disabled = isBaseChecked;
        });
    }

    function openEditModal(id, savedLimits) {
        const currency = allCurrenciesData.find(function(item) { return item.id === id; });
        if (!currency) return;

        document.getElementById('editCurrencyId').value = id;
        document.getElementById('editCurrencyCode').value = currency.code;
        document.getElementById('editCurrencyName').value = currency.name;

        const editIsBase = document.getElementById('editIsBase');
        const editBaseHint = document.getElementById('editBaseHint');
        const isThisBase = currency.isBase === 1;
        const canSetBase = isThisBase || !hasBaseCurrency;

        editIsBase.checked = isThisBase;
        editIsBase.disabled = !canSetBase;

        if (isThisBase) {
            editBaseHint.textContent = 'This is the current base currency. Uncheck to remove base status.';
        } else if (hasBaseCurrency) {
            editBaseHint.textContent = 'Another currency is already set as base. Only one base currency is allowed.';
        } else {
            editBaseHint.textContent = 'Mark this as the base currency for exchange transactions.';
        }

        const limitsMap = {};
        (savedLimits || []).forEach(function(item) {
            limitsMap[item.refId] = item;
        });

        const container = document.getElementById('editLimitsContainer');
        container.innerHTML = '';

        if (isThisBase || baseCurrencyId <= 0) {
            container.innerHTML = '<div class="text-muted small">Base currency does not need exchange limits. Limits are set on other currencies against the base.</div>';
        } else {
            const saved = limitsMap[baseCurrencyId] || { min: '', max: '' };
            let html = '<label class="form-label fw-semibold">Exchange Limit vs Base Currency</label>';
            html += '<small class="text-muted d-block mb-2">Min / max rate for ' + currency.code + ' against ' + baseCurrencyCode + ' (base).</small>';
            html += '<div class="limit-block">';
            html += '<div class="limit-block-title">' + baseCurrencyCode + ' — ' + baseCurrencyName + '</div>';
            html += '<input type="hidden" name="refCurrencyId" value="' + baseCurrencyId + '">';
            html += '<div class="limit-direction">' + currency.code + ' &rarr; ' + baseCurrencyCode + '</div>';
            html += '<div class="row g-2">';
            html += '<div class="col-6"><label class="form-label small mb-1">Min Value</label>';
            html += '<input type="number" step="0.0001" min="0" name="refMin" class="form-control fg-inp" value="' + saved.min + '" required></div>';
            html += '<div class="col-6"><label class="form-label small mb-1">Max Value</label>';
            html += '<input type="number" step="0.0001" min="0" name="refMax" class="form-control fg-inp" value="' + saved.max + '" required></div>';
            html += '</div></div>';
            container.innerHTML = html;
        }

        var modal = new bootstrap.Modal(document.getElementById('editModal'));
        modal.show();
    }

    var addCurrencyCodeInput = document.querySelector('#addCurrencyForm input[name="currencyCode"]');
    if (addCurrencyCodeInput) {
        addCurrencyCodeInput.addEventListener('input', function() {
            const code = this.value.trim().toUpperCase() || 'New Currency';
            document.querySelectorAll('.new-to-ref-label').forEach(function(el) {
                el.innerHTML = code + ' &rarr; ' + el.getAttribute('data-ref-code');
            });
        });
    }

    var addIsBase = document.getElementById('addIsBase');
    if (addIsBase) {
        addIsBase.addEventListener('change', toggleAddBaseLimitSection);
        toggleAddBaseLimitSection();
    }
</script>
</body>
</html>
