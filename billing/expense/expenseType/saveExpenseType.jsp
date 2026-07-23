<%@page language="java" import="java.util.*" %>
<jsp:useBean id="prod" class="product.productBean" />

<%
String expenseTypeName = request.getParameter("expenseTypeName");

try {
    int typeId = prod.checkExpenseTypeExist(expenseTypeName);

    if (typeId != 0) {
        response.sendRedirect(request.getContextPath() + "/expense/expenseType/expenseType.jsp?msg=Expense+type+already+exists!&type=warning");
        return;
    } else {
        prod.addExpenseType(expenseTypeName);
        response.sendRedirect(request.getContextPath() + "/expense/expenseType/expenseType.jsp?msg=Expense+type+added+successfully!&type=success");
        return;
    }
} catch (Exception e) {
    response.sendRedirect(
        "expenseType.jsp?msg=Error+occurred+while+inserting+expense+type:+"
        + java.net.URLEncoder.encode(e.getMessage(), "UTF-8")
        + "&type=danger"
    );
}
%>
