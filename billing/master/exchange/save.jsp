<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page language="java" import="java.math.BigDecimal"%>
<jsp:useBean id="currency" class="currency.currencyBean" />
<%
String currencyCode = request.getParameter("currencyCode");
String currencyName = request.getParameter("currencyName");
String[] refCurrencyIds = request.getParameterValues("refCurrencyId");
String[] refMins = request.getParameterValues("refMin");
String[] refMaxs = request.getParameterValues("refMax");

try {
    if (currencyCode == null || currencyCode.trim().isEmpty()) {
        response.sendRedirect(request.getContextPath() + "/master/exchange/page.jsp?msg=Currency+code+is+required&type=danger");
        return;
    }
    if (currencyName == null || currencyName.trim().isEmpty()) {
        response.sendRedirect(request.getContextPath() + "/master/exchange/page.jsp?msg=Currency+name+is+required&type=danger");
        return;
    }

    int existingId = currency.checkCurrencyCodeExists(currencyCode, 0);
    if (existingId != 0) {
        response.sendRedirect(request.getContextPath() + "/master/exchange/page.jsp?msg=Currency+code+already+exists&type=warning");
        return;
    }

    boolean isBase = "1".equals(request.getParameter("isBase"));
    boolean isBank = "1".equals(request.getParameter("isBank"));

    if (isBase && currency.hasBaseCurrency()) {
        response.sendRedirect(request.getContextPath() + "/master/exchange/page.jsp?msg=Only+one+base+currency+is+allowed&type=warning");
        return;
    }

    if (isBank && currency.hasBankCurrency()) {
        response.sendRedirect(request.getContextPath() + "/master/exchange/page.jsp?msg=Only+one+bank+currency+is+allowed&type=warning");
        return;
    }

    if (!isBase && currency.hasBaseCurrency()) {
        if (refCurrencyIds == null || refCurrencyIds.length == 0
                || refMins == null || refMaxs == null
                || refMins.length != refCurrencyIds.length || refMaxs.length != refCurrencyIds.length) {
            response.sendRedirect(request.getContextPath() + "/master/exchange/page.jsp?msg=Please+enter+min+and+max+vs+base+currency&type=warning");
            return;
        }
        for (int i = 0; i < refCurrencyIds.length; i++) {
            BigDecimal minValue = new BigDecimal(refMins[i].trim());
            BigDecimal maxValue = new BigDecimal(refMaxs[i].trim());
            if (minValue.compareTo(maxValue) > 0) {
                response.sendRedirect(request.getContextPath() + "/master/exchange/page.jsp?msg=Minimum+value+cannot+be+greater+than+maximum+value&type=warning");
                return;
            }
        }
    }

    int newId = currency.addCurrency(currencyCode, currencyName, isBase, isBank);

    if (!isBase && refCurrencyIds != null && refCurrencyIds.length > 0) {
        int[] refIds = new int[refCurrencyIds.length];
        BigDecimal[] mins = new BigDecimal[refCurrencyIds.length];
        BigDecimal[] maxs = new BigDecimal[refCurrencyIds.length];

        for (int i = 0; i < refCurrencyIds.length; i++) {
            refIds[i] = Integer.parseInt(refCurrencyIds[i]);
            mins[i] = new BigDecimal(refMins[i].trim());
            maxs[i] = new BigDecimal(refMaxs[i].trim());
        }

        currency.saveCurrencyLimits(newId, refIds, mins, maxs);
    }

    response.sendRedirect(request.getContextPath() + "/master/exchange/page.jsp?msg=Currency+added+successfully&type=success");
} catch (Exception e) {
    e.printStackTrace();
    response.sendRedirect(request.getContextPath() + "/master/exchange/page.jsp?msg=Error:+"
        + java.net.URLEncoder.encode(e.getMessage(), "UTF-8") + "&type=danger");
}
%>
