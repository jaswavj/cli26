<%@ page import="java.sql.*" %>
<%
String orderId = request.getParameter("orderId");
String tableId = request.getParameter("tableId");

Connection conn = null;
PreparedStatement ps = null;

try {
    conn = util.DBConnectionManager.getConnectionFromPool();
    conn.setAutoCommit(false);
    
    // Mark order as billed
    String sql = "UPDATE prod_order SET is_billed = 1 WHERE id = ?";
    ps = conn.prepareStatement(sql);
    ps.setInt(1, Integer.parseInt(orderId));
    ps.executeUpdate();
    ps.close();
    
    // Free up the table
    sql = "UPDATE order_tables SET is_occupied = 0 WHERE id = ?";
    ps = conn.prepareStatement(sql);
    ps.setInt(1, Integer.parseInt(tableId));
    ps.executeUpdate();
    
    conn.commit();
    out.print("success");
    
} catch(Exception e) {
    if(conn != null) {
        try { conn.rollback(); } catch(Exception ex) {}
    }
    out.print("error: " + e.getMessage());
} finally {
    if(ps != null) try { ps.close(); } catch(Exception e) { }
    if(conn != null) {
        try { conn.setAutoCommit(true); } catch(Exception e) { }
        try { conn.close(); } catch(Exception e) { }
    }
}
%>
