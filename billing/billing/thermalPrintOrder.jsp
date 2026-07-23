<%@ page language="java" contentType="text/html; charset=UTF-8"%>
<%@ page language="java" import="java.util.*"%>
<%@ page language="java" import="java.sql.*"%>
<%@ page language="java" import="java.text.DecimalFormat"%>
<jsp:useBean id="userBean" class="user.userBean" scope="page"/>
<%
String orderId = request.getParameter("orderId");
if(orderId == null || orderId.trim().isEmpty()){
    out.print("Error: Missing order ID");
    return;
}

Connection conn = null;
PreparedStatement ps = null;
ResultSet rs = null;

String orderNo = "";
String tableName = "";
String orderDate = "";
String orderTime = "";
int isDelivered = 0;
List<Map<String, Object>> items = new ArrayList<Map<String, Object>>();
double grandTotal = 0;

try {
    conn = util.DBConnectionManager.getConnectionFromPool();
    
    // Get order details
    String sql = "SELECT po.*, ot.name as table_name FROM prod_order po " +
                 "JOIN order_tables ot ON po.table_id = ot.id WHERE po.id = ?";
    ps = conn.prepareStatement(sql);
    ps.setInt(1, Integer.parseInt(orderId));
    rs = ps.executeQuery();
    
    if(rs.next()) {
        orderNo = rs.getString("order_no");
        tableName = rs.getString("table_name");
        orderDate = rs.getString("date");
        orderTime = rs.getString("time");
        isDelivered = rs.getInt("is_delivered");
    }
    
    rs.close();
    ps.close();
    
    // Get order items
    sql = "SELECT od.*, p.name as prod_name FROM prod_order_details od " +
          "JOIN prod_product p ON od.prod_id = p.id WHERE od.order_id = ?";
    ps = conn.prepareStatement(sql);
    ps.setInt(1, Integer.parseInt(orderId));
    rs = ps.executeQuery();
    
    DecimalFormat df = new DecimalFormat("0.00");
    while(rs.next()) {
        Map<String, Object> item = new HashMap<String, Object>();
        item.put("prod_name", rs.getString("prod_name"));
        item.put("qty", rs.getDouble("qty"));
        item.put("price", rs.getDouble("price"));
        double itemTotal = rs.getDouble("qty") * rs.getDouble("price");
        item.put("total", itemTotal);
        grandTotal += itemTotal;
        items.add(item);
    }

// Fetch company details
Vector companyDetails = userBean.getCompanyDetails();
String companyName = "";
String companyAddress = "";

if (companyDetails != null && companyDetails.size() >= 2) {
    companyName = companyDetails.get(1) != null ? companyDetails.get(1).toString() : "";
    companyAddress = companyDetails.get(2) != null ? companyDetails.get(2).toString() : "";
}
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Order Print - <%= orderNo %></title>
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/bootstrap/5.3.0/css/bootstrap.min.css">
    <style>
        @media print {
            body { 
                margin: 0;
                padding: 0;
            }
            .no-print {
                display: none !important;
            }
            .order-receipt {
                border: none !important;
                box-shadow: none !important;
            }
        }
        
        body {
            background-color: #f5f5f5;
            padding: 20px;
        }
        
        .order-receipt {
            width: 80mm;
            margin: 0 auto;
            background: white;
            padding: 10mm;
            font-family: 'Courier New', monospace;
            font-size: 12px;
            border: 1px solid #ddd;
            box-shadow: 0 0 10px rgba(0,0,0,0.1);
        }
        
        .text-center { text-align: center; }
        .text-left { text-align: left; }
        .text-right { text-align: right; }
        .fw-bold { font-weight: bold; }
        .divider { 
            border-top: 1px dashed #000; 
            margin: 5px 0; 
        }
        
        .company-name {
            font-size: 16px;
            font-weight: bold;
            margin-bottom: 5px;
        }
        
        .order-header {
            font-size: 18px;
            font-weight: bold;
            margin: 10px 0;
        }
        
        .order-info {
            margin: 10px 0;
        }
        
        .items-table {
            width: 100%;
            margin: 10px 0;
        }
        
        .items-table th,
        .items-table td {
            padding: 3px 0;
            font-size: 11px;
        }
        
        .items-table th {
            border-bottom: 1px solid #000;
            font-weight: bold;
        }
        
        .total-row {
            font-size: 14px;
            font-weight: bold;
            margin-top: 10px;
        }
        
        .print-buttons {
            margin: 20px auto;
            width: 80mm;
            text-align: center;
        }
        
        @media (max-width: 576px) {
            body {
                padding: 10px;
            }
            .order-receipt {
                width: 100%;
            }
            .print-buttons {
                width: 100%;
            }
        }
    </style>
</head>
<body>
    <div class="print-buttons no-print">
        <button class="btn btn-primary" onclick="window.print()">
            <i class="fas fa-print"></i> Print
        </button>
        <button class="btn btn-secondary" onclick="window.close()">
            <i class="fas fa-times"></i> Close
        </button>
    </div>

    <div class="order-receipt">
        <!-- Header -->
        <div class="text-center order-header">ORDER RECEIPT</div>
        
        <% if (!companyName.isEmpty()) { %>
        <div class="text-center company-name"><%= companyName %></div>
        <% } %>
        
        <% if (!companyAddress.isEmpty()) { %>
        <div class="text-center" style="font-size:10px;"><%= companyAddress.replace("\n", "<br>") %></div>
        <% } %>
        
        <div class="divider"></div>
        
        <!-- Order Info -->
        <div class="order-info">
            <div class="fw-bold">Order No: <%= orderNo %></div>
            <div class="fw-bold">Table: <%= tableName %></div>
            <div>Date: <%= orderDate %></div>
            <div>Time: <%= orderTime %></div>
            <div>Status: <span class="<%= isDelivered == 1 ? "text-success" : "text-warning" %>"><%= isDelivered == 1 ? "Delivered" : "Pending" %></span></div>
        </div>
        
        <div class="divider"></div>
        
        <!-- Items -->
        <table class="items-table">
            <thead>
                <tr>
                    <th style="width:50%">ITEM</th>
                    <th style="width:12%;text-align:center">QTY</th>
                    <th style="width:19%;text-align:right">RATE</th>
                    <th style="width:19%;text-align:right">AMT</th>
                </tr>
            </thead>
            <tbody>
            <% 
            for(Map<String, Object> item : items) { 
            %>
                <tr>
                    <td><%= item.get("prod_name") %></td>
                    <td style="text-align:center"><%= (int)Math.round((Double)item.get("qty")) %></td>
                    <td style="text-align:right"><%= df.format((Double)item.get("price")) %></td>
                    <td style="text-align:right"><%= df.format((Double)item.get("total")) %></td>
                </tr>
            <% } %>
            </tbody>
        </table>
        
        <div class="divider"></div>
        
        <!-- Total -->
        <div class="total-row">
            <div style="display:flex;justify-content:space-between;">
                <span>TOTAL:</span>
                <span>Rs <%= df.format(grandTotal) %></span>
            </div>
        </div>
        
        <div class="divider"></div>
        
        <!-- Footer -->
        <div class="text-center" style="margin-top:10px;">Thank You!</div>
    </div>

    <script>
        // Auto-print on load (optional)
        // window.onload = function() { window.print(); };
    </script>
</body>
</html>
<%
} catch(Exception e) {
    e.printStackTrace();
    out.println("<div class='alert alert-danger'>Error: " + e.getMessage() + "</div>");
} finally {
    if(rs != null) rs.close();
    if(ps != null) ps.close();
    if(conn != null) conn.close();
}
%>
