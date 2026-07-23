<%@ page language="java" contentType="application/json; charset=UTF-8"%>
<%@ page import="java.util.*" %>
<%@ page import="java.text.DecimalFormat" %>
<%@ page import="org.json.simple.JSONObject" %>
<%@ page import="org.json.simple.JSONArray" %>
<jsp:useBean id="bill" class="billing.billingBean" />
<jsp:useBean id="userBean" class="user.userBean" scope="page"/>
<%
/**
 * Get Bill Data API for Mobile Bluetooth Printing
 * Returns complete bill data in JSON format
 */

response.setContentType("application/json");
response.setCharacterEncoding("UTF-8");

// Check if user is logged in
if (session.getAttribute("userId") == null) {
    response.setStatus(401);
    out.print("{\"success\":false,\"message\":\"Not authenticated\"}");
    return;
}

String billNo = request.getParameter("billNo");

if (billNo == null || billNo.trim().isEmpty()) {
    response.setStatus(400);
    out.print("{\"success\":false,\"message\":\"Missing bill number\"}");
    return;
}

try {
    DecimalFormat df = new DecimalFormat("0.00");
    
    // Fetch bill data
    Vector<Vector<Object>> billDetails = bill.getBillDetailsUsingNo(billNo);
    if (billDetails == null || billDetails.isEmpty()) {
        response.setStatus(404);
        out.print("{\"success\":false,\"message\":\"Bill not found\"}");
        return;
    }
    
    double extradisc = bill.getExtraDisc(billNo);
    String cusName = bill.getCusName(billNo);
    String cusNumber = bill.getCusNumber(billNo);
    double paid = bill.getPaidTotal(billNo);
    double balance = bill.getbalanceTotal(billNo);
    String billDate = bill.getBillDate(billNo);
    String numPaid = bill.getNumPaid(paid);
    
    // Get customer details
    Vector customerDetails = bill.getCustomerDetailsByBillNo(billNo);
    String customerName = cusName;
    String customerPhone = "-";
    String customerAddress = "-";
    String customerGSTIN = "-";
    
    if (customerDetails != null && customerDetails.size() >= 4) {
        customerName = customerDetails.get(0) != null ? customerDetails.get(0).toString() : cusName;
        customerPhone = customerDetails.get(1) != null ? customerDetails.get(1).toString() : cusNumber;
        customerAddress = customerDetails.get(2) != null ? customerDetails.get(2).toString() : "-";
        customerGSTIN = customerDetails.get(3) != null ? customerDetails.get(3).toString() : "-";
    } else {
        customerName = cusName;
        customerPhone = cusNumber != null ? cusNumber : "-";
    }
    
    // Get company details
    Vector companyDetails = userBean.getCompanyDetails();
    String companyName = "";
    String companyAddress = "";
    String companyGSTIN = "";
    
    if (companyDetails != null && companyDetails.size() >= 4) {
        companyName = companyDetails.get(1) != null ? companyDetails.get(1).toString() : "";
        companyAddress = companyDetails.get(2) != null ? companyDetails.get(2).toString() : "";
        companyGSTIN = companyDetails.get(3) != null ? companyDetails.get(3).toString() : "";
    }
    
    // Calculate totals and GST
    double totalAmount = 0;
    double totalDiscount = 0;
    double totalQty = 0;
    double totalTaxableAmount = 0;
    double totalGSTAmount = 0;
    double totalCGST = 0;
    double totalSGST = 0;
    
    Map<Integer, Double> gstWiseTaxable = new HashMap<Integer, Double>();
    Map<Integer, Double> gstWiseCGST = new HashMap<Integer, Double>();
    Map<Integer, Double> gstWiseSGST = new HashMap<Integer, Double>();
    
    // Build JSON response
    JSONObject response_json = new JSONObject();
    response_json.put("success", true);
    response_json.put("billNo", billNo);
    response_json.put("billDate", billDate);
    
    // Company info
    JSONObject company = new JSONObject();
    company.put("name", companyName);
    company.put("address", companyAddress);
    company.put("gstin", companyGSTIN);
    response_json.put("company", company);
    
    // Customer info
    JSONObject customer = new JSONObject();
    customer.put("name", customerName);
    customer.put("phone", customerPhone);
    customer.put("address", customerAddress);
    customer.put("gstin", customerGSTIN);
    response_json.put("customer", customer);
    
    // Items
    JSONArray items = new JSONArray();
    for (Vector<Object> prod : billDetails) {
        String itemName = prod.get(0).toString();
        double qty = Double.parseDouble(prod.get(1).toString());
        double itemPrice = Double.parseDouble(prod.get(2).toString());
        double itemDisc = Double.parseDouble(prod.get(3).toString());
        double itemTotal = Double.parseDouble(prod.get(4).toString());
        int gstPer = Integer.parseInt(prod.get(5).toString());
        
        // Calculations
        double taxableAmount = itemTotal / (1 + (gstPer / 100.0));
        double gstAmount = itemTotal - taxableAmount;
        double cgst = gstAmount / 2;
        double sgst = gstAmount / 2;
        
        totalQty += qty;
        totalAmount += itemTotal;
        totalDiscount += itemDisc;
        totalTaxableAmount += taxableAmount;
        totalGSTAmount += gstAmount;
        totalCGST += cgst;
        totalSGST += sgst;
        
        // Update GST summary
        if (!gstWiseTaxable.containsKey(gstPer)) {
            gstWiseTaxable.put(gstPer, 0.0);
            gstWiseCGST.put(gstPer, 0.0);
            gstWiseSGST.put(gstPer, 0.0);
        }
        gstWiseTaxable.put(gstPer, gstWiseTaxable.get(gstPer) + taxableAmount);
        gstWiseCGST.put(gstPer, gstWiseCGST.get(gstPer) + cgst);
        gstWiseSGST.put(gstPer, gstWiseSGST.get(gstPer) + sgst);
        
        // Add item to JSON
        JSONObject item = new JSONObject();
        item.put("name", itemName);
        item.put("qty", qty);
        item.put("price", itemPrice);
        item.put("discount", itemDisc);
        item.put("total", itemTotal);
        item.put("gstPercent", gstPer);
        item.put("taxableAmount", taxableAmount);
        item.put("gstAmount", gstAmount);
        items.add(item);
    }
    response_json.put("items", items);
    
    // Totals
    double finalTotal = totalAmount - extradisc;
    JSONObject totals = new JSONObject();
    totals.put("itemCount", (int)totalQty);
    totals.put("subtotal", totalAmount + totalDiscount);
    totals.put("itemDiscount", totalDiscount);
    totals.put("extraDiscount", extradisc);
    totals.put("total", finalTotal);
    totals.put("paid", paid);
    totals.put("balance", balance);
    totals.put("totalGST", totalGSTAmount);
    totals.put("amountInWords", numPaid);
    response_json.put("totals", totals);
    
    // GST Summary
    JSONArray gstSummary = new JSONArray();
    List<Integer> gstRates = new ArrayList<Integer>(gstWiseTaxable.keySet());
    Collections.sort(gstRates);
    for (Integer rate : gstRates) {
        if (rate > 0) {
            JSONObject gstItem = new JSONObject();
            gstItem.put("rate", rate);
            gstItem.put("taxable", gstWiseTaxable.get(rate));
            gstItem.put("cgst", gstWiseCGST.get(rate));
            gstItem.put("sgst", gstWiseSGST.get(rate));
            gstItem.put("total", gstWiseCGST.get(rate) + gstWiseSGST.get(rate));
            gstSummary.add(gstItem);
        }
    }
    response_json.put("gstSummary", gstSummary);
    
    // Send response
    out.print(response_json.toJSONString());
    
} catch (Exception e) {
    e.printStackTrace();
    response.setStatus(500);
    String errorMsg = e.getMessage() != null ? e.getMessage().replace("\"", "'") : "Unknown error";
    out.print("{\"success\":false,\"message\":\"Error: " + errorMsg + "\"}");
}
%>
