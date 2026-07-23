<%@ page contentType="application/json; charset=UTF-8" %>
<%@ page import="java.util.*, org.json.*" %>
<jsp:useBean id="prod" class="product.productBean" />

<%
    String searchKey = request.getParameter("term");   // same name used in AJAX

    Vector productList = prod.getProductList(searchKey);

    JSONArray jsonArray = new JSONArray();
    if (productList != null) {
        for (Object item : productList) {
            jsonArray.put(item.toString());
        }
    }

    out.print(jsonArray.toString());
%>
