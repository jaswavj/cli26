<%@ page language="java" import="java.io.*" %><%
// Serve PDF file from project bills folder
String fileName = request.getParameter("file");
if (fileName == null || fileName.trim().isEmpty()) {
    response.setStatus(400);
    out.print("Missing file parameter");
    return;
}

// Security: prevent directory traversal
fileName = new File(fileName).getName();

// Get bills folder path (relative to application)
String billsDir = application.getRealPath("/bills");
File pdfFile = new File(billsDir + File.separator + fileName);

if (!pdfFile.exists() || !pdfFile.isFile()) {
    response.setStatus(404);
    out.print("PDF file not found");
    return;
}

// Serve the PDF
response.setContentType("application/pdf");
response.setHeader("Content-Disposition", "inline; filename=\"" + fileName + "\"");
response.setContentLength((int) pdfFile.length());

FileInputStream fis = new FileInputStream(pdfFile);
OutputStream os = response.getOutputStream();
byte[] buffer = new byte[4096];
int bytesRead;
while ((bytesRead = fis.read(buffer)) != -1) {
    os.write(buffer, 0, bytesRead);
}
fis.close();
os.flush();
%>