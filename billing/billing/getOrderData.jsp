<%@ page language="java" contentType="application/json; charset=UTF-8"%>
<%@ page language="java" import="java.util.*"%>
<%@ page language="java" import="java.sql.*"%>
<%@ page language="java" import="java.text.DecimalFormat"%>
<%@ page import="org.json.simple.JSONObject"%>
<%@ page import="org.json.simple.JSONArray"%>
<jsp:useBean id="userBean" class="user.userBean" scope="page"/>
<%
response.setHeader("Cache-Control", "no-cache, no-store, must-revalidate");
response.setHeader("Pragma", "no-cache");
response.setDateHeader("Expires", 0);

String orderId = request.getParameter("orderId");

JSONObject responseJson = new JSONObject();

if(orderId == null || orderId.trim().isEmpty()) {
    responseJson.put("success", false);
    responseJson.put("message", "Missing order ID");
    out.print(responseJson.toString());
    return;
}

Connection conn = null;
PreparedStatement ps = null;
ResultSet rs = null;

try {
    conn = util.DBConnectionManager.getConnectionFromPool();
    
    // Get order details
    String sql = "SELECT po.*, ot.name as table_name FROM prod_order po " +
                 "JOIN order_tables ot ON po.table_id = ot.id WHERE po.id = ?";
    ps = conn.prepareStatement(sql);
    ps.setInt(1, Integer.parseInt(orderId));
    rs = ps.executeQuery();
    
    if(!rs.next()) {
        responseJson.put("success", false);
        responseJson.put("message", "Order not found");
        out.print(responseJson.toString());
        return;
    }
    
    // Order basic info
    String orderNo = rs.getString("order_no");
    String tableName = rs.getString("table_name");
    String orderDate = rs.getString("date");
    String orderTime = rs.getString("time");
    int isDelivered = rs.getInt("is_delivered");
    
    JSONObject orderInfo = new JSONObject();
    orderInfo.put("orderId", orderId);
    orderInfo.put("orderNo", orderNo);
    orderInfo.put("tableName", tableName);
    orderInfo.put("date", orderDate);
    orderInfo.put("time", orderTime);
    orderInfo.put("isDelivered", isDelivered);
    orderInfo.put("status", isDelivered == 1 ? "Delivered" : "Pending");
    
    rs.close();
    ps.close();
    
    // Get order items
    sql = "SELECT od.*, p.prod_name FROM prod_order_details od " +
          "JOIN prod_product p ON od.prod_id = p.id WHERE od.order_id = ? ORDER BY od.id";
    ps = conn.prepareStatement(sql);
    ps.setInt(1, Integer.parseInt(orderId));
    rs = ps.executeQuery();
    
    JSONArray itemsArray = new JSONArray();
    double grandTotal = 0;
    DecimalFormat df = new DecimalFormat("0.00");
    
    while(rs.next()) {
        JSONObject item = new JSONObject();
        String prodName = rs.getString("prod_name");
        double qty = rs.getDouble("qty");
        double price = rs.getDouble("price");
        double itemTotal = qty * price;
        
        item.put("prodName", prodName);
        item.put("qty", qty);
        item.put("price", price);
        item.put("total", itemTotal);
        item.put("formattedQty", String.format("%.0f", qty));
        item.put("formattedPrice", df.format(price));
        item.put("formattedTotal", df.format(itemTotal));
        
        itemsArray.add(item);
        grandTotal += itemTotal;
    }
    
    rs.close();
    ps.close();
    
    // Get company details
    Vector companyDetails = userBean.getCompanyDetails();
    JSONObject companyInfo = new JSONObject();
    
    if (companyDetails != null && companyDetails.size() >= 2) {
        companyInfo.put("name", companyDetails.get(1) != null ? companyDetails.get(1).toString() : "");
        companyInfo.put("address", companyDetails.get(2) != null ? companyDetails.get(2).toString() : "");
        companyInfo.put("phone", companyDetails.size() > 3 && companyDetails.get(3) != null ? companyDetails.get(3).toString() : "");
        companyInfo.put("gst", companyDetails.size() > 4 && companyDetails.get(4) != null ? companyDetails.get(4).toString() : "");
    }
    
    // Totals
    JSONObject totals = new JSONObject();
    totals.put("grandTotal", grandTotal);
    totals.put("formattedGrandTotal", df.format(grandTotal));
    
    // Build response
    responseJson.put("success", true);
    responseJson.put("order", orderInfo);
    responseJson.put("company", companyInfo);
    responseJson.put("items", itemsArray);
    responseJson.put("totals", totals);
    
    out.print(responseJson.toString());
    
} catch(Exception e) {
    responseJson.put("success", false);
    responseJson.put("message", "Error: " + e.getMessage());
    e.printStackTrace();
    out.print(responseJson.toString());
} finally {
    if(rs != null) try { rs.close(); } catch(Exception e) {}
    if(ps != null) try { ps.close(); } catch(Exception e) {}
    if(conn != null) try { conn.close(); } catch(Exception e) {}
}
%>
