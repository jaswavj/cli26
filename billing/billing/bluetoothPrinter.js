/**
 * Bluetooth Thermal Printer for Mobile Devices
 * Uses Web Bluetooth API to print ESC/POS receipts from mobile browsers
 * Compatible with: Chrome/Edge on Android (iOS Safari not supported)
 */

// ESC/POS Command Constants
const ESC = 0x1B;
const GS = 0x1D;

const ESC_POS = {
    INIT: [0x1B, 0x40],                    // Initialize printer
    BOLD_ON: [0x1B, 0x45, 0x01],           // Bold on
    BOLD_OFF: [0x1B, 0x45, 0x00],          // Bold off
    ALIGN_CENTER: [0x1B, 0x61, 0x01],      // Center align
    ALIGN_LEFT: [0x1B, 0x61, 0x00],        // Left align
    ALIGN_RIGHT: [0x1B, 0x61, 0x02],       // Right align
    FONT_NORMAL: [0x1B, 0x21, 0x00],       // Normal font
    FONT_DOUBLE_H: [0x1B, 0x21, 0x10],     // Double height
    FONT_B: [0x1B, 0x4D, 0x01],            // Font B (small/compact)
    FONT_A: [0x1B, 0x4D, 0x00],            // Font A (default)
    CUT_PAPER: [0x1D, 0x56, 0x01],         // Partial cut
    FEED_2_LINES: [0x1B, 0x64, 0x02],      // Feed 2 lines
    FEED_3_LINES: [0x1B, 0x64, 0x03],      // Feed 3 lines
    LF: [0x0A]                             // Line feed
};

// Receipt configuration
const RECEIPT_WIDTH_58MM = 32;
const RECEIPT_WIDTH_80MM = 48;
let RECEIPT_WIDTH = RECEIPT_WIDTH_80MM; // Default

// Bluetooth connection state
let bluetoothDevice = null;
let bluetoothCharacteristic = null;
let isConnected = false;

/**
 * Check if device is mobile
 */
function isMobileDevice() {
    return /Android|webOS|iPhone|iPad|iPod|BlackBerry|IEMobile|Opera Mini/i.test(navigator.userAgent);
}

/**
 * Check if Web Bluetooth API is supported
 */
function isWebBluetoothSupported() {
    return 'bluetooth' in navigator;
}

/**
 * Check if mobile Bluetooth printing is available
 */
function isBluetoothPrintAvailable() {
    return isMobileDevice() && isWebBluetoothSupported();
}

/**
 * Connect to Bluetooth thermal printer
 * @returns {Promise<boolean>} Connection success status
 */
async function connectBluetoothPrinter() {
    try {
        console.log('Requesting Bluetooth device...');
        
        // Request Bluetooth device (will show pairing dialog)
        bluetoothDevice = await navigator.bluetooth.requestDevice({
            filters: [
                { services: ['000018f0-0000-1000-8000-00805f9b34fb'] }, // Generic printer service
            ],
            optionalServices: [
                '000018f0-0000-1000-8000-00805f9b34fb',
                '49535343-fe7d-4ae5-8fa9-9fafd205e455' // Some thermal printers use this
            ]
        });

        console.log('Connecting to GATT Server...');
        const server = await bluetoothDevice.gatt.connect();
        
        console.log('Getting Service...');
        let service;
        try {
            service = await server.getPrimaryService('000018f0-0000-1000-8000-00805f9b34fb');
        } catch (e) {
            // Try alternate service UUID
            service = await server.getPrimaryService('49535343-fe7d-4ae5-8fa9-9fafd205e455');
        }
        
        console.log('Getting Characteristic...');
        try {
            bluetoothCharacteristic = await service.getCharacteristic('00002af1-0000-1000-8000-00805f9b34fb');
        } catch (e) {
            // Try alternate characteristic
            bluetoothCharacteristic = await service.getCharacteristic('49535343-8841-43f4-a8d4-ecbe34729bb3');
        }
        
        isConnected = true;
        
        // Store device info for reconnection
        if (bluetoothDevice.name) {
            localStorage.setItem('lastBluetoothPrinter', bluetoothDevice.name);
        }
        
        console.log('Bluetooth printer connected:', bluetoothDevice.name);
        return true;
        
    } catch (error) {
        console.error('Bluetooth connection error:', error);
        isConnected = false;
        
        if (error.name === 'NotFoundError') {
            throw new Error('No Bluetooth printer found. Make sure printer is turned on and in pairing mode.');
        } else if (error.name === 'SecurityError') {
            throw new Error('Bluetooth access denied. Please allow Bluetooth permission in browser settings.');
        } else {
            throw new Error('Failed to connect to printer: ' + error.message);
        }
    }
}

/**
 * Disconnect from Bluetooth printer
 */
function disconnectBluetoothPrinter() {
    if (bluetoothDevice && bluetoothDevice.gatt.connected) {
        bluetoothDevice.gatt.disconnect();
        console.log('Bluetooth printer disconnected');
    }
    bluetoothDevice = null;
    bluetoothCharacteristic = null;
    isConnected = false;
}

/**
 * Send data to Bluetooth printer
 * @param {Uint8Array} data - ESC/POS command data
 */
async function sendToBluetoothPrinter(data) {
    if (!isConnected || !bluetoothCharacteristic) {
        throw new Error('Printer not connected');
    }
    
    try {
        // Split data into chunks (Bluetooth has MTU limitations)
        const chunkSize = 512; // Safe size for most printers
        for (let i = 0; i < data.length; i += chunkSize) {
            const chunk = data.slice(i, i + chunkSize);
            await bluetoothCharacteristic.writeValue(chunk);
            // Small delay between chunks to prevent buffer overflow
            if (i + chunkSize < data.length) {
                await new Promise(resolve => setTimeout(resolve, 50));
            }
        }
        console.log('Data sent to printer successfully');
        return true;
    } catch (error) {
        console.error('Error sending to printer:', error);
        throw new Error('Failed to send data to printer: ' + error.message);
    }
}

/**
 * Main function: Print bill via Bluetooth
 * @param {string} billNo - Bill number to print
 */
async function bluetoothPrint(billNo) {
    try {
        // Show loading indicator
        showBluetoothPrintStatus('Preparing receipt...', 'info');
        
        // Connect to printer if not already connected
        if (!isConnected) {
            showBluetoothPrintStatus('Connecting to printer...', 'info');
            await connectBluetoothPrinter();
        }
        
        // Fetch bill data
        showBluetoothPrintStatus('Loading bill data...', 'info');
        const billData = await fetchBillData(billNo);
        
        // Generate ESC/POS commands
        showBluetoothPrintStatus('Generating receipt...', 'info');
        const escposData = generateESCPOSReceipt(billData);
        
        // Send to printer
        showBluetoothPrintStatus('Printing...', 'info');
        await sendToBluetoothPrinter(escposData);
        
        // Success
        showBluetoothPrintStatus('Receipt printed successfully!', 'success');
        
        // Auto-dismiss after 2 seconds
        setTimeout(() => {
            hideBluetoothPrintStatus();
        }, 2000);
        
    } catch (error) {
        console.error('Bluetooth print error:', error);
        showBluetoothPrintStatus('Print failed: ' + error.message, 'error', true);
        
        // Offer fallback
        if (confirm('Bluetooth printing failed. Open browser print preview instead?')) {
            openPrintPreview(billNo);
        }
    }
}

/**
 * Fetch bill data from server
 * @param {string} billNo - Bill number
 * @returns {Promise<Object>} Bill data
 */
async function fetchBillData(billNo) {
    const response = await fetch(`getBillData.jsp?billNo=${encodeURIComponent(billNo)}`);
    if (!response.ok) {
        throw new Error('Failed to fetch bill data');
    }
    const data = await response.json();
    if (!data.success) {
        throw new Error(data.message || 'Failed to load bill data');
    }
    return data;
}

/**
 * Generate ESC/POS receipt commands
 * @param {Object} billData - Bill data from server
 * @returns {Uint8Array} ESC/POS command bytes
 */
function generateESCPOSReceipt(billData) {
    const commands = [];
    
    // Initialize printer
    commands.push(...ESC_POS.INIT);
    commands.push(...ESC_POS.FONT_NORMAL);
    commands.push(...ESC_POS.FONT_A);
    
    // ===== COMPANY HEADER =====
    commands.push(...ESC_POS.ALIGN_CENTER);
    commands.push(...ESC_POS.BOLD_ON);
    commands.push(...stringToBytes(billData.company.name + '\n'));
    commands.push(...ESC_POS.BOLD_OFF);
    
    // Company address (handle multi-line)
    if (billData.company.address) {
        const addressLines = billData.company.address.split('\n');
        addressLines.forEach(line => {
            if (line.trim()) {
                commands.push(...stringToBytes(line.trim() + '\n'));
            }
        });
    }
    
    // Company GSTIN
    if (billData.company.gstin) {
        commands.push(...stringToBytes('GSTIN: ' + billData.company.gstin + '\n'));
    }
    
    commands.push(...divider());
    
    // ===== BILL INFO =====
    commands.push(...ESC_POS.ALIGN_LEFT);
    const billLine = padRight('Bill: ' + billData.billNo, RECEIPT_WIDTH - billData.billDate.length) + billData.billDate + '\n';
    commands.push(...stringToBytes(billLine));
    
    // ===== CUSTOMER INFO =====
    commands.push(...stringToBytes('Cust: ' + billData.customer.name + '\n'));
    if (billData.customer.phone && billData.customer.phone !== '-') {
        commands.push(...stringToBytes('Ph: ' + billData.customer.phone + '\n'));
    }
    if (billData.customer.gstin && billData.customer.gstin !== '-') {
        commands.push(...stringToBytes('GSTIN: ' + billData.customer.gstin + '\n'));
    }
    
    commands.push(...divider());
    
    // ===== ITEMS HEADER =====
    commands.push(...ESC_POS.BOLD_ON);
    commands.push(...stringToBytes(formatItemHeader()));
    commands.push(...ESC_POS.BOLD_OFF);
    commands.push(...divider());
    
    // ===== ITEMS =====
    billData.items.forEach(item => {
        commands.push(...stringToBytes(formatItemRow(
            item.name,
            item.qty.toString(),
            formatNumber(item.price),
            formatNumber(item.total),
            item.gstPercent
        )));
        
        if (item.discount > 0) {
            commands.push(...stringToBytes(padLeft('Disc: -' + formatNumber(item.discount), RECEIPT_WIDTH) + '\n'));
        }
    });
    
    commands.push(...divider());
    
    // ===== TOTALS =====
    commands.push(...stringToBytes(formatTotalRow('Items:', billData.totals.itemCount.toString())));
    
    if (billData.totals.itemDiscount > 0) {
        commands.push(...stringToBytes(formatTotalRow('Item Disc:', '-Rs ' + formatNumber(billData.totals.itemDiscount))));
    }
    if (billData.totals.extraDiscount > 0) {
        commands.push(...stringToBytes(formatTotalRow('Extra Disc:', '-Rs ' + formatNumber(billData.totals.extraDiscount))));
    }
    
    commands.push(...divider());
    
    // TOTAL (bold)
    commands.push(...ESC_POS.BOLD_ON);
    commands.push(...stringToBytes(formatTotalRow('TOTAL:', 'Rs ' + formatNumber(billData.totals.total))));
    commands.push(...ESC_POS.BOLD_OFF);
    
    commands.push(...divider());
    
    commands.push(...stringToBytes(formatTotalRow('Paid:', 'Rs ' + formatNumber(billData.totals.paid))));
    
    if (billData.totals.balance !== 0) {
        commands.push(...ESC_POS.BOLD_ON);
        const label = billData.totals.balance > 0 ? 'Balance:' : 'Change:';
        commands.push(...stringToBytes(formatTotalRow(label, 'Rs ' + formatNumber(Math.abs(billData.totals.balance)))));
        commands.push(...ESC_POS.BOLD_OFF);
    }
    
    // ===== GST SUMMARY =====
    if (billData.gstSummary && billData.gstSummary.length > 0) {
        commands.push(...divider());
        commands.push(...ESC_POS.BOLD_ON);
        commands.push(...stringToBytes('GST Summary:\n'));
        commands.push(...ESC_POS.BOLD_OFF);
        
        billData.gstSummary.forEach(gst => {
            if (gst.rate > 0) {
                commands.push(...stringToBytes('GST' + gst.rate + '% Txbl:Rs' + formatNumber(gst.taxable) + '\n'));
                commands.push(...stringToBytes('CGST:Rs' + formatNumber(gst.cgst) + ' SGST:Rs' + formatNumber(gst.sgst) + '\n'));
            }
        });
        
        commands.push(...ESC_POS.BOLD_ON);
        commands.push(...stringToBytes(formatTotalRow('Total GST:', 'Rs ' + formatNumber(billData.totals.totalGST))));
        commands.push(...ESC_POS.BOLD_OFF);
    }
    
    commands.push(...divider());
    
    // ===== FOOTER =====
    commands.push(...ESC_POS.ALIGN_CENTER);
    commands.push(...stringToBytes(billData.totals.amountInWords.toUpperCase() + '\n'));
    commands.push(...stringToBytes('Thank You! Visit Again\n'));
    
    // Feed and cut
    commands.push(...ESC_POS.FEED_3_LINES);
    commands.push(...ESC_POS.CUT_PAPER);
    
    return new Uint8Array(commands);
}

// ===== FORMATTING HELPERS =====

function stringToBytes(str) {
    const encoder = new TextEncoder();
    return Array.from(encoder.encode(str));
}

function divider() {
    let line = '';
    for (let i = 0; i < RECEIPT_WIDTH; i++) line += '-';
    return stringToBytes(line + '\n');
}

function formatItemHeader() {
    if (RECEIPT_WIDTH === RECEIPT_WIDTH_58MM) {
        return padRight('ITEM', 18) + padRight('Q', 4) + padLeft('RATE', 5) + padLeft('AMT', 5) + '\n';
    } else {
        return padRight('ITEM', 28) + padRight('QTY', 6) + padLeft('RATE', 7) + padLeft('AMT', 7) + '\n';
    }
}

function formatItemRow(name, qty, rate, amt, gstPer) {
    let line = '';
    
    if (RECEIPT_WIDTH === RECEIPT_WIDTH_58MM) {
        const nameWidth = 18;
        if (gstPer > 0 && name.length < nameWidth - 4) {
            name = name + '(' + gstPer + '%)';
        }
        if (name.length > nameWidth) {
            name = name.substring(0, nameWidth);
        }
        line = padRight(name, nameWidth) + padRight(qty, 4) + padLeft(rate, 5) + padLeft(amt, 5);
    } else {
        const nameWidth = 28;
        if (gstPer > 0 && name.length < nameWidth - 5) {
            name = name + '(' + gstPer + '%)';
        }
        if (name.length > nameWidth) {
            name = name.substring(0, nameWidth);
        }
        line = padRight(name, nameWidth) + padRight(qty, 6) + padLeft(rate, 7) + padLeft(amt, 7);
    }
    
    return line + '\n';
}

function formatTotalRow(label, value) {
    const padding = RECEIPT_WIDTH - label.length - value.length;
    let line = label;
    for (let i = 0; i < Math.max(1, padding); i++) line += ' ';
    line += value;
    return line + '\n';
}

function padRight(str, width) {
    if (!str) str = '';
    if (str.length >= width) return str.substring(0, width);
    while (str.length < width) str += ' ';
    return str;
}

function padLeft(str, width) {
    if (!str) str = '';
    if (str.length >= width) return str;
    let result = '';
    while (result.length < width - str.length) result += ' ';
    return result + str;
}

function formatNumber(num) {
    return parseFloat(num).toFixed(2);
}

// ===== UI HELPERS =====

/**
 * Show Bluetooth print status message
 */
function showBluetoothPrintStatus(message, type = 'info', persistent = false) {
    // Remove existing status
    hideBluetoothPrintStatus();
    
    // Create status element
    const status = document.createElement('div');
    status.id = 'bluetoothPrintStatus';
    status.style.cssText = `
        position: fixed;
        top: 20px;
        right: 20px;
        z-index: 10000;
        padding: 15px 20px;
        border-radius: 8px;
        box-shadow: 0 4px 12px rgba(0,0,0,0.15);
        font-size: 14px;
        font-weight: 500;
        max-width: 300px;
        animation: slideIn 0.3s ease-out;
    `;
    
    // Set color based on type
    if (type === 'success') {
        status.style.backgroundColor = '#4CAF50';
        status.style.color = 'white';
        status.innerHTML = '<i class="fas fa-check-circle"></i> ' + message;
    } else if (type === 'error') {
        status.style.backgroundColor = '#f44336';
        status.style.color = 'white';
        status.innerHTML = '<i class="fas fa-exclamation-circle"></i> ' + message;
    } else {
        status.style.backgroundColor = '#2196F3';
        status.style.color = 'white';
        status.innerHTML = '<i class="fas fa-bluetooth"></i> ' + message;
    }
    
    // Add close button for errors
    if (type === 'error' || persistent) {
        const closeBtn = document.createElement('span');
        closeBtn.innerHTML = ' <i class="fas fa-times" style="cursor:pointer;margin-left:10px;"></i>';
        closeBtn.onclick = hideBluetoothPrintStatus;
        status.appendChild(closeBtn);
    }
    
    document.body.appendChild(status);
    
    // Add animation
    const style = document.createElement('style');
    style.textContent = `
        @keyframes slideIn {
            from { transform: translateX(400px); opacity: 0; }
            to { transform: translateX(0); opacity: 1; }
        }
    `;
    document.head.appendChild(style);
}

function hideBluetoothPrintStatus() {
    const status = document.getElementById('bluetoothPrintStatus');
    if (status) {
        status.remove();
    }
}

/**
 * Print order receipt via Bluetooth (for mobile devices)
 * @param {string} orderId - Order ID to print
 */
async function bluetoothPrintOrder(orderId) {
    try {
        // Show loading indicator
        showBluetoothPrintStatus('Preparing order receipt...', 'info');
        
        // Connect to printer if not already connected
        if (!isConnected) {
            showBluetoothPrintStatus('Connecting to printer...', 'info');
            await connectBluetoothPrinter();
        }
        
        // Fetch order data
        showBluetoothPrintStatus('Loading order data...', 'info');
        const orderData = await fetchOrderData(orderId);
        
        // Generate ESC/POS commands
        showBluetoothPrintStatus('Generating receipt...', 'info');
        const escposData = generateESCPOSOrderReceipt(orderData);
        
        // Send to printer
        showBluetoothPrintStatus('Printing...', 'info');
        await sendToBluetoothPrinter(escposData);
        
        // Success
        showBluetoothPrintStatus('Order receipt printed successfully!', 'success');
        
        // Auto-dismiss after 2 seconds
        setTimeout(() => {
            hideBluetoothPrintStatus();
        }, 2000);
        
    } catch (error) {
        console.error('Bluetooth order print error:', error);
        showBluetoothPrintStatus('Print failed: ' + error.message, 'error', true);
        
        // Offer fallback
        if (confirm('Bluetooth printing failed. Open browser print preview instead?')) {
            const width = 400;
            const height = 600;
            const left = (screen.width - width) / 2;
            const top = (screen.height - height) / 2;
            window.open(`thermalPrintOrder.jsp?orderId=${encodeURIComponent(orderId)}`, 'OrderPrintWindow', 
                `width=${width},height=${height},left=${left},top=${top},scrollbars=yes,resizable=yes`);
        }
    }
}

/**
 * Fetch order data from server
 * @param {string} orderId - Order ID
 * @returns {Promise<Object>} Order data
 */
async function fetchOrderData(orderId) {
    const response = await fetch(`getOrderData.jsp?orderId=${encodeURIComponent(orderId)}`);
    if (!response.ok) {
        throw new Error('Failed to fetch order data');
    }
    const data = await response.json();
    if (!data.success) {
        throw new Error(data.message || 'Failed to load order data');
    }
    return data;
}

/**
 * Generate ESC/POS order receipt commands
 * @param {Object} orderData - Order data from server
 * @returns {Uint8Array} ESC/POS command bytes
 */
function generateESCPOSOrderReceipt(orderData) {
    const commands = [];
    
    // Initialize printer
    commands.push(...ESC_POS.INIT);
    commands.push(...ESC_POS.FONT_NORMAL);
    commands.push(...ESC_POS.FONT_A);
    
    // ===== COMPANY HEADER =====
    commands.push(...ESC_POS.ALIGN_CENTER);
    commands.push(...ESC_POS.BOLD_ON);
    commands.push(...ESC_POS.FONT_DOUBLE_H);
    commands.push(...stringToBytes('ORDER RECEIPT\n'));
    commands.push(...ESC_POS.FONT_NORMAL);
    commands.push(...ESC_POS.BOLD_OFF);
    
    if (orderData.company.name) {
        commands.push(...ESC_POS.BOLD_ON);
        commands.push(...stringToBytes(orderData.company.name + '\n'));
        commands.push(...ESC_POS.BOLD_OFF);
    }
    
    // Company address (handle multi-line)
    if (orderData.company.address) {
        const addressLines = orderData.company.address.split('\n');
        addressLines.forEach(line => {
            if (line.trim()) {
                commands.push(...stringToBytes(line.trim() + '\n'));
            }
        });
    }
    
    commands.push(...divider());
    
    // ===== ORDER INFO =====
    commands.push(...ESC_POS.ALIGN_LEFT);
    commands.push(...ESC_POS.BOLD_ON);
    commands.push(...stringToBytes('Order No: ' + orderData.order.orderNo + '\n'));
    commands.push(...stringToBytes('Table: ' + orderData.order.tableName + '\n'));
    commands.push(...ESC_POS.BOLD_OFF);
    
    const dateLine = padRight('Date: ' + orderData.order.date, RECEIPT_WIDTH - orderData.order.time.length - 6) + 'Time: ' + orderData.order.time + '\n';
    commands.push(...stringToBytes(dateLine));
    
    // Status
    commands.push(...stringToBytes('Status: ' + orderData.order.status + '\n'));
    
    commands.push(...divider());
    
    // ===== ITEMS HEADER =====
    commands.push(...ESC_POS.BOLD_ON);
    if (RECEIPT_WIDTH === RECEIPT_WIDTH_58MM) {
        commands.push(...stringToBytes(padRight('ITEM', 18) + padRight('Q', 4) + padLeft('RATE', 5) + padLeft('AMT', 5) + '\n'));
    } else {
        commands.push(...stringToBytes(padRight('ITEM', 28) + padRight('QTY', 6) + padLeft('RATE', 7) + padLeft('AMT', 7) + '\n'));
    }
    commands.push(...ESC_POS.BOLD_OFF);
    commands.push(...divider());
    
    // ===== ITEMS =====
    orderData.items.forEach(item => {
        let itemName = item.prodName;
        let qty = item.formattedQty;
        let rate = item.formattedPrice;
        let amt = item.formattedTotal;
        
        let line = '';
        if (RECEIPT_WIDTH === RECEIPT_WIDTH_58MM) {
            const nameWidth = 18;
            if (itemName.length > nameWidth) {
                itemName = itemName.substring(0, nameWidth);
            }
            line = padRight(itemName, nameWidth) + padRight(qty, 4) + padLeft(rate, 5) + padLeft(amt, 5);
        } else {
            const nameWidth = 28;
            if (itemName.length > nameWidth) {
                itemName = itemName.substring(0, nameWidth);
            }
            line = padRight(itemName, nameWidth) + padRight(qty, 6) + padLeft(rate, 7) + padLeft(amt, 7);
        }
        commands.push(...stringToBytes(line + '\n'));
    });
    
    commands.push(...divider());
    
    // ===== TOTAL =====
    commands.push(...ESC_POS.BOLD_ON);
    commands.push(...ESC_POS.FONT_DOUBLE_H);
    const totalLine = padLeft('TOTAL: Rs ' + orderData.totals.formattedGrandTotal, RECEIPT_WIDTH);
    commands.push(...stringToBytes(totalLine + '\n'));
    commands.push(...ESC_POS.FONT_NORMAL);
    commands.push(...ESC_POS.BOLD_OFF);
    
    commands.push(...divider());
    
    // ===== FOOTER =====
    commands.push(...ESC_POS.ALIGN_CENTER);
    commands.push(...stringToBytes('Thank You!\n'));
    
    // Feed and cut
    commands.push(...ESC_POS.FEED_3_LINES);
    commands.push(...ESC_POS.CUT_PAPER);
    
    return new Uint8Array(commands);
}

// ===== EXPORT FUNCTIONS =====
// Make functions available globally
window.bluetoothPrint = bluetoothPrint;
window.bluetoothPrintOrder = bluetoothPrintOrder;
window.isBluetoothPrintAvailable = isBluetoothPrintAvailable;
window.connectBluetoothPrinter = connectBluetoothPrinter;
window.disconnectBluetoothPrinter = disconnectBluetoothPrinter;
window.isMobileDevice = isMobileDevice;
window.isWebBluetoothSupported = isWebBluetoothSupported;

console.log('Bluetooth Printer Module Loaded');
console.log('Mobile Device:', isMobileDevice());
console.log('Web Bluetooth Supported:', isWebBluetoothSupported());
