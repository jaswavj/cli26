<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page language="java" import="java.util.*"%>
<jsp:useBean id="customer" class="currency.currencyBean" />
<%
Integer userId = (Integer) session.getAttribute("userId");
if (userId == null) {
    response.sendRedirect(request.getContextPath() + "/index.jsp");
    return;
}
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Customer Master</title>
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <%@ include file="/assets/common/head.jsp" %>
    <style>
        .table td, .table th { vertical-align: middle; }
        .badge { padding: 0.35em 0.65em; }
    </style>
</head>
<body>
    <%@ include file="/assets/navbar/navbar.jsp" %>
<%
    request.setAttribute("pageTitle",    "Customer Master");
    request.setAttribute("pageSubtitle", "Customer Management — Customer Master");
    request.setAttribute("pageIcon",     "fa-solid fa-users");
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
                    <h6 class="mb-0"><i class="fa-solid fa-user-plus me-2"></i>Add Customer</h6>
                </div>
                <div class="card-body p-3">
                    <form action="<%=contextPath%>/customer/master/save.jsp" method="post">
                        <div class="mb-3">
                            <label class="form-label fw-semibold">Customer Name <span class="text-danger">*</span></label>
                            <input type="text" name="customerName" class="form-control fg-inp" placeholder="Enter customer name" maxlength="150" required>
                        </div>
                        <div class="mb-3">
                            <label class="form-label fw-semibold">Phone Number</label>
                            <input type="text" name="phoneNumber" class="form-control fg-inp" placeholder="Optional" maxlength="20">
                        </div>
                        <div class="mb-3">
                            <label class="form-label fw-semibold">Address</label>
                            <textarea name="address" class="form-control fg-inp" rows="3" placeholder="Optional"></textarea>
                        </div>
                        <div class="mb-3">
                            <label class="form-label fw-semibold">Notes</label>
                            <textarea name="notes" class="form-control fg-inp" rows="2" placeholder="Optional"></textarea>
                        </div>
                        <button type="submit" class="bb bb-primary w-100">
                            <i class="fa-solid fa-floppy-disk me-1"></i>Save Customer
                        </button>
                    </form>
                </div>
            </div>
        </div>

        <div class="col-lg-8">
            <div class="card mst-card">
                <div class="mst-card-header">
                    <h6 class="mb-0"><i class="fa-solid fa-list me-2"></i>Customer List</h6>
                </div>
                <div class="card-body p-0">
                    <div class="table-responsive">
                        <table class="table mst-table table-hover mb-0">
                            <thead>
                                <tr>
                                    <th>#</th>
                                    <th>Name</th>
                                    <th>Phone</th>
                                    <th>Address</th>
                                    <th>Notes</th>
                                    <th>Status</th>
                                    <th class="text-center">Actions</th>
                                </tr>
                            </thead>
                            <tbody>
                                <%
                                try {
                                    Vector vec = customer.getCustomerList();
                                    if (vec != null && vec.size() > 0) {
                                        for (int i = 0; i < vec.size(); i++) {
                                            Vector row = (Vector) vec.get(i);
                                            int id = Integer.parseInt(row.elementAt(0).toString());
                                            String name = row.elementAt(1).toString();
                                            String phone = row.elementAt(2) != null ? row.elementAt(2).toString() : "-";
                                            String address = row.elementAt(3) != null ? row.elementAt(3).toString() : "-";
                                            String notes = row.elementAt(4) != null ? row.elementAt(4).toString() : "-";
                                            int isActive = Integer.parseInt(row.elementAt(5).toString());
                                %>
                                <tr>
                                    <td><%= i + 1 %></td>
                                    <td class="fw-semibold"><%= name %></td>
                                    <td><%= phone %></td>
                                    <td><%= address.length() > 40 ? address.substring(0, 40) + "..." : address %></td>
                                    <td><%= notes.length() > 30 ? notes.substring(0, 30) + "..." : notes %></td>
                                    <td>
                                        <% if (isActive == 1) { %>
                                            <span class="badge bg-success">Active</span>
                                        <% } else { %>
                                            <span class="badge bg-danger">Blocked</span>
                                        <% } %>
                                    </td>
                                    <td class="text-center">
                                        <button type="button" class="btn btn-sm bb bb-outline me-1 btn-edit-customer"
                                            data-id="<%= id %>"
                                            data-name="<%= name.replace("\"", "&quot;") %>"
                                            data-phone="<%= phone.equals("-") ? "" : phone.replace("\"", "&quot;") %>"
                                            data-address="<%= address.equals("-") ? "" : address.replace("\"", "&quot;") %>"
                                            data-notes="<%= notes.equals("-") ? "" : notes.replace("\"", "&quot;") %>">
                                            <i class="fa-solid fa-pen-to-square me-1"></i>Edit
                                        </button>
                                        <% if (isActive == 1) { %>
                                            <a href="<%=contextPath%>/customer/master/block.jsp?id=<%= id %>&action=block"
                                               class="btn btn-sm btn-outline-danger"
                                               onclick="return confirm('Block this customer?')">
                                                <i class="fa-solid fa-ban me-1"></i>Block
                                            </a>
                                        <% } else { %>
                                            <a href="<%=contextPath%>/customer/master/block.jsp?id=<%= id %>&action=unblock"
                                               class="btn btn-sm btn-outline-success"
                                               onclick="return confirm('Unblock this customer?')">
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
                                        No customers found. Add your first customer on the left.
                                    </td>
                                </tr>
                                <%
                                    }
                                } catch (Exception e) {
                                    out.println("<tr><td colspan='7' class='text-center text-danger'>Error loading customers: " + e.getMessage() + "</td></tr>");
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
                <h6 class="modal-title mb-0"><i class="fa-solid fa-pen-to-square me-2"></i>Edit Customer</h6>
                <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal" aria-label="Close"></button>
            </div>
            <div class="modal-body p-3">
                <form action="<%=contextPath%>/customer/master/update.jsp" method="post">
                    <input type="hidden" name="customerId" id="editCustomerId">
                    <div class="mb-3">
                        <label class="form-label fw-semibold">Customer Name <span class="text-danger">*</span></label>
                        <input type="text" name="customerName" id="editCustomerName" class="form-control fg-inp" maxlength="150" required>
                    </div>
                    <div class="mb-3">
                        <label class="form-label fw-semibold">Phone Number</label>
                        <input type="text" name="phoneNumber" id="editPhoneNumber" class="form-control fg-inp" maxlength="20">
                    </div>
                    <div class="mb-3">
                        <label class="form-label fw-semibold">Address</label>
                        <textarea name="address" id="editAddress" class="form-control fg-inp" rows="3"></textarea>
                    </div>
                    <div class="mb-3">
                        <label class="form-label fw-semibold">Notes</label>
                        <textarea name="notes" id="editNotes" class="form-control fg-inp" rows="2"></textarea>
                    </div>
                    <div class="d-flex gap-2 justify-content-end">
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
    document.querySelectorAll('.btn-edit-customer').forEach(function(btn) {
        btn.addEventListener('click', function() {
            document.getElementById('editCustomerId').value = btn.dataset.id;
            document.getElementById('editCustomerName').value = btn.dataset.name || '';
            document.getElementById('editPhoneNumber').value = btn.dataset.phone || '';
            document.getElementById('editAddress').value = btn.dataset.address || '';
            document.getElementById('editNotes').value = btn.dataset.notes || '';
            var modal = new bootstrap.Modal(document.getElementById('editModal'));
            modal.show();
        });
    });
</script>
</body>
</html>
