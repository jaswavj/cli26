<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page language="java" import="java.util.*"%>
<%
Integer userId = (Integer) session.getAttribute("userId");
if (userId == null) {
    response.sendRedirect(request.getContextPath() + "/index.jsp");
    return;
}
String msg = request.getParameter("msg");
String type = request.getParameter("type");
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Additional Income</title>
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <%@ include file="/assets/common/head.jsp" %>
</head>
<body>
    <%@ include file="/assets/navbar/navbar.jsp" %>
<%
    request.setAttribute("pageTitle", "Additional Income");
    request.setAttribute("pageSubtitle", "Record income in base currency");
    request.setAttribute("pageIcon", "fa-solid fa-coins");
%>
<jsp:include page="/assets/common/pageHeader.jsp" />

<div class="container-fluid mt-3 mst-page" style="max-width:900px;">
<% if (msg != null) { %>
<div class="alert alert-<%= (type != null ? type : "info") %> alert-dismissible fade show mb-3" role="alert">
    <%= msg %>
    <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Close"></button>
</div>
<% } %>
    <div class="card mst-card">
        <div class="mst-card-header">
            <h5 class="mb-0"><i class="fa-solid fa-coins me-2"></i>Additional Income Entry</h5>
        </div>
        <div class="card-body p-4">
            <form action="<%=request.getContextPath()%>/income/additionalIncome/save.jsp" method="post" onsubmit="return validateIncomeForm()">
                <div class="mb-3">
                    <label class="form-label fw-semibold">Particular</label>
                    <input type="text" name="particular" id="particular" class="form-control fg-inp" placeholder="Enter income particular" required>
                </div>
                <div class="mb-3">
                    <label class="form-label fw-semibold">Income Amount (Base Currency)</label>
                    <input type="number" step="0.0001" min="0.0001" name="amount" id="amount" class="form-control fg-inp" placeholder="0.0000" required>
                </div>
                <div class="mb-3">
                    <label class="form-label fw-semibold">Description</label>
                    <textarea name="description" id="description" class="form-control fg-inp" rows="4" placeholder="Optional notes"></textarea>
                </div>
                <div class="d-flex gap-2 justify-content-end mt-4">
                    <button type="reset" class="bb bb-outline">
                        <i class="fa-solid fa-rotate-left me-2"></i>Reset
                    </button>
                    <button type="submit" class="bb bb-primary">
                        <i class="fa-solid fa-floppy-disk me-2"></i>Save Income
                    </button>
                </div>
            </form>
        </div>
    </div>
</div>

<script>
    function validateIncomeForm() {
        const particular = document.getElementById('particular').value.trim();
        const amount = parseFloat(document.getElementById('amount').value);
        if (!particular) {
            alert('Please enter particular');
            return false;
        }
        if (isNaN(amount) || amount <= 0) {
            alert('Please enter a valid income amount');
            return false;
        }
        return true;
    }
</script>
<br><br><br><br><br>
</body>
</html>
