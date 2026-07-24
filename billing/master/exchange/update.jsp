<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page language="java" import="java.math.BigDecimal"%>
<jsp:useBean id="currency" class="currency.currencyBean" />
<%
int currencyId = Integer.parseInt(request.getParameter("currencyId"));
String currencyCode = request.getParameter("currencyCode");
String currencyName = request.getParameter("currencyName");
String[] refCurrencyIds = request.getParameterValues("refCurrencyId");
String[] refMins = request.getParameterValues("refMin");
String[] refMaxs = request.getParameterValues("refMax");
String[] revMins = request.getParameterValues("revMin");
String[] revMaxs = request.getParameterValues("revMax");

try {
    if (currencyCode == null || currencyCode.trim().isEmpty() || currencyName == null || currencyName.trim().isEmpty()) {
        response.sendRedirect(request.getContextPath() + "/master/exchange/page.jsp?msg=Currency+code+and+name+are+required&type=danger");
        return;
    }

    int existingId = currency.checkCurrencyCodeExists(currencyCode, currencyId);
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
    int existingBaseId = currency.getBaseCurrencyId();

    if (isBase && existingBaseId > 0 && existingBaseId != currencyId) {
        response.sendRedirect(request.getContextPath() + "/master/exchange/page.jsp?msg=Only+one+base+currency+is+allowed&type=warning");
        return;
    }

    currency.updateCurrency(currencyId, currencyCode, currencyName, isBase);

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

        currency.replaceCurrencyLimits(currencyId, refIds, mins, maxs);
        currency.replaceReverseCurrencyLimits(currencyId, refIds, revMinValues, revMaxValues);
    } else {
        currency.replaceCurrencyLimits(currencyId, new int[0], new BigDecimal[0], new BigDecimal[0]);
        currency.replaceReverseCurrencyLimits(currencyId, new int[0], new BigDecimal[0], new BigDecimal[0]);
    }

    response.sendRedirect(request.getContextPath() + "/master/exchange/page.jsp?msg=Currency+updated+successfully&type=success");
} catch (Exception e) {
    e.printStackTrace();
    response.sendRedirect(request.getContextPath() + "/master/exchange/page.jsp?msg=Error:+"
        + java.net.URLEncoder.encode(e.getMessage(), "UTF-8") + "&type=danger");
}
%>
