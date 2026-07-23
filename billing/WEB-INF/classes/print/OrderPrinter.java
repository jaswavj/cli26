package print;

import javax.print.*;
import javax.print.attribute.*;
import javax.print.attribute.standard.*;
import java.io.*;
import java.util.*;
import java.text.DecimalFormat;
import java.sql.*;
import user.userBean;

/**
 * ESC/POS Order Printer Utility
 * Prints kitchen/order receipts to thermal printer
 */
public class OrderPrinter {

    // ESC/POS Command Constants
    private static final byte[] INIT = {0x1B, 0x40};
    private static final byte[] BOLD_ON = {0x1B, 0x45, 0x01};
    private static final byte[] BOLD_OFF = {0x1B, 0x45, 0x00};
    private static final byte[] ALIGN_CENTER = {0x1B, 0x61, 0x01};
    private static final byte[] ALIGN_LEFT = {0x1B, 0x61, 0x00};
    private static final byte[] FONT_NORMAL = {0x1B, 0x21, 0x00};
    private static final byte[] FONT_DOUBLE_H = {0x1B, 0x21, 0x10};
    private static final byte[] FONT_A = {0x1B, 0x4D, 0x00};
    private static final byte[] CUT_PAPER = {0x1D, 0x56, 0x01};
    private static final byte[] FEED_3_LINES = {0x1B, 0x64, 0x03};
    
    private static int RECEIPT_WIDTH = 48; // 80mm printer
    private static final int RECEIPT_WIDTH_58MM = 32;
    private static final int RECEIPT_WIDTH_80MM = 48;
    
    private static final DecimalFormat df = new DecimalFormat("0.00");
    
    // Base path for the web application (set from JSP using setApplicationPath)
    private static String applicationBasePath = null;
    
    // TXT output folder when no printer is available (relative to application)
    private static String getTxtOutputDir() {
        if (applicationBasePath != null) {
            return applicationBasePath + File.separator + "bills";
        }
        // Fallback to current directory + bills (for local development)
        return "bills";
    }
    
    /**
     * Set the application base path from JSP/Servlet context
     * Call this from JSP: OrderPrinter.setApplicationPath(application.getRealPath("/"));
     */
    public static void setApplicationPath(String basePath) {
        applicationBasePath = basePath;
    }
    
    private static String configuredPrinterName = null;

    /**
     * Print result
     */
    public static class PrintResult {
        public boolean printed;
        public boolean txtSaved;
        public String txtPath;
        public String message;
        
        public PrintResult(boolean printed, boolean txtSaved, String txtPath, String message) {
            this.printed = printed;
            this.txtSaved = txtSaved;
            this.txtPath = txtPath;
            this.message = message;
        }
    }

    /**
     * Get configured printer
     */
    private static String getConfiguredPrinterName() {
        if (configuredPrinterName != null) return configuredPrinterName;
        try {
            userBean uBean = new userBean();
            Vector companyDetails = uBean.getCompanyDetails();
            if (companyDetails != null && companyDetails.size() > 5) {
                String printerName = (String) companyDetails.elementAt(5);
                if (printerName != null && !printerName.trim().isEmpty()) {
                    configuredPrinterName = printerName.trim();
                    if (printerName.contains("58")) {
                        RECEIPT_WIDTH = RECEIPT_WIDTH_58MM;
                    } else {
                        RECEIPT_WIDTH = RECEIPT_WIDTH_80MM;
                    }
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return configuredPrinterName;
    }

    /**
     * Find print service
     */
    private static PrintService findPrintService() {
        String printerName = getConfiguredPrinterName();
        
        if (printerName != null && !printerName.isEmpty()) {
            PrintService[] services = PrintServiceLookup.lookupPrintServices(null, null);
            for (PrintService service : services) {
                if (service.getName().toLowerCase().contains(printerName.toLowerCase())) {
                    return service;
                }
            }
        }
        
        return PrintServiceLookup.lookupDefaultPrintService();
    }

    /**
     * Print order receipt
     */
    public static PrintResult printOrder(String orderId) throws Exception {
        PrintService service = findPrintService();
        
        if (service != null) {
            byte[] orderData = buildOrderReceiptData(orderId);
            DocFlavor flavor = DocFlavor.BYTE_ARRAY.AUTOSENSE;
            Doc doc = new SimpleDoc(orderData, flavor, null);
            DocPrintJob job = service.createPrintJob();
            job.print(doc, null);
            return new PrintResult(true, false, null, "Order printed to: " + service.getName());
        } else {
            String txtPath = generateTxtOrder(orderId);
            return new PrintResult(false, true, txtPath, "No printer found. Order saved to: " + txtPath);
        }
    }

    /**
     * Generate TXT order
     */
    public static String generateTxtOrder(String orderId) throws Exception {
        File dir = new File(getTxtOutputDir());
        if (!dir.exists()) dir.mkdirs();
        
        String safeOrderId = orderId.replace("/", "-").replace("\\", "-").replace(" ", "_");
        String fileName = "Order_" + safeOrderId + ".txt";
        String filePath = getTxtOutputDir() + File.separator + fileName;
        
        String orderText = buildPlainTextOrder(orderId);
        
        FileWriter writer = new FileWriter(filePath);
        writer.write(orderText);
        writer.close();
        
        return filePath;
    }

    /**
     * Build ESC/POS order receipt data
     */
    private static byte[] buildOrderReceiptData(String orderId) throws Exception {
        ByteArrayOutputStream baos = new ByteArrayOutputStream();
        
        // Initialize
        writeBytes(baos, INIT);
        writeBytes(baos, FONT_NORMAL);
        writeBytes(baos, FONT_A);
        
        // Get order data
        Map<String, Object> orderData = getOrderData(orderId);
        
        // Header
        writeBytes(baos, ALIGN_CENTER);
        writeBytes(baos, BOLD_ON);
        writeBytes(baos, FONT_DOUBLE_H);
        writeString(baos, "ORDER RECEIPT\n");
        writeBytes(baos, FONT_NORMAL);
        writeBytes(baos, BOLD_OFF);
        
        // Company name
        String companyName = (String) orderData.get("company_name");
        if (companyName != null && !companyName.isEmpty()) {
            writeString(baos, companyName + "\n");
        }
        
        writeDivider(baos);
        
        // Order info
        writeBytes(baos, ALIGN_LEFT);
        writeBytes(baos, BOLD_ON);
        writeString(baos, "Order No: " + orderData.get("order_no") + "\n");
        writeString(baos, "Table: " + orderData.get("table_name") + "\n");
        writeBytes(baos, BOLD_OFF);
        writeString(baos, "Date: " + orderData.get("date") + "\n");
        writeString(baos, "Time: " + orderData.get("time") + "\n");
        
        String status = (Integer) orderData.get("is_delivered") == 1 ? "Delivered" : "Pending";
        writeString(baos, "Status: " + status + "\n");
        
        writeDivider(baos);
        
        // Items header
        writeBytes(baos, BOLD_ON);
        writeString(baos, formatOrderItemHeader());
        writeBytes(baos, BOLD_OFF);
        writeDivider(baos);
        
        // Items
        List<Map<String, Object>> items = (List<Map<String, Object>>) orderData.get("items");
        double total = 0;
        
        for (Map<String, Object> item : items) {
            String prodName = (String) item.get("prod_name");
            double qty = (Double) item.get("qty");
            double price = (Double) item.get("price");
            double itemTotal = qty * price;
            total += itemTotal;
            
            writeString(baos, formatOrderItemRow(prodName, String.valueOf((int)qty), df.format(price), df.format(itemTotal)));
        }
        
        writeDivider(baos);
        
        // Total
        writeBytes(baos, BOLD_ON);
        writeString(baos, formatTotalRow("TOTAL:", "Rs " + df.format(total)));
        writeBytes(baos, BOLD_OFF);
        
        writeDivider(baos);
        
        // Footer
        writeBytes(baos, ALIGN_CENTER);
        writeString(baos, "Thank You!\n");
        
        writeBytes(baos, FEED_3_LINES);
        writeBytes(baos, CUT_PAPER);
        
        return baos.toByteArray();
    }

    /**
     * Build plain text order
     */
    private static String buildPlainTextOrder(String orderId) throws Exception {
        StringBuilder sb = new StringBuilder();
        
        Map<String, Object> orderData = getOrderData(orderId);
        
        // Header
        sb.append(centerText("ORDER RECEIPT")).append("\n");
        
        String companyName = (String) orderData.get("company_name");
        if (companyName != null && !companyName.isEmpty()) {
            sb.append(centerText(companyName)).append("\n");
        }
        
        sb.append(divider());
        
        // Order info
        sb.append("Order No: ").append(orderData.get("order_no")).append("\n");
        sb.append("Table: ").append(orderData.get("table_name")).append("\n");
        sb.append("Date: ").append(orderData.get("date")).append("\n");
        sb.append("Time: ").append(orderData.get("time")).append("\n");
        
        String status = (Integer) orderData.get("is_delivered") == 1 ? "Delivered" : "Pending";
        sb.append("Status: ").append(status).append("\n");
        
        sb.append(divider());
        
        // Items
        sb.append(formatOrderItemHeader());
        sb.append(divider());
        
        List<Map<String, Object>> items = (List<Map<String, Object>>) orderData.get("items");
        double total = 0;
        
        for (Map<String, Object> item : items) {
            String prodName = (String) item.get("prod_name");
            double qty = (Double) item.get("qty");
            double price = (Double) item.get("price");
            double itemTotal = qty * price;
            total += itemTotal;
            
            sb.append(formatOrderItemRow(prodName, String.valueOf((int)qty), df.format(price), df.format(itemTotal)));
        }
        
        sb.append(divider());
        sb.append(formatTotalRow("TOTAL:", "Rs " + df.format(total)));
        sb.append(divider());
        sb.append(centerText("Thank You!")).append("\n");
        sb.append("\n\n");
        
        return sb.toString();
    }

    /**
     * Get order data from database
     */
    private static Map<String, Object> getOrderData(String orderId) throws Exception {
        Map<String, Object> orderData = new HashMap<String, Object>();
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
            
            if (rs.next()) {
                orderData.put("order_no", rs.getString("order_no"));
                orderData.put("table_name", rs.getString("table_name"));
                orderData.put("date", rs.getString("date"));
                orderData.put("time", rs.getString("time"));
                orderData.put("is_delivered", rs.getInt("is_delivered"));
            }
            
            rs.close();
            ps.close();
            
            // Get order items
            sql = "SELECT od.*, p.name as prod_name FROM prod_order_details od " +
                  "JOIN prod_product p ON od.prod_id = p.id WHERE od.order_id = ?";
            ps = conn.prepareStatement(sql);
            ps.setInt(1, Integer.parseInt(orderId));
            rs = ps.executeQuery();
            
            List<Map<String, Object>> items = new ArrayList<Map<String, Object>>();
            while (rs.next()) {
                Map<String, Object> item = new HashMap<String, Object>();
                item.put("prod_name", rs.getString("prod_name"));
                item.put("qty", rs.getDouble("qty"));
                item.put("price", rs.getDouble("price"));
                items.add(item);
            }
            orderData.put("items", items);
            
            // Get company name
            userBean uBean = new userBean();
            Vector companyDetails = uBean.getCompanyDetails();
            if (companyDetails != null && companyDetails.size() > 1) {
                orderData.put("company_name", companyDetails.get(1) != null ? companyDetails.get(1).toString() : "");
            } else {
                orderData.put("company_name", "");
            }
            
        } finally {
            if (rs != null) rs.close();
            if (ps != null) ps.close();
            if (conn != null) conn.close();
        }
        
        return orderData;
    }

    // Formatting helpers
    private static void writeBytes(ByteArrayOutputStream baos, byte[] data) {
        try {
            baos.write(data);
        } catch (IOException e) {
            e.printStackTrace();
        }
    }
    
    private static void writeString(ByteArrayOutputStream baos, String str) {
        try {
            baos.write(str.getBytes("UTF-8"));
        } catch (IOException e) {
            e.printStackTrace();
        }
    }
    
    private static void writeDivider(ByteArrayOutputStream baos) {
        StringBuilder sb = new StringBuilder();
        for (int i = 0; i < RECEIPT_WIDTH; i++) sb.append("-");
        sb.append("\n");
        writeString(baos, sb.toString());
    }
    
    private static String divider() {
        StringBuilder sb = new StringBuilder();
        for (int i = 0; i < RECEIPT_WIDTH; i++) sb.append("-");
        sb.append("\n");
        return sb.toString();
    }
    
    private static String formatOrderItemHeader() {
        if (RECEIPT_WIDTH == RECEIPT_WIDTH_58MM) {
            return padRight("ITEM", 16) + padRight("QTY", 4) + padLeft("RATE", 6) + padLeft("AMT", 6) + "\n";
        } else {
            return padRight("ITEM", 26) + padRight("QTY", 6) + padLeft("RATE", 8) + padLeft("AMT", 8) + "\n";
        }
    }
    
    private static String formatOrderItemRow(String name, String qty, String rate, String amt) {
        StringBuilder sb = new StringBuilder();
        
        if (RECEIPT_WIDTH == RECEIPT_WIDTH_58MM) {
            int nameWidth = 16;
            if (name.length() > nameWidth) {
                name = name.substring(0, nameWidth);
            }
            sb.append(padRight(name, nameWidth));
            sb.append(padRight(qty, 4));
            sb.append(padLeft(rate, 6));
            sb.append(padLeft(amt, 6));
        } else {
            int nameWidth = 26;
            if (name.length() > nameWidth) {
                name = name.substring(0, nameWidth);
            }
            sb.append(padRight(name, nameWidth));
            sb.append(padRight(qty, 6));
            sb.append(padLeft(rate, 8));
            sb.append(padLeft(amt, 8));
        }
        
        sb.append("\n");
        return sb.toString();
    }
    
    private static String formatTotalRow(String label, String value) {
        int padding = RECEIPT_WIDTH - label.length() - value.length();
        if (padding < 1) padding = 1;
        StringBuilder sb = new StringBuilder();
        sb.append(label);
        for (int i = 0; i < padding; i++) sb.append(" ");
        sb.append(value);
        sb.append("\n");
        return sb.toString();
    }
    
    private static String padRight(String s, int width) {
        if (s == null) s = "";
        if (s.length() >= width) return s.substring(0, width);
        StringBuilder sb = new StringBuilder(s);
        while (sb.length() < width) sb.append(" ");
        return sb.toString();
    }
    
    private static String padLeft(String s, int width) {
        if (s == null) s = "";
        if (s.length() >= width) return s;
        StringBuilder sb = new StringBuilder();
        while (sb.length() < width - s.length()) sb.append(" ");
        sb.append(s);
        return sb.toString();
    }
    
    private static String centerText(String text) {
        if (text == null) text = "";
        if (text.length() >= RECEIPT_WIDTH) return text.substring(0, RECEIPT_WIDTH);
        int totalPadding = RECEIPT_WIDTH - text.length();
        int leftPadding = totalPadding / 2;
        int rightPadding = totalPadding - leftPadding;
        StringBuilder sb = new StringBuilder();
        for (int i = 0; i < leftPadding; i++) sb.append(" ");
        sb.append(text);
        for (int i = 0; i < rightPadding; i++) sb.append(" ");
        return sb.toString();
    }
}
