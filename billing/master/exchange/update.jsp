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

    boolean isBase = "1".equals(request.getParameter("isBase"));
    boolean isBank = "1".equals(request.getParameter("isBank"));
    int existingBaseId = currency.getBaseCurrencyId();
    int existingBankId = currency.getBankCurrencyId();

    if (isBase && existingBaseId > 0 && existingBaseId != currencyId) {
        response.sendRedirect(request.getContextPath() + "/master/exchange/page.jsp?msg=Only+one+base+currency+is+allowed&type=warning");
        return;
    }

    if (isBank && existingBankId > 0 && existingBankId != currencyId) {
        response.sendRedirect(request.getContextPath() + "/master/exchange/page.jsp?msg=Only+one+bank+currency+is+allowed&type=warning");
        return;
    }

    if (!isBase && existingBaseId > 0 && existingBaseId != currencyId) {
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

    currency.updateCurrency(currencyId, currencyCode, currencyName, isBase, isBank);

    if (!isBase && refCurrencyIds != null && refCurrencyIds.length > 0) {
        int[] refIds = new int[refCurrencyIds.length];
        BigDecimal[] mins = new BigDecimal[refCurrencyIds.length];
        BigDecimal[] maxs = new BigDecimal[refCurrencyIds.length];

        for (int i = 0; i < refCurrencyIds.length; i++) {
            refIds[i] = Integer.parseInt(refCurrencyIds[i]);
            mins[i] = new BigDecimal(refMins[i].trim());
            maxs[i] = new BigDecimal(refMaxs[i].trim());
        }

        currency.replaceCurrencyLimits(currencyId, refIds, mins, maxs);
    } else {
        currency.replaceCurrencyLimits(currencyId, new int[0], new BigDecimal[0], new BigDecimal[0]);
    }

    // Clear any old reverse / non-base pair limits for this currency
    currency.replaceReverseCurrencyLimits(currencyId, new int[0], new BigDecimal[0], new BigDecimal[0]);

    response.sendRedirect(request.getContextPath() + "/master/exchange/page.jsp?msg=Currency+updated+successfully&type=success");
} catch (Exception e) {
    e.printStackTrace();
    response.sendRedirect(request.getContextPath() + "/master/exchange/page.jsp?msg=Error:+"
        + java.net.URLEncoder.encode(e.getMessage(), "UTF-8") + "&type=danger");
}
%>
