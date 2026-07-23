<%@ page import="java.sql.*" %>
<%
Connection conn = null;
PreparedStatement ps = null;
ResultSet rs = null;

try {
    conn = util.DBConnectionManager.getConnectionFromPool();
    String sql = "SELECT po.*, ot.name as table_name FROM prod_order po " +
                 "JOIN order_tables ot ON po.table_id = ot.id " +
                 "WHERE po.is_billed = 0 AND po.is_cancelled = 0 " +
                 "ORDER BY po.date DESC, po.time DESC";
    ps = conn.prepareStatement(sql);
    rs = ps.executeQuery();
%>
<!DOCTYPE html>
<html>
<head>
    <title>Pending Orders</title>
    <jsp:include page="/assets/common/head.jsp" />
</head>
<body>
    <%@ include file="/assets/navbar/navbar.jsp" %>
    <div class="container-fluid">
        <h3>Pending Orders - Select to Bill</h3>
        <table class="table table-bordered table-hover">
            <thead>
                <tr>
                    <th>Order No</th>
                    <th>Table</th>
                    <th>Date</th>
                    <th>Time</th>
                    <th>Status</th>
                    <th>Action</th>
                </tr>
            </thead>
            <tbody>
<%
    while(rs.next()) {
        int orderId = rs.getInt("id");
        String orderNo = rs.getString("order_no");
        String tableName = rs.getString("table_name");
        String date = rs.getString("date");
        String time = rs.getString("time");
        int isDelivered = rs.getInt("is_delivered");
        String status = isDelivered == 1 ? "Delivered" : "Pending";
        String badgeClass = isDelivered == 1 ? "badge-success" : "badge-warning";
%>
                <tr>
                    <td><%=orderNo%></td>
                    <td><%=tableName%></td>
                    <td><%=date%></td>
                    <td><%=time%></td>
                    <td><span class="badge <%=badgeClass%>"><%=status%></span></td>
                    <td>
                        <button class="btn btn-sm btn-primary" onclick="selectOrder(<%=orderId%>)">
                            <i class="fas fa-file-invoice"></i> Bill This
                        </button>
                    </td>
                </tr>
<%
    }
%>
            </tbody>
        </table>
    </div>
    
    <script>
    function selectOrder(orderId) {
        window.opener.loadOrderToBill(orderId);
        window.close();
    }
    </script>
</body>
</html>
<%
} catch(Exception e) {
    out.println("<div class='alert alert-danger'>Error: " + e.getMessage() + "</div>");
} finally {
    if(rs != null) rs.close();
    if(ps != null) ps.close();
    if(conn != null) conn.close();
}
%>
