package print;

import javax.print.*;
import javax.print.attribute.*;
import javax.print.attribute.standard.*;
import java.io.*;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.sql.*;
import java.awt.*;
import java.awt.print.*;
import java.awt.image.*;
import com.google.zxing.*;
import com.google.zxing.common.*;
import com.google.zxing.oned.*;

/**
 * Barcode Label Printer - renders all label rows on a single page
 * Uses PrinterJob with explicit Paper size to prevent blank label feed
 * Compatible with SNBC TVSE LP 46 NEO BPLE and thermal label printers
 */
public class BarcodePrinter {

    // Label dimensions
    private static final double MM_TO_PT = 72.0 / 25.4;
    private static final double LABEL_W_MM = 25.0;
    private static final double LABEL_H_MM = 28.0; // height is flexible, total page height will be rows * LABEL_H_MM
    private static final double SHEET_W_MM = 100.0;   // 3 labels x 25mm = 75mm (content width)
    private static final double PAPER_W_MM = 100.0;  // declared paper wider to shift content left
    private static final int COLS = 3;

    /**
     * Print barcode labels - all rows rendered on a single page
     */
    public static String printLabels(List<Map<String, String>> labelData) {
        try {
            String configuredPrinter = getConfiguredBarcodePrinter();
            
            PrintService printService = findPrintService(configuredPrinter, null);
            if (printService == null) {
                return "ERROR: No printer found. Please check printer connection.";
            }

            System.out.println("Using printer: " + printService.getName());

            // Flatten all labels (expand qty)
            List<Map<String, String>> allLabels = new ArrayList<Map<String, String>>();
            for (Map<String, String> label : labelData) {
                int qty = 1;
                try { qty = Integer.parseInt(label.getOrDefault("qty", "1")); } catch(Exception e) {}
                for (int i = 0; i < qty; i++) {
                    allLabels.add(label);
                }
            }

            if (allLabels.isEmpty()) {
                return "ERROR: No labels to print.";
            }

            // Group labels into rows of 3
            final List<List<Map<String, String>>> rows = new ArrayList<List<Map<String, String>>>();
            for (int i = 0; i < allLabels.size(); i += COLS) {
                List<Map<String, String>> row = new ArrayList<Map<String, String>>();
                for (int j = 0; j < COLS && (i + j) < allLabels.size(); j++) {
                    row.add(allLabels.get(i + j));
                }
                rows.add(row);
            }

            System.out.println("Printing " + allLabels.size() + " labels in " + rows.size() + " rows...");

            // Dimensions in points
            
            final double sheetWPt = SHEET_W_MM * MM_TO_PT;   // 75mm content
            final double paperWPt = PAPER_W_MM * MM_TO_PT;   // 100mm declared paper
            final double rowHPt = LABEL_H_MM * MM_TO_PT;
            final double labelWPt = sheetWPt / COLS;  // 25mm per label (fixed)
            final double totalHPt = rows.size() * rowHPt;

            // Use PrinterJob with explicit Paper size for precise control
            PrinterJob printerJob = PrinterJob.getPrinterJob();
            printerJob.setPrintService(printService);
            printerJob.setJobName("Barcode Labels");

            // Declare paper WIDER than content so driver doesn't center the 75mm onto the roll
            Paper paper = new Paper();
            paper.setSize(paperWPt, totalHPt);
            paper.setImageableArea(0, 0, paperWPt, totalHPt);

            PageFormat pageFormat = new PageFormat();
            pageFormat.setPaper(paper);
            pageFormat.setOrientation(PageFormat.PORTRAIT);

            // Single Printable - ALL rows rendered on ONE page
            Printable printable = new Printable() {
                public int print(Graphics graphics, PageFormat pf, int pageIndex) {
                    if (pageIndex > 0) {
                        return Printable.NO_SUCH_PAGE;
                    }

                    //Graphics2D g2d = (Graphics2D) graphics;
                    //g2d.setRenderingHint(RenderingHints.KEY_TEXT_ANTIALIASING,
                                         //RenderingHints.VALUE_TEXT_ANTIALIAS_ON);
Graphics2D g2d = (Graphics2D) graphics;

g2d.translate(pf.getImageableX(), pf.getImageableY());

g2d.setRenderingHint(RenderingHints.KEY_TEXT_ANTIALIASING,
                     RenderingHints.VALUE_TEXT_ANTIALIAS_ON);
                    // Java's Printable already sets (0,0) at the imageable area origin —
                    // no translate needed. Row 0 starts at y=0 (top of printable area).

                    // Use hardcoded 25mm-per-label constants.
                    // Never use pf.getImageableX()/getWidth() — the printer driver
                    // can report a shifted imageable origin (e.g. 25mm or 37.5mm)
                    // which causes labels to start printing from the centre of the roll.
                    // labelWPt = SHEET_W_MM/COLS * MM_TO_PT = exactly 25mm in points.
                    double actualLabelW = labelWPt;   // 25mm per column, always
                    System.out.println("Fixed label width: " + actualLabelW + "pt ("
                        + (actualLabelW / MM_TO_PT) + "mm) — driver imageable area ignored");

                    for (int r = 0; r < rows.size(); r++) {
                        List<Map<String, String>> row = rows.get(r);
                        double yOffset = r * rowHPt;   // starts at 0 (top of paper)

                        for (int col = 0; col < row.size(); col++) {
                            // col 0 → x=0mm, col 1 → x=25mm, col 2 → x=50mm (physical paper)
                            double xOffset = col * actualLabelW;
                            
                            // Clip to exact label area
                            Shape oldClip = g2d.getClip();
                            g2d.setClip((int) xOffset, (int) yOffset, (int) actualLabelW, (int) rowHPt);
                            renderLabel(g2d, row.get(col), xOffset, yOffset, actualLabelW, rowHPt);
                            g2d.setClip(oldClip);
                        }
                    }

                    return Printable.PAGE_EXISTS;
                }
            };

            printerJob.setPrintable(printable, pageFormat);

            // Set print attributes
            PrintRequestAttributeSet attrs = new HashPrintRequestAttributeSet();
            attrs.add(new MediaPrintableArea(0, 0,
                (float) PAPER_W_MM, (float)(rows.size() * LABEL_H_MM),
                MediaPrintableArea.MM));

            printerJob.print(attrs);
            System.out.println("Print job sent! " + allLabels.size() + " labels in " + rows.size() + " rows.");

            return "SUCCESS: " + allLabels.size() + " labels sent to printer (" 
                   + rows.size() + " rows).";

        } catch (Exception e) {
            e.printStackTrace();
            return "ERROR: " + e.getMessage();
        }
    }

    /**
     * Render a single label using Java2D graphics
     */
    private static void renderLabel(Graphics2D g, Map<String, String> label, 
                                     double x, double y, double w, double h) {
        String code = label.get("code") != null ? label.get("code") : "";
        String name = label.get("name") != null ? label.get("name") : "";
        String mrp = label.get("mrp") != null ? label.get("mrp") : "0";
        String barcode = label.get("barcode") != null ? label.get("barcode") : code;
        String rateStr = "Rate : " + formatMrp(mrp);

        // Horizontal padding inside each label (left & right gap from label edge)
        double hPad = 8;        // ~2.8mm each side — gap between labels
        double effectiveW = w - 2 * hPad;   // usable width for text/barcode

        // Center content within label (using full label width for center point)
        double cx = x + w / 2.0;  // Center X of label
        
        double padding = 1;     // Top padding in points
        double currentY = y + padding;

        // Font setup (sizes in points)
        Font fontCodeBold = new Font("Arial", Font.BOLD, 7);
        Font fontName = new Font("Arial", Font.BOLD, 6);
        Font fontRate = new Font("Arial", Font.BOLD, 8);

        g.setColor(Color.BLACK);

        // 1) Product Code - bold, centered
        g.setFont(fontCodeBold);
        FontMetrics fm = g.getFontMetrics();
        String codeTrunc = truncate(code, 20);
        int codeW = fm.stringWidth(codeTrunc);
        currentY += fm.getAscent();
        g.drawString(codeTrunc, (float)(cx - codeW / 2.0), (float)currentY);
        currentY += fm.getDescent() + 0.5;

        // 2) Product Name - centered
        g.setFont(fontName);
        fm = g.getFontMetrics();
        String nameTrunc = truncate(name, 20);
        int nameW = fm.stringWidth(nameTrunc);
        currentY += fm.getAscent();
        g.drawString(nameTrunc, (float)(cx - nameW / 2.0), (float)currentY);
        currentY += fm.getDescent() + 1;

        // 3) Barcode - rendered using ZXing, centered
        try {
            int barcodeW = (int)(effectiveW); // full effective width (respects hPad)
            int barcodeH = (int)(h * 0.30); // 30% of label height
            if (barcodeH < 8) barcodeH = 8;

            Code128Writer writer = new Code128Writer();
            BitMatrix matrix = writer.encode(barcode, BarcodeFormat.CODE_128, barcodeW, barcodeH);

            // Draw barcode centered
            int barcodeX = (int)(cx - barcodeW / 2.0);
            for (int bx = 0; bx < matrix.getWidth(); bx++) {
                for (int by = 0; by < matrix.getHeight(); by++) {
                    if (matrix.get(bx, by)) {
                        g.fillRect(barcodeX + bx, (int)currentY + by, 1, 1);
                    }
                }
            }
            currentY += barcodeH + 2;
        } catch (Exception e) {
            // Fallback: just print barcode text
            g.setFont(fontName);
            fm = g.getFontMetrics();
            int fbW = fm.stringWidth(barcode);
            currentY += 8;
            g.drawString(barcode, (float)(cx - fbW / 2.0), (float)currentY);
            currentY += 8;
        }

        // 4) Rate - bold, centered
        g.setFont(fontRate);
        fm = g.getFontMetrics();
        int rateW = fm.stringWidth(rateStr);
        currentY += fm.getAscent();
        g.drawString(rateStr, (float)(cx - rateW / 2.0), (float)currentY);
    }

    /**
     * Format MRP value
     */
    private static String formatMrp(String mrp) {
        try {
            double val = Double.parseDouble(mrp);
            return String.format("%.2f", val);
        } catch (Exception e) {
            return mrp;
        }
    }

    /**
     * Truncate text to max length
     */
    private static String truncate(String text, int maxLen) {
        if (text == null) return "";
        return text.length() > maxLen ? text.substring(0, maxLen - 2) + ".." : text;
    }

    /**
     * Get configured barcode printer from database
     */
    private static String getConfiguredBarcodePrinter() {
        Connection con = null;
        PreparedStatement ps = null;
        ResultSet rs = null;
        
        try {
            con = util.DBConnectionManager.getConnectionFromPool();
            ps = con.prepareStatement("SELECT barcode_printer FROM company_details LIMIT 1");
            rs = ps.executeQuery();
            
            if (rs.next()) {
                String printer = rs.getString("barcode_printer");
                if (printer != null && !printer.trim().isEmpty()) {
                    System.out.println("Configured barcode printer from database: " + printer);
                    return printer.trim();
                }
            }
            System.out.println("No barcode printer configured in database, using auto-detection");
            return null;
        } catch (Exception e) {
            System.err.println("Error reading barcode printer config: " + e.getMessage());
            e.printStackTrace();
            return null;
        } finally {
            if (rs != null) try { rs.close(); } catch (Exception e) { }
            if (ps != null) try { ps.close(); } catch (Exception e) { }
            if (con != null) try { con.close(); } catch (Exception e) { }
        }
    }

    /**
     * Find label/barcode printer or fall back to default
     * @param configuredPrinter Optional configured printer name from database
     * @param flavor Optional DocFlavor to filter printers that support it (null for no filter)
     */
    private static PrintService findPrintService(String configuredPrinter, DocFlavor flavor) {
        PrintService[] services;
        if (flavor != null) {
            services = PrintServiceLookup.lookupPrintServices(flavor, null);
        } else {
            services = PrintServiceLookup.lookupPrintServices(null, null);
        }

        // First, try exact match with configured printer name
        if (configuredPrinter != null && !configuredPrinter.isEmpty()) {
            for (PrintService service : services) {
                if (service.getName().equalsIgnoreCase(configuredPrinter)) {
                    System.out.println("Found exact match for configured printer: " + service.getName());
                    return service;
                }
            }
            System.out.println("Configured printer '" + configuredPrinter + "' not found, trying auto-detection...");
        }

        // Fall back to keyword detection
        for (PrintService service : services) {
            String name = service.getName().toLowerCase();
            if (name.contains("label") || name.contains("barcode") ||
                name.contains("xprinter") || name.contains("gprinter") ||
                name.contains("tsc") || name.contains("godex") || 
                name.contains("zebra") || name.contains("dymo") ||
                name.contains("snbc") || name.contains("tvse") ||
                name.contains("lp 46") || name.contains("lp46")) {
                System.out.println("Found label printer via keyword: " + service.getName());
                return service;
            }
        }

        PrintService defaultService = PrintServiceLookup.lookupDefaultPrintService();
        System.out.println("Using default printer: " + (defaultService != null ? defaultService.getName() : "None"));
        return defaultService;
    }

}
