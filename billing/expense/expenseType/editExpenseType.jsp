<%@page language="java" import="java.util.*" %>
<jsp:useBean id="prod" class="product.productBean" />

<%
String newExpenseType = request.getParameter("newExpenseType");
int expenseTypeId = Integer.parseInt(request.getParameter("expenseTypeId"));
String block = request.getParameter("block");

if (block != null) {
    prod.blockExpenseType(expenseTypeId);
    response.sendRedirect(request.getContextPath() + "/expense/expenseType/expenseType.jsp?msg=Expense+type+blocked+successfully&type=info");
    return;
}

try {
    int typeId = prod.checkExpenseTypeExist(newExpenseType);

    if (typeId != 0 && typeId != expenseTypeId) {
        response.sendRedirect(request.getContextPath() + "/expense/expenseType/expenseType.jsp?msg=Expense+type+already+exists!&type=warning");
        return;
    }

    prod.editExpenseType(expenseTypeId, newExpenseType);
    response.sendRedirect(request.getContextPath() + "/expense/expenseType/expenseType.jsp?msg=Expense+type+updated+successfully!&type=success");
} catch (Exception e) {
    response.sendRedirect(
        "expenseType.jsp?msg=Error+occurred+while+updating+expense+type:+"
        + java.net.URLEncoder.encode(e.getMessage(), "UTF-8")
        + "&type=danger"
    );
}
%>
