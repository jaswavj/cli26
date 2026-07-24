<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page language="java" import="java.math.BigDecimal"%>
<jsp:useBean id="exchange" class="currency.exchangeBean" />
<%
Integer userId = (Integer) session.getAttribute("userId");
if (userId == null) {
    response.sendRedirect(request.getContextPath() + "/index.jsp");
    return;
}

int currencyId = Integer.parseInt(request.getParameter("currencyId"));
int adjustmentType = Integer.parseInt(request.getParameter("adjustmentType"));
BigDecimal quantity = new BigDecimal(request.getParameter("quantity").trim());
String reason = request.getParameter("reason");

try {
    exchange.adjustStock(currencyId, adjustmentType, quantity, reason, userId);
    response.sendRedirect(request.getContextPath() + "/exchange/report/stockReport.jsp?msg=Stock+adjusted+successfully&type=success");
} catch (Exception e) {
    e.printStackTrace();
    response.sendRedirect(request.getContextPath() + "/exchange/report/stockReport.jsp?msg=Error:+"
        + java.net.URLEncoder.encode(e.getMessage(), "UTF-8") + "&type=danger");
}
%>
