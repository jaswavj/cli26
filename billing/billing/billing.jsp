<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.util.*, javax.servlet.http.*" %>
<jsp:useBean id="prod" class="product.productBean" />
<jsp:useBean id="userBn" class="user.userBean" />
<%
String contextPaths = request.getContextPath();
Integer uid = (Integer) session.getAttribute("userId");
Vector attenderList = prod.getActiveAttenders();
int userDiscPer = (uid != null) ? userBn.getUserDiscPer(uid) : 100;
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Billing</title>
    <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no">
    <jsp:include page="/assets/common/head.jsp" />
    <style>
        /* =====================================================
           PROFESSIONAL BILLING LAYOUT â€” ONE PAGE, NO SCROLL
           ===================================================== */
        :root {
            /* Layout & spacing only – all colors are in theme.css */
            --shadow-sm: 0 1px 4px rgba(0,0,0,.07);
            --shadow:    0 2px 10px rgba(0,0,0,.10);
            --r:         7px;
            --r-sm:      5px;
        }

        *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }

        html, body {
            height: 100%;
            overflow: hidden;
            font-family: 'Segoe UI', system-ui, -apple-system, sans-serif;
            font-size: 13px;
        }

        /* â”€â”€ WRAPPER â”€â”€ */
        .bw {
            display: flex;
            flex-direction: column;
            height: 100vh;
            height: 100dvh;
            overflow: hidden;
        }

        /* â”€â”€ NAVBAR ZONE â”€â”€ */
        .bw-nav { flex-shrink: 0; }

        /* ── TOP PANEL ── */
        .top-panel {
            flex-shrink: 0;
            border-bottom-width: 2px;
            border-bottom-style: solid;
            padding: 7px 14px 8px;
            box-shadow: var(--shadow-sm);
        }

        .tp-row {
            display: flex;
            gap: 7px;
            align-items: flex-end;
            flex-wrap: wrap;
        }

        /* â”€â”€ FIELD GROUP (label + input, no float) â”€â”€ */
        .fg {
            display: flex;
            flex-direction: column;
            gap: 3px;
            min-width: 0;
            position: relative;
        }

        .fg-lbl {
            font-size: 10px;
            font-weight: 700;
            text-transform: uppercase;
            letter-spacing: .5px;
            white-space: nowrap;
            padding-left: 1px;
        }

        .fg-inp {
            height: 33px;
            border-width: 1.5px;
            border-style: solid;
            border-radius: var(--r-sm);
            padding: 0 9px;
            font-size: 13px;
            transition: border-color .15s, box-shadow .15s;
            outline: none;
            width: 100%;
        }

        .fg-sel {
            height: 33px;
            border-width: 1.5px;
            border-style: solid;
            border-radius: var(--r-sm);
            padding: 0 7px;
            font-size: 13px;
            cursor: pointer;
            outline: none;
            transition: border-color .15s;
            width: 100%;
        }

        /* â”€â”€ TOGGLE CHIPS â”€â”€ */
        .tog {
            display: flex;
            align-items: center;
            gap: 5px;
            height: 33px;
            padding: 0 11px;
            border-width: 1.5px;
            border-style: solid;
            border-radius: var(--r-sm);
            cursor: pointer;
            user-select: none;
            white-space: nowrap;
            transition: border-color .15s, background .15s;
        }

        .tog input[type="checkbox"] {
            width: 32px;
            height: 17px;
            cursor: pointer;
            flex-shrink: 0;
        }

        .tog-lbl {
            font-size: 12px;
            font-weight: 600;
            cursor: pointer;
        }

        /* â”€â”€ BUTTONS â”€â”€ */
        .bb {
            display: inline-flex;
            align-items: center;
            gap: 5px;
            height: 33px;
            padding: 0 13px;
            border-radius: var(--r-sm);
            font-size: 12px;
            font-weight: 700;
            cursor: pointer;
            border: 1.5px solid transparent;
            transition: all .15s;
            white-space: nowrap;
            letter-spacing: .2px;
        }

        /* button colors defined in theme.css */

        /* â”€â”€ EXCHANGE BANNER â”€â”€ */
        #exchangePointBanner {
            margin: 5px 0 0;
            padding: 4px 12px;
            font-size: 12px;
            border-radius: var(--r-sm);
        }

        /* ── PRODUCT ROW ── */
        .prod-row {
            display: flex;
            gap: 7px;
            align-items: flex-end;
            flex-wrap: wrap;
            margin-top: 7px;
            padding-bottom: 16px;
        }

        /* â”€â”€ TABLE PANEL â”€â”€ */
        .tbl-panel {
            flex: 1;
            min-height: 0;
            display: flex;
            flex-direction: column;
            margin: 5px 10px;
            border-width: 1px;
            border-style: solid;
            border-radius: var(--r);
            box-shadow: var(--shadow-sm);
            overflow: hidden;
        }

        .btbl {
            width: 100%;
            border-collapse: collapse;
            table-layout: fixed;
            font-size: 12.5px;
            display: flex;
            flex-direction: column;
            height: 100%;
        }

        .btbl thead {
            display: block;
            flex-shrink: 0;
        }

        .btbl tbody {
            display: block;
            flex: 1;
            overflow-y: auto;
        }

        .btbl thead tr,
        .btbl tbody tr {
            display: table;
            width: 100%;
            table-layout: fixed;
        }

        .btbl thead th {
            padding: 8px 7px;
            font-size: 11px;
            font-weight: 700;
            text-transform: uppercase;
            letter-spacing: .4px;
            border: none;
            border-right-width: 1px;
            border-right-style: solid;
        }

        .btbl thead th:last-child { border-right: none; }

        .btbl tbody td {
            padding: 5px 6px;
            border-bottom-width: 1px;
            border-bottom-style: solid;
            border-right-width: 1px;
            border-right-style: solid;
            vertical-align: middle;
        }

        .btbl tbody td:last-child { border-right: none; }

        .btbl::-webkit-scrollbar       { width: 5px; }
        .btbl tbody::-webkit-scrollbar { width: 5px; }

        /* Inline edit inputs in table */
        .tbl-inp {
            width: 100%;
            height: 26px;
            border-width: 1px;
            border-style: solid;
            border-radius: 3px;
            padding: 0 4px;
            font-size: 12px;
        }

        .disc-cell {
            display: flex;
            gap: 3px;
            align-items: center;
        }

        .disc-type-sel {
            width: 38px;
            min-width: 38px;
            height: 26px;
            border-width: 1px;
            border-style: solid;
            border-radius: 3px;
            padding: 0 2px;
            font-size: 11px;
            font-weight: 700;
            cursor: pointer;
            flex-shrink: 0;
        }

        .disc-cell .disc-inp {
            flex: 1;
            min-width: 0;
            width: auto;
            height: 26px;
            border-width: 1px;
            border-style: solid;
            border-radius: 3px;
            padding: 0 4px;
            font-size: 12px;
            text-align: right;
        }

        /* â”€â”€ BOOTSTRAP BTN COMPAT FOR BILLING.JS ROWS â”€â”€ */
        /* Bootstrap btn compat – structural only (colors in theme.css) */
        .btn    { display: inline-flex; align-items: center; gap: 3px; cursor: pointer; border: 1px solid transparent; border-radius: 4px; padding: 2px 8px; font-size: 11.5px; font-weight: 600; transition: all .15s; }
        .btn-sm { padding: 2px 7px; font-size: 11px; }

        /* â”€â”€ BOTTOM PANEL â”€â”€ */
        .bot-panel {
            flex-shrink: 0;
            border-top-width: 2px;
            border-top-style: solid;
            padding: 7px 14px;
            box-shadow: 0 -2px 8px rgba(0,0,0,.06);
        }

        .bot-inner {
            display: flex;
            gap: 10px;
            align-items: flex-end;
            flex-wrap: wrap;
        }

        .grp {
            display: flex;
            gap: 7px;
            align-items: flex-end;
            flex-wrap: wrap;
        }

        .grp-totals { flex: 2.5; }
        .grp-pay    { flex: 1.8; }
        .grp-act    { flex: 1; justify-content: flex-end; }

        /* Payable highlight – structural only, colors in theme.css */
        .fg-inp.payable {
            font-size: 19px !important;
            font-weight: 800 !important;
            text-align: center;
        }

        .fg-inp.amt { font-weight: 600; }

        /* Bill number badge – colors in theme.css */
        .bill-badge {
            padding: 5px 14px;
            border-radius: var(--r-sm);
            font-size: 12px;
            font-weight: 800;
            min-width: 80px;
            text-align: center;
            letter-spacing: .5px;
            white-space: nowrap;
            height: 33px;
            display: flex;
            align-items: center;
            justify-content: center;
        }

        /* â”€â”€ MOBILE â”€â”€ */
        @media (max-width: 768px) {
            .bw { height: 100svh; }

            .top-panel { padding: 5px 8px 7px; }

            .tp-row   { gap: 5px; }
            .prod-row { gap: 5px; margin-top: 5px; }

            .tbl-panel { margin: 4px 6px; }

            .bot-panel { padding: 5px 8px 82px; overflow-y: auto; max-height: 42vh; }

            .bot-inner { flex-direction: column; gap: 5px; align-items: stretch; }

            .grp-totals,
            .grp-pay {
                flex: none;
                width: 100%;
                display: grid;
                gap: 5px;
            }

            .grp-totals { grid-template-columns: repeat(3, 1fr); }
            .grp-pay    { grid-template-columns: repeat(3, 1fr); }

            /* Action buttons: fixed bar always visible at bottom */
            .grp-act {
                position: fixed;
                bottom: 0;
                left: 0;
                right: 0;
                z-index: 200;
                border-top-width: 2px;
                border-top-style: solid;
                box-shadow: 0 -3px 10px rgba(0,0,0,.12);
                padding: 6px 8px;
                display: grid !important;
                grid-template-columns: repeat(3, 1fr);
                gap: 5px;
                justify-items: stretch;
            }

            .bb { justify-content: center; width: 100%; }
            .bill-badge { width: 100%; }

            .btbl { min-width: 700px; }
            .tbl-panel { overflow-x: auto; }
        }

        @media (max-width: 480px) {
            .tp-row   { display: grid; grid-template-columns: 1fr 1fr; gap: 5px; }
            .prod-row { display: grid; grid-template-columns: repeat(3,1fr); gap: 5px; }
            .grp-totals { grid-template-columns: repeat(2,1fr); }
            .grp-pay    { grid-template-columns: repeat(2,1fr); }
        }
    </style>
</head>

<body>
<div class="bw">

    <!-- â”€â”€ NAVBAR â”€â”€ -->
    <div class="bw-nav">
        <jsp:include page="/assets/navbar/navbar.jsp" />
    </div><!-- /bw-nav -->

    <!-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
         TOP PANEL â€” Customer + Product Inputs
         â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â• -->
    <div class="top-panel">

        <!-- Row 1: Customer info + toggles + hold -->
        <div class="tp-row">
            <div class="fg" style="flex:1.6;min-width:130px;">
                <span class="fg-lbl">Customer Name</span>
                <input type="text" id="customerName" class="fg-inp" placeholder="Customer name" autocomplete="off">
                <input type="hidden" id="customerId" value="0">
                <input type="hidden" id="customerCreditLimit" value="0">
                <input type="hidden" id="customerExchangePoint" value="0">
                <input type="hidden" id="exchangePointUsed" value="0">
            </div>
            <div class="fg" style="flex:1;min-width:120px;">
                <span class="fg-lbl">Phone No</span>
                <input type="text" id="customerPhn" class="fg-inp" placeholder="Phone number" autocomplete="off">
            </div>
            <input type="hidden" id="isTaxBill" value="1">
            <input type="hidden" id="isCommission" value="0">
            <button class="bb bb-outline" data-bs-toggle="modal" data-bs-target="#quotationListModal">
                <i class="fa-solid fa-clock"></i> HOLD LIST
            </button>
        </div>

        <!-- Exchange Point Banner -->
        <div id="exchangePointBanner" class="alert alert-success alert-dismissible d-none" role="alert"
             style="margin:5px 0 0;padding:4px 12px;font-size:12px;">
            <i class="fas fa-coins me-1"></i>
            <strong>Exchange Points: â‚¹<span id="exchangePointValue">0</span></strong>&nbsp;
            <button type="button" class="btn btn-sm btn-success py-0 px-2"
                    onclick="applyExchangePointDiscount()" style="font-size:11px;">
                <i class="fas fa-tag me-1"></i>Use as Discount
            </button>
            <button type="button" class="btn-close" onclick="dismissExchangePointBanner()" aria-label="Close"></button>
        </div>

        <!-- Row 2: Product entry -->
        <div class="prod-row">
            <div class="fg" style="flex:2.8;min-width:160px;position:relative;">
                <span class="fg-lbl">Code / Item Name</span>
                <input type="text" id="productSearch" class="fg-inp" placeholder="Scan barcode or search item" autocomplete="off">
                <span id="stockBadge" style="display:none;position:absolute;bottom:-18px;left:1px;font-size:10px;font-weight:700;letter-spacing:.3px;padding:2px 7px;border-radius:3px;white-space:nowrap;"></span>
            </div>
            <input type="hidden" id="productCode">
            <input type="hidden" id="productName" name="productName">
            <div class="fg" style="flex:.75;min-width:78px;">
                <span class="fg-lbl">Unit</span>
                <select id="productUnit" class="fg-sel" disabled>
                    <option value="">Unit</option>
                    <option value="gram">Gram</option>
                </select>
                <input type="hidden" id="productUnitId" value="">
                <input type="hidden" id="productUnitName" value="">
                <input type="hidden" id="productConvertionUnit" value="">
            </div>
            <div class="fg" style="flex:.65;min-width:68px;">
                <span class="fg-lbl" id="qtyLabel">Qty</span>
                <input type="number" id="productQty" class="fg-inp" placeholder="1" value="1" min="1">
            </div>
            <div class="fg" style="flex:.9;min-width:88px;">
                <span class="fg-lbl">Price</span>
                <input type="number" id="productPrice" class="fg-inp" placeholder="0.00" min="0">
            </div>
            <input type="hidden" id="productDiscount" value="0">
            <div style="display:flex;align-items:flex-end;">
                <button class="bb bb-primary" onclick="addProduct()">
                    <i class="fa-solid fa-circle-plus"></i> ADD
                </button>
            </div>
        </div>

    </div><!-- /top-panel -->

    <!-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
         TABLE PANEL â€” Bill Items
         â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â• -->
    <div class="tbl-panel">
        <table class="btbl">
            <thead>
                <tr>
                    <th style="width:5%;">#</th>
                    <th style="width:10%;">Code</th>
                    <th style="width:23%;">Item Name</th>
                    <th style="width:8%;">Qty</th>
                    <th style="width:10%;">Price</th>
                    <th style="width:10%;">Discount</th>
                    <th style="width:12%;">Total</th>
                    <th style="width:15%;">Action</th>
                </tr>
            </thead>
            <tbody id="billBody">
            </tbody>
        </table>
    </div><!-- /tbl-panel -->

    <!-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
         BOTTOM PANEL â€” Totals + Payment + Actions
         â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â• -->
    <div class="bot-panel">
        <div class="bot-inner">

            <!-- Totals Group -->
            <div class="grp grp-totals">
                <div class="fg">
                    <span class="fg-lbl">Price Total</span>
                    <input type="text" class="fg-inp amt only-numbers" id="priceTotal" value="0" readonly>
                </div>
                <div class="fg">
                    <span class="fg-lbl">Discount</span>
                    <input type="text" class="fg-inp amt only-numbers" id="discountTotal" value="0" readonly>
                </div>
                <div class="fg">
                    <span class="fg-lbl">Grand Total</span>
                    <input type="text" class="fg-inp amt only-numbers" id="grandTotal" value="0" readonly>
                </div>
                <div class="fg">
                    <span class="fg-lbl">Extra Disc</span>
                    <input type="text" class="fg-inp amt only-numbers" id="finalDiscount" value="0"
                           oninput="setDefaultValue(this); updatePayableAmount();">
                </div>
                <div class="fg">
                    <span class="fg-lbl" style="color:var(--red);font-weight:800;">PAYABLE</span>
                    <input type="text" class="fg-inp payable only-numbers" id="payableAmount" value="0" readonly>
                </div>
            </div>

            <!-- Payment Group -->
            <div class="grp grp-pay">
                <div class="fg">
                    <span class="fg-lbl">Pay Mode</span>
                    <select name="mode" id="mode" class="fg-sel" required style="min-width:78px;">
                        <option value="1">Cash</option>
                        <option value="2">Bank</option>
                        <option value="3">Mixed</option>
                    </select>
                </div>
                <div class="fg">
                    <span class="fg-lbl">Pay Type</span>
                    <select name="type" id="type" class="fg-sel" required style="min-width:88px;">
                        <option value="1">UPI</option>
                        <option value="2">Debit Card</option>
                        <option value="3">Credit Card</option>
                        <option value="4">Net Banking</option>
                        <option value="5">Wallet</option>
                    </select>
                </div>
                <div class="fg">
                    <span class="fg-lbl">Cash Paid</span>
                    <input type="text" class="fg-inp amt only-numbers" id="paid" value="0">
                </div>
                <div class="fg">
                    <span class="fg-lbl">Bank Paid</span>
                    <input type="text" class="fg-inp amt only-numbers" id="bankPaid" value="0">
                </div>
                <div class="fg">
                    <span class="fg-lbl">Balance</span>
                    <input type="text" class="fg-inp amt only-numbers" id="balance" value="0">
                </div>
            </div>

            <!-- Actions Group -->
            <div class="grp grp-act">
                <button id="saveBillBtn" class="bb bb-navy" onclick="saveBill()">
                    <i class="fa-regular fa-floppy-disk"></i> SAVE
                </button>
                <button class="bb bb-outline" onclick="printBill()" title="Print to thermal printer">
                    <i class="fa-solid fa-print"></i> PRINT
                </button>
                <div id="quotationBtnDiv">
                    <button class="bb bb-outline" onclick="saveQuotation()" style="width:100%;">
                        <i class="fa-solid fa-clock"></i> HOLD
                    </button>
                </div>
                <div id="quotationPrintBtnDiv" style="display:none;">
                    <button class="bb bb-outline" onclick="printSavedQuotation()" style="width:100%;">
                        <i class="fa-solid fa-print"></i> PRINT HOLD
                    </button>
                </div>
                <button type="button" class="bb bb-outline" onclick="newBill()">
                    <i class="fa-solid fa-rotate"></i> NEW
                </button>
                <button class="bb bb-outline" data-bs-toggle="modal" data-bs-target="#duplicateBillModal">
                    <i class="fa-solid fa-copy"></i> DUPE
                </button>
                <div class="bill-badge" id="billNoSpan"></div>
            </div>

        </div>
    </div><!-- /bot-panel -->

</div><!-- /bw -->

<!-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
     MODALS
     â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â• -->
<%@ include file="duplicateBillModal.jsp" %>
<%@ include file="quotationList.jsp" %>

<!-- Order List Modal -->
<div class="modal fade" id="orderListModal" tabindex="-1" aria-labelledby="orderListModalLabel" aria-hidden="true">
    <div class="modal-dialog modal-lg modal-fullscreen-sm-down">
        <div class="modal-content">
            <div class="modal-header bg-success text-white">
                <h5 class="modal-title" id="orderListModalLabel">
                    <i class="fas fa-utensils me-2"></i>Pending Orders
                </h5>
                <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal" aria-label="Close"></button>
            </div>
            <div class="modal-body p-2 p-md-3">
                <div id="orderListSpinner" class="text-center" style="display:none;">
                    <div class="spinner-border text-success" role="status"><span class="visually-hidden">Loading</span></div>
                </div>
                <div id="orderListContent">
                    <div class="d-none d-md-block">
                        <div class="table-responsive">
                            <table class="table table-bordered table-hover table-sm">
                                <thead class="table-light">
                                    <tr><th>Order No</th><th>Table</th><th>Date</th><th>Time</th><th>Status</th><th>Actions</th></tr>
                                </thead>
                                <tbody id="orderListTableBody"></tbody>
                            </table>
                        </div>
                    </div>
                    <div class="d-md-none" id="orderListCardsBody"></div>
                </div>
            </div>
        </div>
    </div>
</div>

<!-- Available Cheques Modal -->
<div class="modal fade" id="availableChequesModal" tabindex="-1" aria-labelledby="availableChequesModalLabel" aria-hidden="true">
    <div class="modal-dialog modal-lg">
        <div class="modal-content">
            <div class="modal-header bg-primary text-white">
                <h5 class="modal-title" id="availableChequesModalLabel">
                    <i class="fas fa-money-check-alt me-2"></i>Available Cheques for <span id="chequeCustomerName"></span>
                </h5>
                <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal" aria-label="Close"></button>
            </div>
            <div class="modal-body">
                <div id="chequeLoadingSpinner" class="text-center" style="display:none;">
                    <div class="spinner-border text-primary" role="status"><span class="visually-hidden">Loading</span></div>
                </div>
                <div id="chequeContent">
                    <div class="table-responsive">
                        <table class="table table-bordered table-hover table-sm">
                            <thead class="table-light">
                                <tr><th>#</th><th>Cheque Number</th><th>Entry Date</th><th>Bank Name</th><th>Status</th></tr>
                            </thead>
                            <tbody id="chequeTableBody">
                                <tr><td colspan="5" class="text-center text-muted">No cheques available</td></tr>
                            </tbody>
                        </table>
                    </div>
                </div>
            </div>
            <div class="modal-footer">
                <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Close</button>
            </div>
        </div>
    </div>
</div>

<!-- Product History Modal -->
<div class="modal fade" id="productHistoryModal" tabindex="-1" aria-labelledby="productHistoryModalLabel" aria-hidden="true">
    <div class="modal-dialog modal-lg modal-fullscreen-sm-down">
        <div class="modal-content">
            <div class="modal-header">
                <h5 class="modal-title" id="productHistoryModalLabel">
                    Last 6 Bills â€” <span id="historyProductName"></span>
                </h5>
                <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
            </div>
            <div class="modal-body">
                <div id="historyLoadingSpinner" class="text-center" style="display:none;">
                    <div class="spinner-border text-primary" role="status"><span class="visually-hidden">Loading</span></div>
                </div>
                <div id="historyContent" class="table-responsive">
                    <table class="table table-bordered table-sm">
                        <thead>
                            <tr>
                                <th>Bill No</th><th>Date</th><th>Time</th><th>Customer</th>
                                <th>Qty</th><th>Price</th><th>Discount</th><th>Total</th>
                            </tr>
                        </thead>
                        <tbody id="historyTableBody">
                            <tr><td colspan="8" class="text-center">No history available</td></tr>
                        </tbody>
                    </table>
                </div>
            </div>
            <div class="modal-footer">
                <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Close</button>
            </div>
        </div>
    </div>
</div>

<!-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
     SCRIPTS
     â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â• -->
<script>
    var contextPath = '<%=contextPaths%>';
    var userMaxDiscPer = <%=userDiscPer%>;
</script>
<script src="bluetoothPrinter.js"></script>
<script src="billing.js"></script>
<script>
document.addEventListener("DOMContentLoaded", function () {
    // Focus product search input on load
    setTimeout(function () {
        const ps = document.getElementById('productSearch');
        if (ps) ps.focus();
    }, 150);

    const productCodeInput = document.getElementById('productCode');
    const productNameInput = document.getElementById('productName');
    const productSearchInput = document.getElementById('productSearch');
    const sidebar = document.getElementById('sidebar');
    const sidebarOverlay = document.getElementById('sidebarOverlay');
    const body = document.body;

    function isMobile() { return window.innerWidth <= 768; }

    function closeSidebar() {
        if (sidebar && sidebarOverlay) {
            if (isMobile()) {
                sidebar.classList.remove('show');
                sidebarOverlay.classList.remove('show');
                body.classList.remove('sidebar-open');
            } else {
                if (!sidebar.classList.contains('hidden')) {
                    sidebar.classList.add('hidden');
                    body.classList.add('sidebar-hidden');
                }
            }
        }
    }

    if (productSearchInput) productSearchInput.addEventListener('focus', closeSidebar);

    // Ctrl+S â€” save bill
    document.addEventListener('keydown', function (e) {
        if ((e.ctrlKey || e.metaKey) && e.key === 's') {
            e.preventDefault();
            const btn = document.getElementById('saveBillBtn');
            if (btn && !btn.disabled) saveBill();
        }
    });
});
</script>
</body>
</html>
