<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.*, javax.servlet.http.*" %>
<jsp:useBean id="bill" class="billing.billingBean" />
<%
int uid = (Integer) session.getAttribute("userId");
int billId = Integer.parseInt(request.getParameter("billId"));
double payNow = Double.parseDouble(request.getParameter("payNow")); 
int mode = Integer.parseInt(request.getParameter("mode"));
int bankOption = Integer.parseInt(request.getParameter("bankOption"));

bill.saveDuePayment(billId, payNow, mode, bankOption, uid);

// Get updated bill balance after payment
double newBalance = bill.getBillCurrentBalance(billId);

// Handle cheque operations
try {
    cheque.chequeBean chequeBean = new cheque.chequeBean();
    
    // If bank payment with cheque option (bankOption = 6)
    if (mode == 2 && bankOption == 6) {
        // Clear allocated cheques for this bill
        chequeBean.clearChequeAllocationForBill(billId, payNow);
    } 
    // If full payment made (balance is now 0), reverse cheque allocation
    else if (newBalance == 0) {
        chequeBean.reverseChequeAllocation(billId, payNow);
    }
} catch (Exception e) {
    System.out.println("Cheque operation error: " + e.getMessage());
    e.printStackTrace();
}

response.sendRedirect(request.getContextPath() + "/billing/balanceCollection.jsp");
%>