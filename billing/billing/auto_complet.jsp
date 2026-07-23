<%@ page import="java.util.*" %>
<jsp:useBean id="prod" class="product.productBean" />
<%
    String keyword = request.getParameter("productSearch");
    Vector vec = prod.getProductBySearch(keyword);

    StringBuilder json = new StringBuilder("[");
    for (int i = 0; i < vec.size(); i++) {
        Vector vec1 = (Vector) vec.elementAt(i);
        String id = vec1.elementAt(0).toString();     // catId
        String name = vec1.elementAt(1).toString();   // catName

        json.append("{\"label\":\"").append(name).append("\",\"value\":\"").append(id).append("\"}");
        if (i < vec.size() - 1) json.append(",");
    }
    json.append("]");
    out.print(json.toString());
%>
