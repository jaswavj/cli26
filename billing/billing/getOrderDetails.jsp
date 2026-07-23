<%@ page import="java.sql.*" %>
<%@ page import="org.json.*" %>
<%
String orderId = request.getParameter("orderId");
Connection conn = null;
PreparedStatement ps = null;
ResultSet rs = null;

try {
    conn = util.DBConnectionManager.getConnectionFromPool();
    
    // Get order details
    String sql = "SELECT po.*, ot.name as table_name, ot.id as table_id FROM prod_order po " +
                 "JOIN order_tables ot ON po.table_id = ot.id WHERE po.id = ?";
    ps = conn.prepareStatement(sql);
    ps.setInt(1, Integer.parseInt(orderId));
    rs = ps.executeQuery();
    
    JSONObject orderData = new JSONObject();
    
    if(rs.next()) {
        orderData.put("orderId", rs.getInt("id"));
        orderData.put("orderNo", rs.getString("order_no"));
        orderData.put("tableName", rs.getString("table_name"));
        orderData.put("tableId", rs.getInt("table_id"));
    }
    rs.close();
    ps.close();
    
    // Get order items with batch IDs
    sql = "SELECT pod.*, p.name, p.code FROM prod_order_details pod " +
          "JOIN prod_product p ON pod.prod_id = p.id WHERE pod.order_id = ?";
    ps = conn.prepareStatement(sql);
    ps.setInt(1, Integer.parseInt(orderId));
    rs = ps.executeQuery();
    
    JSONArray items = new JSONArray();
    PreparedStatement batchPs = null;
    ResultSet batchRs = null;
    
    while(rs.next()) {
        JSONObject item = new JSONObject();
        int prodId = rs.getInt("prod_id");
        item.put("prodId", prodId);
        item.put("prodName", rs.getString("name"));
        item.put("code", rs.getString("code"));
        item.put("qty", rs.getDouble("qty"));
        item.put("price", rs.getDouble("price"));
        item.put("total", rs.getDouble("total"));
        
        // Get batch ID for this product
        int batchId = 0;
        try {
            batchPs = conn.prepareStatement("SELECT id FROM prod_batch WHERE product_id = ? AND stock > 0 ORDER BY id LIMIT 1");
            batchPs.setInt(1, prodId);
            batchRs = batchPs.executeQuery();
            if(batchRs.next()) {
                batchId = batchRs.getInt("id");
            }
            batchRs.close();
            batchPs.close();
        } catch(Exception be) {
            // If batch not found, use 0
        }
        
        item.put("batchId", batchId);
        items.put(item);
    }
    
    orderData.put("items", items);
    
    response.setContentType("application/json");
    out.print(orderData.toString());
    
} catch(Exception e) {
    JSONObject error = new JSONObject();
    error.put("error", e.getMessage());
    out.print(error.toString());
} finally {
    if(rs != null) rs.close();
    if(ps != null) ps.close();
    if(conn != null) conn.close();
}
%>
