<%@ page language="java" contentType="text/html; charset=UTF-8"%>
<%@ page import="java.util.Vector"%>
<jsp:useBean id="userBean" class="user.userBean" scope="page"/>
<%
// Fetch company details
Vector companyDetails = userBean.getCompanyDetails();
String companyName = "";
String companyAddress = "";
String companyGSTIN = "";

if (companyDetails != null && companyDetails.size() >= 4) {
    companyName = companyDetails.get(1) != null ? companyDetails.get(1).toString() : "";
    companyAddress = companyDetails.get(2) != null ? companyDetails.get(2).toString() : "";
    companyGSTIN = companyDetails.get(3) != null ? companyDetails.get(3).toString() : "";
}
%>
<html>
<head>
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
    </style>
</head>
<body>
    <div class="header-box">
    <% if (!companyName.isEmpty()) { %>
        <h1 class="company-name"><%= companyName %></h1>
    <% } %>
    <% if (!companyAddress.isEmpty()) { %>
        <% 
        // Split address by newlines and display each line
        String[] addressLines = companyAddress.split("\\r?\\n");
        for (String line : addressLines) {
            if (line != null && !line.trim().isEmpty()) {
        %>
            <p><%= line.trim() %></p>
        <% 
            }
        } 
        %>
    <% } %>
    <% if (!companyGSTIN.isEmpty()) { %>
        <p>GSTIN: <%= companyGSTIN %></p>
    <% } %>
  </div>
</body>
</html> 