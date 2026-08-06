
    // Print function
    function printReport(titles) {
    // Get table HTML
    var table = document.getElementById("printTable").outerHTML;

    // Open new window
    var newWin = window.open("", "_blank");
    newWin.document.write(`
        <html>
        <head>
            <title>Billing Report</title>
            <style>
                .header-box {
  border: 1px solid #000;
  padding: 10px;
  margin-bottom: 12px;
  text-align: center;
}
.header-box h1 {
  font-size: 26px;
  margin-bottom: 4px;
}
.header-box p {
  margin: 2px 0;
  font-weight: bold;
}
                /* Force all text to black */
                body, h1, h2, h3, h4, h5, h6, p, span, td, th, a, div {
                    color: #000 !important;
                }

                /* Table styles */
                table { 
                    border-collapse: collapse !important; 
                    width: 100%; 
                    font-size: 12px; 
                    color: #000 !important; 
                }
                table, th, td { 
                    border: 1px solid black !important; 
                    padding: 5px !important; 
                    color: #000 !important; 
                }
                th { 
                    background: #ccc !important; 
                    color: #000 !important; 
                }

                a { 
                    color: #000 !important; 
                    text-decoration: none !important; 
                }

                button { display: none !important; } /* hide buttons in print */
            </style>
        </head>
        <body>
            <div class="header-box">
    <h1>SAI DHEETSHA HEART CARE HOSPITAL</h1>
    <p>No:1051, E.V.N Road, G.H Opp, Erode - 638009</p>
    <p>Phone - 9003624989 , 04244031155</p>
  </div>
            <h3> ${titles}</h3>
            ${table}
        </body>
        </html>
    `);
    newWin.document.close();
    newWin.focus();
    newWin.print();
    newWin.close();
}

    function csvEscapeCell(val) {
        if (val === null || val === undefined) val = '';
        val = String(val).replace(/\r\n/g, '\n').replace(/\r/g, '\n');
        if (/[",\n]/.test(val)) {
            return '"' + val.replace(/"/g, '""') + '"';
        }
        return val;
    }

    function downloadCsvFile(filename, lines) {
        filename = filename ? String(filename) : 'export';
        filename = filename.replace(/\.(xlsx|xls|csv)$/i, '') + '.csv';

        var blob = new Blob(['\ufeff' + lines.join('\r\n')], { type: 'text/csv;charset=utf-8' });
        if (navigator.msSaveOrOpenBlob) {
            navigator.msSaveOrOpenBlob(blob, filename);
            return;
        }

        var url = URL.createObjectURL(blob);
        var downloadLink = document.createElement('a');
        downloadLink.href = url;
        downloadLink.download = filename;
        document.body.appendChild(downloadLink);
        downloadLink.click();
        document.body.removeChild(downloadLink);
        setTimeout(function() { URL.revokeObjectURL(url); }, 1000);
    }

    // Export table data as CSV (opens reliably in Excel)
    function exportTableToExcel(tableID, filename) {
        var el = document.getElementById(tableID);
        if (!el) return;

        var lines = [];
        var meta = el.querySelector('.print-meta');
        if (meta) {
            var title = meta.querySelector('h2, h3');
            if (title) lines.push(csvEscapeCell(title.innerText.trim()));
            meta.querySelectorAll('p').forEach(function(p) {
                lines.push(csvEscapeCell(p.innerText.trim()));
            });
            meta.querySelectorAll('.balance-summary span').forEach(function(span) {
                lines.push(csvEscapeCell(span.innerText.trim()));
            });
            lines.push('');
        }

        var headerBox = el.querySelector('.header-box');
        if (headerBox && !meta) {
            headerBox.querySelectorAll('h1, p').forEach(function(node) {
                lines.push(csvEscapeCell(node.innerText.trim()));
            });
            lines.push('');
        }

        var table = el.tagName === 'TABLE' ? el : el.querySelector('table');
        if (!table) {
            alert('No table found to export');
            return;
        }

        table.querySelectorAll('tr').forEach(function(tr) {
            var cells = [];
            tr.querySelectorAll('th, td').forEach(function(cell) {
                cells.push(csvEscapeCell(cell.innerText.trim().replace(/\s+/g, ' ')));
            });
            if (cells.length) lines.push(cells.join(','));
        });

        downloadCsvFile(filename, lines);
    }

    function exportTableToPdf(tableID, title) {
        var table = document.getElementById(tableID);
        if (!table) return;

        var newWin = window.open("", "_blank");
        newWin.document.write(`
        <html>
        <head>
            <title>${title || 'Report'}</title>
            <style>
                body, h1, h2, h3, h4, h5, h6, p, span, td, th, a, div { color: #000 !important; }
                table { border-collapse: collapse !important; width: 100%; font-size: 12px; }
                table, th, td { border: 1px solid black !important; padding: 5px !important; }
                th { background: #ccc !important; }
            </style>
        </head>
        <body>
            <h3>${title || 'Report'}</h3>
            ${table.outerHTML}
        </body>
        </html>
        `);
        newWin.document.close();
        newWin.focus();
        setTimeout(function() { newWin.print(); }, 300);
    }
