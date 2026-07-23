<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page language="java" import= "java.util.*"%>
<%@ page errorPage="" %>
<jsp:useBean id="prod" class="product.productBean" />
<%

// Session check
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
    <title>Expense Type - Billing App</title>
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <!-- Bootstrap CSS -->
    <%@ include file="/assets/common/head.jsp" %>

</head>
<body>
    <%@ include file="/assets/navbar/navbar.jsp" %>
<%
    request.setAttribute("pageTitle",    "Expense Types");
    request.setAttribute("pageSubtitle", "Manage expense categories");
    request.setAttribute("pageIcon",     "fa-solid fa-tags");
%>
<jsp:include page="/assets/common/pageHeader.jsp" />

<div class="container-fluid mt-3 mst-page">
<%
String msg = request.getParameter("msg");
String type = request.getParameter("type");
%>
<% if (msg != null) { %>
<div class="alert alert-<%= (type != null ? type : "info") %> alert-dismissible fade show mb-3" role="alert">
  <%= msg %>
  <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Close"></button>
</div>
<% } %>
        <div class="row g-3">
            <!-- Left Column - Add Expense Type Form -->
            <div class="col-md-7">
                <div class="card mst-card h-100">
                    <div class="mst-card-header">
                        <h6 class="mb-0"><i class="fa-solid fa-plus-circle me-2"></i>Add New Expense Type</h6>
                    </div>
                    <div class="card-body p-3">
                        <form action="<%=contextPath%>/expense/expenseType/saveExpenseType.jsp" method="post">
                            <div class="mb-3">
                                <label class="form-label fw-semibold">Expense Type Name</label>
                                <input type="text" name="expenseTypeName" class="form-control fg-inp" placeholder="Enter expense type name" required>
                            </div>
                            <button type="submit" class="bb bb-primary w-100">
                                <i class="fa-solid fa-floppy-disk me-1"></i>Add Expense Type
                            </button>
                        </form>
                    </div>
                </div>
            </div>

            <!-- Right Column - Expense Type List Table -->
            <div class="col-md-5">
                <div class="card mst-card">
                    <div class="mst-card-header">
                        <h6 class="mb-0"><i class="fa-solid fa-list me-2"></i>Expense Type List</h6>
                    </div>
                    <div class="card-body p-0">

                <table class="table mst-table table-sm mb-0">
                    <thead>
                        <tr>
                            <th>#</th>
                            <th><i class="fa-solid fa-tag me-1"></i>Name</th>
                            <th class="text-center"><i class="fa-solid fa-gear me-1"></i>Actions</th>
                        </tr>
                    </thead>
                    <tbody>

                        <%
                        try {
                            Vector vec = prod.getExpenseTypeList();
                            if (vec != null && vec.size() > 0) {
                                for (int i = 0; i < vec.size(); i++) {
                                    Vector vec1 = (Vector) vec.get(i); // inner vector (row)
                                    if (vec1 == null || vec1.elementAt(0) == null || vec1.elementAt(1) == null) {
                                        continue; // Skip null entries
                                    }
                                    String typeName = vec1.elementAt(0).toString();
                                    int typeId = Integer.parseInt(vec1.elementAt(1).toString());
                        %>
                        <tr>
                            <td><%=i+1%></td>
                            <td class="fw-medium"><%=typeName%></td>
                            <td class="text-center">
                                <button onclick="openEditModal('<%=typeName.replace("'", "\\'" )%>', <%=typeId%>)" class="btn btn-sm bb bb-outline">
                                    <i class="fa-solid fa-pen-to-square me-1"></i>Edit
                                </button>
                            </td>
                        </tr>
                        <%
                                }
                            } else {
                        %>
                        <tr>
                            <td colspan="3" class="text-center py-4 text-muted">
                                <i class="fa-solid fa-inbox fa-2x mb-2 d-block opacity-50"></i>
                                No expense types found. Add your first expense type above.
                            </td>
                        </tr>
                        <%
                            }
                        } catch (Exception e) {
                            out.println("<tr><td colspan='3' class='text-center text-danger'>Error loading expense types: " + e.getMessage() + "</td></tr>");
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

    <!-- Edit Expense Type Modal -->
    <div class="modal fade" id="editModal" tabindex="-1" aria-hidden="true">
        <div class="modal-dialog modal-dialog-centered">
            <div class="modal-content">
                <div class="modal-header mst-card-header">
                    <h6 class="modal-title mb-0"><i class="fa-solid fa-pen-to-square me-2"></i>Edit Expense Type</h6>
                    <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
                </div>
                <div class="modal-body p-3">
                    <form id="editForm" action="<%=contextPath%>/expense/expenseType/editExpenseType.jsp" method="post">
                        <input type="hidden" name="expenseTypeId" id="editExpenseTypeId">
                        
                        <div class="mb-3">
                            <label class="form-label fw-semibold">Current Name</label>
                            <input type="text" id="currentName" class="form-control fg-inp" disabled>
                        </div>
                        
                        <div class="mb-3">
                            <label class="form-label fw-semibold">New Expense Type Name</label>
                            <input type="text" name="newExpenseType" id="editExpenseTypeName" class="form-control fg-inp" placeholder="Enter new name" required>
                        </div>
                        
                        <div class="mb-3">
                            <div class="form-check p-2 rounded" style="background:#fff5f5; border-left:3px solid var(--bill-red);">
                                <input class="form-check-input" type="checkbox" name="block" value="block" id="editBlock">
                                <label class="form-check-label fw-medium" for="editBlock" style="color:var(--bill-red);">
                                    <i class="fa-solid fa-triangle-exclamation me-1"></i>Block this expense type
                                </label>
                            </div>
                            <small class="text-muted mt-1 d-block">Blocking will make this expense type unavailable for selection</small>
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
        function openEditModal(typeName, typeId) {
            document.getElementById('currentName').value = typeName;
            document.getElementById('editExpenseTypeName').value = typeName;
            document.getElementById('editExpenseTypeId').value = typeId;
            
            // Reset checkbox
            document.getElementById('editBlock').checked = false;
            
            var modal = new bootstrap.Modal(document.getElementById('editModal'));
            modal.show();
        }
    </script>

</body>
</html>
