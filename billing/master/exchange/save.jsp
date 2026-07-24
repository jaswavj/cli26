<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page language="java" import="java.math.BigDecimal"%>
<jsp:useBean id="currency" class="currency.currencyBean" />
<%
String currencyCode = request.getParameter("currencyCode");
String currencyName = request.getParameter("currencyName");
String[] refCurrencyIds = request.getParameterValues("refCurrencyId");
String[] refMins = request.getParameterValues("refMin");
String[] refMaxs = request.getParameterValues("refMax");
String[] revMins = request.getParameterValues("revMin");
String[] revMaxs = request.getParameterValues("revMax");

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

    if (refCurrencyIds != null && refCurrencyIds.length > 0) {
        if (refMins == null || refMaxs == null || revMins == null || revMaxs == null
                || refMins.length != refCurrencyIds.length || refMaxs.length != refCurrencyIds.length
                || revMins.length != refCurrencyIds.length || revMaxs.length != refCurrencyIds.length) {
            response.sendRedirect(request.getContextPath() + "/master/exchange/page.jsp?msg=Please+enter+all+exchange+limits&type=warning");
            return;
        }

        for (int i = 0; i < refCurrencyIds.length; i++) {
            BigDecimal minValue = new BigDecimal(refMins[i].trim());
            BigDecimal maxValue = new BigDecimal(refMaxs[i].trim());
            if (minValue.compareTo(maxValue) > 0) {
                response.sendRedirect(request.getContextPath() + "/master/exchange/page.jsp?msg=Minimum+value+cannot+be+greater+than+maximum+value&type=warning");
                return;
            }

            BigDecimal revMinValue = new BigDecimal(revMins[i].trim());
            BigDecimal revMaxValue = new BigDecimal(revMaxs[i].trim());
            if (revMinValue.compareTo(revMaxValue) > 0) {
                response.sendRedirect(request.getContextPath() + "/master/exchange/page.jsp?msg=Minimum+value+cannot+be+greater+than+maximum+value&type=warning");
                return;
            }
        }
    }

    boolean isBase = "1".equals(request.getParameter("isBase"));

    if (isBase && currency.hasBaseCurrency()) {
        response.sendRedirect(request.getContextPath() + "/master/exchange/page.jsp?msg=Only+one+base+currency+is+allowed&type=warning");
        return;
    }

    int newId = currency.addCurrency(currencyCode, currencyName, isBase);

    if (refCurrencyIds != null && refCurrencyIds.length > 0) {
        int[] refIds = new int[refCurrencyIds.length];
        BigDecimal[] mins = new BigDecimal[refCurrencyIds.length];
        BigDecimal[] maxs = new BigDecimal[refCurrencyIds.length];
        BigDecimal[] revMinValues = new BigDecimal[refCurrencyIds.length];
        BigDecimal[] revMaxValues = new BigDecimal[refCurrencyIds.length];

        for (int i = 0; i < refCurrencyIds.length; i++) {
            refIds[i] = Integer.parseInt(refCurrencyIds[i]);
            mins[i] = new BigDecimal(refMins[i].trim());
            maxs[i] = new BigDecimal(refMaxs[i].trim());
            revMinValues[i] = new BigDecimal(revMins[i].trim());
            revMaxValues[i] = new BigDecimal(revMaxs[i].trim());
        }

        currency.saveCurrencyLimits(newId, refIds, mins, maxs);
        currency.saveReverseCurrencyLimits(newId, refIds, revMinValues, revMaxValues);
    }

    response.sendRedirect(request.getContextPath() + "/master/exchange/page.jsp?msg=Currency+added+successfully&type=success");
} catch (Exception e) {
    e.printStackTrace();
    response.sendRedirect(request.getContextPath() + "/master/exchange/page.jsp?msg=Error:+"
        + java.net.URLEncoder.encode(e.getMessage(), "UTF-8") + "&type=danger");
}
%>
