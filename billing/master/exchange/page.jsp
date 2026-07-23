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

                        <% if (allCurrencies != null && allCurrencies.size() > 0) { %>
                        <div class="mb-3">
                            <label class="form-label fw-semibold">Exchange Limits vs Existing Currencies</label>
                            <small class="text-muted d-block mb-2">Enter min and max values of the new currency against each currency already in the table.</small>
                            <%
                            for (int i = 0; i < allCurrencies.size(); i++) {
                                Vector existing = (Vector) allCurrencies.get(i);
                                int refId = Integer.parseInt(existing.elementAt(0).toString());
                                String refCode = existing.elementAt(1).toString();
                                String refName = existing.elementAt(2).toString();
                            %>
                            <div class="limit-block">
                                <div class="limit-block-title"><%= refCode %> — <%= refName %></div>
                                <input type="hidden" name="refCurrencyId" value="<%= refId %>">
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
                            <%
                            }
                            %>
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
                                            String limitsSummary = currency.getCurrencyLimitsSummary(id);

                                            StringBuilder limitsJson = new StringBuilder("[");
                                            Vector limits = currency.getCurrencyLimits(id);
                                            for (int j = 0; j < limits.size(); j++) {
                                                Vector limitRow = (Vector) limits.get(j);
                                                if (j > 0) limitsJson.append(",");
                                                limitsJson.append("{")
                                                    .append("\"refId\":").append(limitRow.elementAt(0))
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
                                    <td colspan="6" class="text-center py-4 text-muted">
                                        <i class="fa-solid fa-inbox fa-2x mb-2 d-block opacity-50"></i>
                                        No currencies found. Add your first currency on the left.
                                    </td>
                                </tr>
                                <%
                                    }
                                } catch (Exception e) {
                                    out.println("<tr><td colspan='6' class='text-center text-danger'>Error loading currencies: " + e.getMessage() + "</td></tr>");
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
                out.print("\"name\":\"" + row.elementAt(2).toString().replace("\"", "\\\"") + "\"");
                out.print("}");
            }
        }
        %>
    ];

    function openEditModal(id, savedLimits) {
        const currency = allCurrenciesData.find(function(item) { return item.id === id; });
        if (!currency) return;

        document.getElementById('editCurrencyId').value = id;
        document.getElementById('editCurrencyCode').value = currency.code;
        document.getElementById('editCurrencyName').value = currency.name;

        const limitsMap = {};
        (savedLimits || []).forEach(function(item) {
            limitsMap[item.refId] = item;
        });

        const container = document.getElementById('editLimitsContainer');
        container.innerHTML = '';

        const otherCurrencies = allCurrenciesData.filter(function(item) { return item.id !== id; });

        if (otherCurrencies.length === 0) {
            container.innerHTML = '<div class="text-muted small">No other currencies available for exchange limits.</div>';
        } else {
            let html = '<label class="form-label fw-semibold">Exchange Limits vs Other Currencies</label>';
            html += '<small class="text-muted d-block mb-2">Update min and max values against each existing currency.</small>';

            otherCurrencies.forEach(function(ref) {
                const saved = limitsMap[ref.id] || { min: '', max: '' };
                html += '<div class="limit-block">';
                html += '<div class="limit-block-title">' + ref.code + ' — ' + ref.name + '</div>';
                html += '<input type="hidden" name="refCurrencyId" value="' + ref.id + '">';
                html += '<div class="row g-2">';
                html += '<div class="col-6">';
                html += '<label class="form-label small mb-1">Min Value</label>';
                html += '<input type="number" step="0.0001" min="0" name="refMin" class="form-control fg-inp" value="' + saved.min + '" required>';
                html += '</div>';
                html += '<div class="col-6">';
                html += '<label class="form-label small mb-1">Max Value</label>';
                html += '<input type="number" step="0.0001" min="0" name="refMax" class="form-control fg-inp" value="' + saved.max + '" required>';
                html += '</div>';
                html += '</div>';
                html += '</div>';
            });

            container.innerHTML = html;
        }

        var modal = new bootstrap.Modal(document.getElementById('editModal'));
        modal.show();
    }
</script>
</body>
</html>
