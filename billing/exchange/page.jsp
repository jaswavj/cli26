<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page language="java" import="java.util.*, java.text.SimpleDateFormat, java.util.Date" %>
<jsp:useBean id="customer" class="currency.currencyBean" />
<%
Integer userId = (Integer) session.getAttribute("userId");
if (userId == null) {
    response.sendRedirect(request.getContextPath() + "/index.jsp");
    return;
}

Vector paymentMethods = customer.getPaymentMethods();
String today = new SimpleDateFormat("yyyy-MM-dd").format(new Date());
String msg = request.getParameter("msg");
String type = request.getParameter("type");
String jsMsg = "";
if (msg != null) {
    jsMsg = msg.replace("\\", "\\\\").replace("'", "\\'").replace("\"", "\\\"").replace("\r", "").replace("\n", "\\n");
}
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Currency Exchange</title>
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <%@ include file="/assets/common/head.jsp" %>
    <style>
        .search-results {
            position: absolute; z-index: 1000; width: 100%; max-height: 220px;
            overflow-y: auto; background: #fff; border: 1px solid #dbe3ee;
            border-radius: 8px; box-shadow: 0 8px 20px rgba(0,0,0,0.08); display: none;
        }
        .search-results .item { padding: 10px 12px; cursor: pointer; border-bottom: 1px solid #f1f5f9; }
        .search-results .item:hover { background: #f8fafc; }
        .search-wrap { position: relative; }
        .limit-hint { font-size: 0.8rem; color: #64748b; margin-top: 4px; }
        .stock-hint { font-size: 0.8rem; color: #0f766e; margin-top: 4px; }
        .currency-section {
            border: 1px solid #e2e8f0;
            border-radius: 8px;
            padding: 14px;
            margin-bottom: 14px;
            background: #f8fafc;
        }
        .currency-section-title {
            font-weight: 600;
            font-size: 0.88rem;
            color: var(--bill-navy, #1e3a5f);
            margin-bottom: 10px;
        }
        .customer-balance-panel {
            display: none;
            border: 1px solid #dbeafe;
            border-radius: 8px;
            padding: 12px 14px;
            margin-bottom: 14px;
            background: #eff6ff;
        }
        .customer-balance-panel .balance-item {
            font-size: 0.92rem;
        }
        .customer-balance-panel .balance-value {
            font-weight: 700;
        }
        .adjust-hint {
            font-size: 0.8rem;
            color: #0369a1;
            margin-top: 4px;
        }
    </style>
</head>
<body>
    <%@ include file="/assets/navbar/navbar.jsp" %>
<%
    request.setAttribute("pageTitle", "Currency Exchange");
    request.setAttribute("pageSubtitle", "Purchase / Sale Transaction");
    request.setAttribute("pageIcon", "fa-solid fa-right-left");
%>
<jsp:include page="/assets/common/pageHeader.jsp" />

<div class="container-fluid mt-3 mst-page">
    <div class="row g-3">
        <div class="col-12">
            <div class="card mst-card">
                <div class="mst-card-header">
                    <h6 class="mb-0"><i class="fa-solid fa-right-left me-2"></i>New Exchange</h6>
                </div>
                <div class="card-body p-3">
                    <form action="<%=request.getContextPath()%>/exchange/save.jsp" method="post" id="exchangeForm">
                        <input type="hidden" name="customerId" id="customerId" value="">

                        <div class="mb-3">
                            <label class="form-label fw-semibold">Customer (Name or Phone)</label>
                            <div class="search-wrap">
                                <input type="text" id="customerSearch" class="form-control fg-inp"
                                    placeholder="Search existing or type new customer name" autocomplete="off" required>
                                <div id="searchResults" class="search-results"></div>
                            </div>
                            <small class="text-muted">If customer not found, enter name and phone — a new record will be created on save.</small>
                        </div>

                        <div id="customerBalancePanel" class="customer-balance-panel">
                            <div class="row g-2">
                                <div class="col-md-6 balance-item">
                                    Purchase Balance (Advance): <span id="customerAdvanceDisplay" class="balance-value text-success">0.0000</span>
                                </div>
                                <div class="col-md-6 balance-item">
                                    Due (Customer Balance): <span id="customerDueDisplay" class="balance-value text-danger">0.0000</span>
                                </div>
                            </div>
                            <div id="adjustHint" class="adjust-hint"></div>
                        </div>

                        <div class="row g-2 mb-3">
                            <div class="col-md-6">
                                <label class="form-label fw-semibold">Phone (for new customer)</label>
                                <input type="text" name="customerPhone" id="customerPhone" class="form-control fg-inp" placeholder="Optional">
                            </div>
                            <div class="col-md-6">
                                <label class="form-label fw-semibold">Date</label>
                                <input type="date" name="exchangeDate" class="form-control fg-inp" value="<%= today %>" required>
                            </div>
                        </div>

                        <div class="mb-3">
                            <label class="form-label fw-semibold d-block">Type</label>
                            <div class="btn-group type-toggle w-100" role="group">
                                <input type="radio" class="btn-check" name="exchangeType" id="typePurchase" value="1" checked>
                                <label class="btn btn-outline-secondary" for="typePurchase"><i class="fa-solid fa-cart-shopping me-1"></i>Purchase</label>
                                <input type="radio" class="btn-check" name="exchangeType" id="typeSale" value="2">
                                <label class="btn btn-outline-secondary" for="typeSale"><i class="fa-solid fa-hand-holding-dollar me-1"></i>Sale</label>
                            </div>
                        </div>

                        <div class="currency-section">
                            <div class="currency-section-title" id="mainSectionTitle">Purchase Currency</div>
                            <div class="mb-3">
                                <label class="form-label fw-semibold" id="currencyLabel">Currency</label>
                                <select name="currencyId" id="currencyId" class="form-select fg-inp" required>
                                    <option value="">Select currency</option>
                                </select>
                                <div id="limitHint" class="limit-hint"></div>
                                <div id="stockHint" class="stock-hint"></div>
                            </div>
                            <div class="mb-0">
                                <label class="form-label fw-semibold" id="amountLabel">Purchase Amount</label>
                                <input type="number" step="0.0001" min="0.0001" name="amount" id="amount" class="form-control fg-inp" placeholder="0.0000" required>
                            </div>
                        </div>

                        <div class="currency-section" id="rateSection" style="display:none;">
                            <div class="currency-section-title">Exchange Rate</div>
                            <div class="mb-0">
                                <label class="form-label fw-semibold" id="exchangeRateLabel">Rate</label>
                                <input type="number" step="0.0001" min="0.0001" id="exchangeRate" class="form-control fg-inp" placeholder="0.0000">
                                <div id="rateLimitHint" class="limit-hint"></div>
                                <div id="calculatedHint" class="stock-hint"></div>
                            </div>
                        </div>

                        <div class="currency-section">
                            <div class="currency-section-title" id="counterSectionTitle">Base Currency</div>
                            <div class="mb-3">
                                <label class="form-label fw-semibold" id="counterCurrencyLabel">Base Currency</label>
                                <input type="text" id="counterCurrencyDisplay" class="form-control fg-inp bg-light" readonly placeholder="Configure base currency in Currency Master">
                                <input type="hidden" name="counterCurrencyId" id="counterCurrencyId" value="">
                                <div id="counterStockHint" class="stock-hint"></div>
                            </div>
                            <div class="mb-0">
                                <label class="form-label fw-semibold" id="counterAmountLabel">Base Currency Amount</label>
                                <input type="number" step="0.0001" min="0.0001" name="counterAmount" id="counterAmount" class="form-control fg-inp bg-light" placeholder="0.0000" required readonly>
                            </div>
                        </div>

                        <div class="mb-3">
                            <label class="form-label fw-semibold">Payment Method</label>
                            <select name="paymentId" id="paymentId" class="form-select fg-inp" required>
                                <option value="">Select payment method</option>
                                <% for (int i = 0; i < paymentMethods.size(); i++) {
                                    Vector pm = (Vector) paymentMethods.get(i);
                                %>
                                <option value="<%= pm.elementAt(0) %>" data-is-cash="<%= pm.elementAt(2) %>"><%= pm.elementAt(1) %></option>
                                <% } %>
                            </select>
                        </div>

                        <div class="row g-2 mb-3">
                            <div class="col-md-4">
                                <label class="form-label fw-semibold" id="paidLabel">Paid</label>
                                <input type="number" step="0.0001" min="0" name="paid" id="paid" class="form-control fg-inp" placeholder="0.0000" value="0">
                            </div>
                            <div class="col-md-4">
                                <label class="form-label fw-semibold" id="adjustedLabel">Adjusted</label>
                                <input type="number" step="0.0001" min="0" id="adjustedAmount" class="form-control fg-inp bg-light" placeholder="0.0000" value="0" readonly>
                            </div>
                            <div class="col-md-4">
                                <label class="form-label fw-semibold" id="balanceLabel">Balance</label>
                                <input type="number" step="0.0001" min="0" name="balance" id="balance" class="form-control fg-inp bg-light" placeholder="0.0000" value="0" readonly>
                                <div id="balanceHint" class="limit-hint"></div>
                            </div>
                        </div>

                        <div class="mb-3">
                            <label class="form-label fw-semibold">Notes</label>
                            <textarea name="notes" class="form-control fg-inp" rows="2" placeholder="Optional"></textarea>
                        </div>

                        <input type="hidden" name="customerName" id="customerName">

                        <div class="d-flex gap-2">
                            <button type="submit" class="bb bb-primary">
                                <i class="fa-solid fa-floppy-disk me-1"></i>Save Exchange
                            </button>
                            <button type="reset" class="bb bb-outline" id="resetBtn">
                                <i class="fa-solid fa-rotate-left me-1"></i>Reset
                            </button>
                        </div>
                    </form>
                </div>
            </div>
        </div>
    </div>
</div>

<script>
    const contextPath = '<%=request.getContextPath()%>';
    let currenciesData = [];
    let baseCurrencyId = 0;
    let baseCurrency = null;
    let searchTimer = null;

    const searchInput = document.getElementById('customerSearch');
    const searchResults = document.getElementById('searchResults');
    const currencySelect = document.getElementById('currencyId');
    const counterCurrencyDisplay = document.getElementById('counterCurrencyDisplay');
    const counterCurrencyIdInput = document.getElementById('counterCurrencyId');
    const limitHint = document.getElementById('limitHint');
    const stockHint = document.getElementById('stockHint');
    const counterStockHint = document.getElementById('counterStockHint');
    const amountInput = document.getElementById('amount');
    const exchangeRateInput = document.getElementById('exchangeRate');
    const counterAmountInput = document.getElementById('counterAmount');
    const paidInput = document.getElementById('paid');
    const balanceInput = document.getElementById('balance');
    const balanceHint = document.getElementById('balanceHint');
    const paymentSelect = document.getElementById('paymentId');
    const rateSection = document.getElementById('rateSection');
    const rateLimitHint = document.getElementById('rateLimitHint');
    const calculatedHint = document.getElementById('calculatedHint');
    const exchangeRateLabel = document.getElementById('exchangeRateLabel');
    const customerBalancePanel = document.getElementById('customerBalancePanel');
    const customerAdvanceDisplay = document.getElementById('customerAdvanceDisplay');
    const customerDueDisplay = document.getElementById('customerDueDisplay');
    const adjustHint = document.getElementById('adjustHint');
    const adjustedAmountInput = document.getElementById('adjustedAmount');
    const adjustedLabel = document.getElementById('adjustedLabel');
    let syncingPaid = false;
    let customerAdvance = 0;
    let customerDue = 0;

    let pairLimits = { min: 0, max: 0, hasLimit: false };

    function getSelectedCode(selectEl) {
        const opt = selectEl.options[selectEl.selectedIndex];
        return (opt && opt.dataset.code) ? opt.dataset.code : '';
    }

    function isCashPayment() {
        const opt = paymentSelect.options[paymentSelect.selectedIndex];
        return opt && opt.dataset.isCash === '1';
    }

    function getBaseCurrencyCode() {
        return baseCurrency ? baseCurrency.code : '';
    }

    function isBaseToBase() {
        return baseCurrencyId > 0 && String(currencySelect.value) === String(baseCurrencyId);
    }

    function fetchPairLimits() {
        const mainId = currencySelect.value;
        pairLimits = { min: 0, max: 0, hasLimit: false };
        if (!mainId || !baseCurrencyId) {
            rateSection.style.display = 'none';
            rateLimitHint.textContent = '';
            return Promise.resolve();
        }

        // Base currency ↔ base currency: fixed rate 1, no rate limits
        if (isBaseToBase()) {
            rateSection.style.display = 'none';
            rateLimitHint.textContent = '';
            exchangeRateInput.value = '1';
            exchangeRateInput.removeAttribute('min');
            exchangeRateInput.removeAttribute('max');
            calculateCounterAmount();
            return Promise.resolve();
        }

        rateSection.style.display = 'block';
        const mainCode = getSelectedCode(currencySelect);
        const counterCode = getBaseCurrencyCode();
        exchangeRateLabel.textContent = counterCode + ' per 1 ' + mainCode;

        return fetch(contextPath + '/exchange/getPairLimits.jsp?currencyId=' + mainId + '&counterCurrencyId=' + baseCurrencyId)
            .then(function(res) { return res.json(); })
            .then(function(data) {
                if (data && data.success) {
                    pairLimits.min = parseFloat(data.min || '0');
                    pairLimits.max = parseFloat(data.max || '0');
                    pairLimits.hasLimit = data.hasLimit === true;
                    if (pairLimits.hasLimit) {
                        rateLimitHint.textContent = 'Allowed rate: ' + pairLimits.min.toFixed(4) + ' to ' + pairLimits.max.toFixed(4);
                        exchangeRateInput.min = pairLimits.min;
                        exchangeRateInput.max = pairLimits.max;
                    } else {
                        rateLimitHint.textContent = 'No exchange rate limit configured for this pair in Currency Master';
                        exchangeRateInput.removeAttribute('min');
                        exchangeRateInput.removeAttribute('max');
                    }
                }
                calculateCounterAmount();
            })
            .catch(function() {
                rateLimitHint.textContent = '';
                calculateCounterAmount();
            });
    }

    function calculateCounterAmount() {
        const amt = parseFloat(amountInput.value);
        const mainCode = getSelectedCode(currencySelect);
        const counterCode = getBaseCurrencyCode();

        if (isBaseToBase()) {
            if (!isNaN(amt) && amt > 0) {
                exchangeRateInput.value = '1';
                counterAmountInput.value = amt.toFixed(4);
                calculatedHint.textContent = amt.toFixed(4) + ' ' + mainCode + ' (base ↔ base, rate 1)';
                syncPaidBalance(true);
            } else {
                counterAmountInput.value = '';
                calculatedHint.textContent = '';
                syncPaidBalance(true);
            }
            updateCounterHints();
            updateCurrencyHints();
            return;
        }

        const rate = parseFloat(exchangeRateInput.value);
        if (!isNaN(amt) && amt > 0 && !isNaN(rate) && rate > 0) {
            const total = (amt * rate).toFixed(4);
            counterAmountInput.value = total;
            calculatedHint.textContent = amt.toFixed(4) + ' ' + mainCode + ' × ' + rate.toFixed(4) + ' = ' + total + ' ' + counterCode;
            syncPaidBalance(true);
        } else {
            counterAmountInput.value = '';
            calculatedHint.textContent = '';
            syncPaidBalance(true);
        }
        updateCounterHints();
        updateCurrencyHints();
    }

    function getAdjustmentAmount(total) {
        const isPurchase = document.getElementById('typePurchase').checked;
        if (isPurchase) {
            return Math.min(customerDue, total);
        }
        return Math.min(customerAdvance, total);
    }

    function loadCustomerBalances(customerId) {
        if (!customerId) {
            customerAdvance = 0;
            customerDue = 0;
            customerBalancePanel.style.display = 'none';
            adjustHint.textContent = '';
            syncPaidBalance(true);
            return;
        }
        fetch(contextPath + '/exchange/getCustomerBalance.jsp?customerId=' + encodeURIComponent(customerId))
            .then(function(res) { return res.json(); })
            .then(function(data) {
                if (data && data.success) {
                    customerAdvance = parseFloat(data.advance || '0') || 0;
                    customerDue = parseFloat(data.due || '0') || 0;
                    customerAdvanceDisplay.textContent = customerAdvance.toFixed(4);
                    customerDueDisplay.textContent = customerDue.toFixed(4);
                    customerBalancePanel.style.display = 'block';
                    syncPaidBalance(true);
                } else {
                    customerAdvance = 0;
                    customerDue = 0;
                    customerBalancePanel.style.display = 'none';
                    syncPaidBalance(true);
                }
            })
            .catch(function() {
                customerAdvance = 0;
                customerDue = 0;
                customerBalancePanel.style.display = 'none';
                syncPaidBalance(true);
            });
    }

    function syncPaidBalance(resetPaid) {
        const total = parseFloat(counterAmountInput.value) || 0;
        const isPurchase = document.getElementById('typePurchase').checked;
        const adjusted = getAdjustmentAmount(total);
        const payableAfterAdjust = Math.max(0, total - adjusted);

        adjustedAmountInput.value = adjusted > 0 ? adjusted.toFixed(4) : '0';
        adjustedLabel.textContent = isPurchase ? 'Due Adjusted' : 'Advance Adjusted';

        if (adjusted > 0) {
            if (isPurchase) {
                adjustHint.textContent = 'Due ' + adjusted.toFixed(4) + ' will be adjusted against this bill. Pay/collect up to ' + payableAfterAdjust.toFixed(4) + '.';
            } else {
                adjustHint.textContent = 'Purchase balance ' + adjusted.toFixed(4) + ' will be adjusted against this bill. Collect up to ' + payableAfterAdjust.toFixed(4) + '.';
            }
        } else if (document.getElementById('customerId').value) {
            adjustHint.textContent = isPurchase
                ? 'No due balance to adjust on this bill.'
                : 'No purchase balance to adjust on this bill.';
        } else {
            adjustHint.textContent = '';
        }

        if (resetPaid) {
            syncingPaid = true;
            paidInput.value = payableAfterAdjust > 0 ? payableAfterAdjust.toFixed(4) : '0';
            syncingPaid = false;
        }
        let paid = parseFloat(paidInput.value);
        if (isNaN(paid) || paid < 0) paid = 0;
        if (paid > payableAfterAdjust) {
            paid = payableAfterAdjust;
            if (!syncingPaid) {
                syncingPaid = true;
                paidInput.value = payableAfterAdjust.toFixed(4);
                syncingPaid = false;
            }
        }
        const bal = Math.max(0, payableAfterAdjust - paid);
        balanceInput.value = bal.toFixed(4);
        updateBalanceHint(bal);
        updateCounterHints();
    }

    function updateBalanceHint(bal) {
        const isPurchase = document.getElementById('typePurchase').checked;
        if (!bal || bal <= 0) {
            balanceHint.textContent = '';
            balanceHint.style.color = '#64748b';
            return;
        }
        if (isPurchase) {
            balanceHint.textContent = 'Unpaid amount will be added to customer advance (shop owes customer)';
            balanceHint.style.color = '#0f766e';
        } else {
            balanceHint.textContent = 'Unpaid amount will be added to customer due (customer owes shop)';
            balanceHint.style.color = '#dc2626';
        }
    }

    function getCurrencyById(id) {
        return currenciesData.find(function(c) { return String(c.id) === String(id); });
    }

    function buildCurrencyOption(c) {
        const opt = document.createElement('option');
        opt.value = c.id;
        opt.textContent = c.code + ' — ' + c.name + ' (Stock: ' + c.stock + ')';
        opt.dataset.min = c.min;
        opt.dataset.max = c.max;
        opt.dataset.stock = c.stock;
        opt.dataset.code = c.code;
        return opt;
    }

    function updateBaseCurrencyDisplay() {
        if (!baseCurrency) {
            counterCurrencyDisplay.value = '';
            counterCurrencyIdInput.value = '';
            counterStockHint.textContent = 'Set a base currency in Currency Master before saving exchanges.';
            counterStockHint.style.color = '#dc2626';
            return;
        }
        counterCurrencyDisplay.value = baseCurrency.code + ' — ' + baseCurrency.name + ' (Stock: ' + parseFloat(baseCurrency.stock || '0').toFixed(4) + ')';
        counterCurrencyIdInput.value = baseCurrencyId;
        updateCounterHints();
    }

    function loadCurrencies() {
        fetch(contextPath + '/exchange/getCurrencies.jsp')
            .then(function(res) { return res.json(); })
            .then(function(data) {
                currenciesData = (data && data.currencies) ? data.currencies : (data || []);
                baseCurrencyId = (data && data.baseCurrencyId) ? data.baseCurrencyId : 0;
                baseCurrency = currenciesData.find(function(c) { return String(c.id) === String(baseCurrencyId); }) || null;
                renderCurrencyOptions();
            })
            .catch(function(err) { console.error(err); });
    }

    function renderCurrencyOptions() {
        const mainSelected = currencySelect.value;
        currencySelect.innerHTML = '<option value="">Select currency</option>';
        currenciesData.forEach(function(c) {
            const opt = buildCurrencyOption(c);
            if (String(c.id) === String(baseCurrencyId)) {
                opt.textContent = c.code + ' — ' + c.name + ' (Base / Stock: ' + c.stock + ')';
            }
            currencySelect.appendChild(opt);
        });
        if (mainSelected) {
            currencySelect.value = mainSelected;
        }
        updateBaseCurrencyDisplay();
        fetchPairLimits();
    }

    function updateCurrencyHints() {
        const opt = currencySelect.options[currencySelect.selectedIndex];
        const isSale = document.getElementById('typeSale').checked;
        limitHint.textContent = '';
        if (!opt || !opt.value) {
            stockHint.textContent = '';
            return;
        }
        if (isBaseToBase()) {
            const stock = parseFloat(opt.dataset.stock || '0');
            const amt = parseFloat(amountInput.value) || 0;
            if (isSale) {
                stockHint.textContent = 'Base sale: stock will decrease by ' + amt.toFixed(4) + ' (available ' + stock.toFixed(4) + ')';
                stockHint.style.color = (amt > 0 && amt > stock) ? '#dc2626' : '#0f766e';
            } else {
                stockHint.textContent = 'Base purchase: stock will increase by ' + amt.toFixed(4) + ' → ' + (stock + amt).toFixed(4);
                stockHint.style.color = '#0f766e';
            }
            return;
        }
        const stock = parseFloat(opt.dataset.stock || '0');
        const amt = parseFloat(amountInput.value) || 0;
        if (isSale) {
            stockHint.textContent = 'Available stock: ' + stock.toFixed(4) + ' ' + opt.dataset.code;
            stockHint.style.color = (amt > 0 && amt > stock) ? '#dc2626' : '#0f766e';
        } else {
            stockHint.textContent = 'Stock after purchase: ' + (stock + amt).toFixed(4) + ' ' + opt.dataset.code;
            stockHint.style.color = '#0f766e';
        }
    }

    function updateCounterHints() {
        const isPurchase = document.getElementById('typePurchase').checked;
        if (!baseCurrency) {
            counterStockHint.textContent = 'Set a base currency in Currency Master before saving exchanges.';
            counterStockHint.style.color = '#dc2626';
            return;
        }

        const stock = parseFloat(baseCurrency.stock || '0');
        const paidAmt = parseFloat(paidInput.value) || 0;
        const counterCode = baseCurrency.code;

        if (!isCashPayment()) {
            counterStockHint.textContent = 'Non-cash payment — ' + counterCode + ' stock will not change';
            counterStockHint.style.color = '#64748b';
            return;
        }

        if (isBaseToBase()) {
            const amt = parseFloat(amountInput.value) || 0;
            if (isPurchase) {
                counterStockHint.textContent = 'Base purchase: ' + counterCode + ' stock increases by ' + amt.toFixed(4);
                counterStockHint.style.color = '#0f766e';
            } else {
                counterStockHint.textContent = 'Base sale: ' + counterCode + ' stock decreases by ' + amt.toFixed(4)
                    + ' (available ' + stock.toFixed(4) + ')';
                counterStockHint.style.color = (amt > 0 && amt > stock) ? '#dc2626' : '#0f766e';
            }
            return;
        }

        if (isPurchase) {
            counterStockHint.textContent = 'Available stock: ' + stock.toFixed(4) + ' ' + counterCode + ' (will decrease by paid amount on cash purchase)';
            counterStockHint.style.color = (paidAmt > 0 && paidAmt > stock) ? '#dc2626' : '#0f766e';
        } else {
            counterStockHint.textContent = 'Stock after cash sale: ' + (stock + paidAmt).toFixed(4) + ' ' + counterCode + ' (increases by paid amount)';
            counterStockHint.style.color = '#0f766e';
        }
    }

    function updateTypeLabels() {
        const isPurchase = document.getElementById('typePurchase').checked;
        document.getElementById('mainSectionTitle').textContent = isPurchase ? 'Purchase Currency' : 'Sale Currency';
        document.getElementById('currencyLabel').textContent = isPurchase ? 'Purchase Currency' : 'Sale Currency';
        document.getElementById('amountLabel').textContent = isPurchase ? 'Purchase Amount' : 'Sale Amount';
        document.getElementById('counterSectionTitle').textContent = 'Base Currency';
        document.getElementById('counterCurrencyLabel').textContent = 'Base Currency';
        document.getElementById('counterAmountLabel').textContent = isPurchase ? 'Paying Amount (Base)' : 'Receiving Amount (Base)';
        document.getElementById('paidLabel').textContent = isPurchase ? 'Paid to Customer' : 'Paid by Customer';
        document.getElementById('balanceLabel').textContent = isPurchase ? 'Balance (Advance)' : 'Balance (Due)';
        updateCurrencyHints();
        updateCounterHints();
        updateBalanceHint(parseFloat(balanceInput.value) || 0);
    }

    document.querySelectorAll('input[name="exchangeType"]').forEach(function(el) {
        el.addEventListener('change', function() {
            updateTypeLabels();
            syncPaidBalance(true);
        });
    });

    currencySelect.addEventListener('change', function() {
        updateCurrencyHints();
        fetchPairLimits();
    });
    paymentSelect.addEventListener('change', updateCounterHints);
    amountInput.addEventListener('input', calculateCounterAmount);
    exchangeRateInput.addEventListener('input', calculateCounterAmount);
    paidInput.addEventListener('input', function() {
        if (!syncingPaid) syncPaidBalance(false);
    });

    searchInput.addEventListener('input', function() {
        clearTimeout(searchTimer);
        document.getElementById('customerId').value = '';
        document.getElementById('customerName').value = this.value.trim();
        loadCustomerBalances('');
        const query = this.value.trim();
        if (query.length < 1) {
            searchResults.style.display = 'none';
            return;
        }
        searchTimer = setTimeout(function() {
            fetch(contextPath + '/customer/enquiry/searchCustomer.jsp?query=' + encodeURIComponent(query))
                .then(function(res) { return res.json(); })
                .then(function(data) {
                    searchResults.innerHTML = '';
                    if (!data || data.length === 0) {
                        searchResults.innerHTML = '<div class="item text-muted">No match — new customer will be created on save</div>';
                    } else {
                        data.forEach(function(item) {
                            const div = document.createElement('div');
                            div.className = 'item';
                            div.textContent = item.name + ' - ' + (item.phone || 'No phone');
                            div.addEventListener('click', function() {
                                document.getElementById('customerId').value = item.id;
                                document.getElementById('customerName').value = item.name;
                                searchInput.value = item.name;
                                document.getElementById('customerPhone').value = item.phone || '';
                                searchResults.style.display = 'none';
                                loadCustomerBalances(item.id);
                            });
                            searchResults.appendChild(div);
                        });
                    }
                    searchResults.style.display = 'block';
                });
        }, 250);
    });

    document.addEventListener('click', function(e) {
        if (!searchResults.contains(e.target) && e.target !== searchInput) {
            searchResults.style.display = 'none';
        }
    });

    document.getElementById('exchangeForm').addEventListener('submit', function(e) {
        const opt = currencySelect.options[currencySelect.selectedIndex];
        const amt = parseFloat(amountInput.value);
        const rate = parseFloat(exchangeRateInput.value);
        const counterAmt = parseFloat(counterAmountInput.value);
        const paidAmt = parseFloat(paidInput.value);
        const adjustedAmt = parseFloat(adjustedAmountInput.value) || 0;
        const payableAfterAdjust = Math.max(0, counterAmt - adjustedAmt);
        const balAmt = parseFloat(balanceInput.value) || 0;
        const isSale = document.getElementById('typeSale').checked;
        const isPurchase = document.getElementById('typePurchase').checked;
        const mainCode = getSelectedCode(currencySelect);
        const counterCode = getBaseCurrencyCode();

        if (!baseCurrencyId || !baseCurrency) {
            e.preventDefault();
            alert('Base currency is not configured. Set it in Currency Master first.');
            return;
        }

        if (!currencySelect.value) {
            e.preventDefault();
            alert('Please select a currency');
            return;
        }

        if (isBaseToBase()) {
            if (!amt || amt <= 0) {
                e.preventDefault();
                alert('Please enter a valid amount');
                return;
            }
        } else {
            if (!rate || rate <= 0) {
                e.preventDefault();
                alert('Please enter a valid exchange rate');
                return;
            }

            if (pairLimits.hasLimit && (rate < pairLimits.min || rate > pairLimits.max)) {
                e.preventDefault();
                alert('Exchange rate must be between ' + pairLimits.min.toFixed(4) + ' and ' + pairLimits.max.toFixed(4)
                    + ' ' + counterCode + ' per 1 ' + mainCode);
                return;
            }
        }

        if (!counterAmt || counterAmt <= 0) {
            e.preventDefault();
            alert('Base currency amount could not be calculated. Check amount and rate.');
            return;
        }

        if (isSale && opt && opt.dataset.stock) {
            const stock = parseFloat(opt.dataset.stock);
            if (amt > stock) {
                e.preventDefault();
                alert('Insufficient sale currency stock. Available: ' + stock.toFixed(4) + ' ' + opt.dataset.code);
                return;
            }
        }

        if (isNaN(paidAmt) || paidAmt < 0) {
            e.preventDefault();
            alert('Please enter a valid paid amount');
            return;
        }

        if (paidAmt > payableAfterAdjust + 0.0001) {
            e.preventDefault();
            alert('Paid amount cannot exceed ' + payableAfterAdjust.toFixed(4) + ' after balance adjustment');
            return;
        }

        const expectedBal = Math.round((payableAfterAdjust - paidAmt) * 10000) / 10000;
        if (Math.abs(balAmt - expectedBal) > 0.0001) {
            syncPaidBalance(false);
        }

        if (balAmt > 0 && !searchInput.value.trim()) {
            e.preventDefault();
            alert('Customer is required when there is a balance amount');
            return;
        }

        if (isPurchase && !isBaseToBase() && isCashPayment() && baseCurrency) {
            const counterStock = parseFloat(baseCurrency.stock || '0');
            if (paidAmt > counterStock) {
                e.preventDefault();
                alert('Insufficient base currency stock for cash payment. Available: ' + counterStock.toFixed(4) + ' ' + counterCode);
                return;
            }
        }

        if (!document.getElementById('customerId').value) {
            document.getElementById('customerName').value = searchInput.value.trim();
        }
    });

    document.getElementById('resetBtn').addEventListener('click', function() {
        setTimeout(function() {
            document.getElementById('customerId').value = '';
            document.getElementById('customerName').value = '';
            customerAdvance = 0;
            customerDue = 0;
            customerBalancePanel.style.display = 'none';
            adjustHint.textContent = '';
            exchangeRateInput.value = '';
            counterAmountInput.value = '';
            paidInput.value = '0';
            adjustedAmountInput.value = '0';
            balanceInput.value = '0';
            balanceHint.textContent = '';
            fetchPairLimits().then(function() {
                updateCurrencyHints();
                updateCounterHints();
                updateTypeLabels();
            });
        }, 0);
    });

    loadCurrencies();
    updateTypeLabels();

    <% if (msg != null && !msg.trim().isEmpty()) { %>
    document.addEventListener('DOMContentLoaded', function() {
        Swal.fire({
            icon: '<%= (type != null && type.equals("success")) ? "success" : "error" %>',
            title: '<%= (type != null && type.equals("success")) ? "Success" : "Error" %>',
            text: '<%= jsMsg %>'
        });
        if (window.history.replaceState) {
            window.history.replaceState({}, document.title, window.location.pathname);
        }
    });
    <% } %>
</script>
</body>
</html>
