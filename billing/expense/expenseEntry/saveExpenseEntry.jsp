<%@page language="java" import="java.util.*" %>
<jsp:useBean id="prod" class="product.productBean" />

<%
// Session check
Integer userId = (Integer) session.getAttribute("userId");
if (userId == null) {
    response.sendRedirect(request.getContextPath() + "/index.jsp");
    return;
}

String expenseTypeParam = request.getParameter("expenseType");
String content = request.getParameter("content");
String description = request.getParameter("description");
String amountParam = request.getParameter("amount");
String expenseDate = request.getParameter("expenseDate");
String expenseTime = request.getParameter("expenseTime");

try {
    int expenseType = Integer.parseInt(expenseTypeParam);
    double amount = Double.parseDouble(amountParam);
    
    // Combine date and time
    String expenseDateTime = expenseDate + " " + expenseTime + ":00";
    
    prod.addExpenseEntry(expenseType, content, description, amount, expenseDateTime, userId);
    
    response.sendRedirect(request.getContextPath() + "/expense/expenseEntry/page.jsp?msg=Expense+entry+added+successfully!&type=success");
} catch (Exception e) {
    response.sendRedirect(
        "page.jsp?msg=Error+occurred+while+saving+expense:+"
        + java.net.URLEncoder.encode(e.getMessage(), "UTF-8")
        + "&type=danger"
    );
}
%>
