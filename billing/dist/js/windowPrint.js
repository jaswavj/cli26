
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

    // Export to Excel function
    function exportTableToExcel(tableID, filename = '') {
        var table = document.getElementById(tableID);
        var tableHTML = table.outerHTML.replace(/ /g, '%20');

        // Specify file name
        filename = filename ? filename + '.xls' : 'excel_data.xls';

        // Create download link
        var downloadLink = document.createElement("a");
        document.body.appendChild(downloadLink);

        if (navigator.msSaveOrOpenBlob) {
            // For IE
            var blob = new Blob(['\ufeff', tableHTML], { type: 'application/vnd.ms-excel' });
            navigator.msSaveOrOpenBlob(blob, filename);
        } else {
            // For other browsers
            downloadLink.href = 'data:application/vnd.ms-excel,' + tableHTML;
            downloadLink.download = filename;
            downloadLink.click();
        }
    }
