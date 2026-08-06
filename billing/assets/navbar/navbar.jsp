<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@page language="java" import="java.util.*" %>
<jsp:useBean id="user" class="user.userBean" />
<%
Integer uids = (Integer) session.getAttribute("userId");
 
// Check if session is null or expired
if (uids == null) {
    response.setContentType("text/html");
    out.println("<script type='text/javascript'>");
    out.println("Swal.fire({");
    out.println("  icon: 'warning',");
    out.println("  title: 'Session Expired',");
    out.println("  text: 'Your session has expired. Please login again.',");
    out.println("  confirmButtonText: 'OK',");
    out.println("  allowOutsideClick: false");
    out.println("}).then(function() {");
    out.println("  window.location.href = '" + request.getContextPath() + "/index.jsp';");
    out.println("});");
    out.println("</script>");
    return;
}

String userNameUni = user.getUserName(uids);

Vector vecPer = user.getUserPermission(uids);
Set<Integer> permissions = new HashSet<Integer>();

for (int i = 0; i < vecPer.size(); i++) {
    Vector cat = (Vector) vecPer.get(i);
    int modId = Integer.parseInt(cat.elementAt(0).toString()); 
    permissions.add(modId);
}
%> 

<!-- Mobile Top Navbar (visible only on mobile) -->
<div class="mobile-top-navbar">
  <div class="mobile-nav-logo">
    <div class="logo-icon">
      <i class="fas fa-cash-register"></i>
    </div>
    <div class="mobile-nav-title">
      <div class="title">JASXBILL</div>
      <div class="subtitle">POS System</div>
    </div>
  </div>
  <div class="mobile-nav-user">
    <a href="<%=request.getContextPath()%>/admin/changePassword/changePassword.jsp" class="mobile-nav-user-link" title="Change Password">
      <i class="fa-solid fa-user"></i>
      <span><%=userNameUni%></span>
    </a>
  </div>
  <button class="mobile-nav-logout" onclick="handleLogout(); return false;" title="Logout">
    <i class="fa-solid fa-arrow-right-from-bracket"></i>
  </button>
  <button class="mobile-nav-toggle" id="mobileNavToggle" title="Menu">
    <i class="fas fa-bars"></i>
  </button>
</div>

<!-- Sidebar -->
<div class="sidebar" id="sidebar">
  <!-- Logo Section -->
  <div class="sidebar-header">
    <div class="sidebar-logo">
      
      <div class="logo-text">
        <div class="logo-title">JASXBILL</div>
        <div class="logo-subtitle">POS System</div>
      </div>
      <button class="sidebar-toggle-btn" id="sidebarToggle" title="Toggle Sidebar">
        <i class="fas fa-bars"></i>
      </button>
    </div>
  </div>
  
  <!-- User Section -->
  <div class="sidebar-user-section">
    <a href="<%=request.getContextPath()%>/admin/changePassword/changePassword.jsp" class="user-info" title="Change Password">
      <i class="fa-solid fa-user"></i>
      <span class="user-name"><%=userNameUni%></span>
    </a>
    <a href="#" onclick="handleLogout(); return false;" class="sidebar-logout-btn" title="Logout">
      <i class="fa-solid fa-arrow-right-from-bracket"></i>
      <span class="logout-text">Logout</span>
    </a>
  </div>
  <div class="sidebar-menu">

    <% if (permissions.contains(1)) { %>
    <div class="sidebar-dropdown">
      <a href="#" class="sidebar-item" data-bs-toggle="collapse" data-bs-target="#exchangeMenu">
        <i class="fa-solid fa-right-left"></i>
        <span>Currency Exchange</span>
        <i class="fas fa-chevron-down ms-auto"></i>
      </a>
      <div class="collapse sidebar-submenu" id="exchangeMenu">
        <a href="<%=request.getContextPath()%>/exchange/page.jsp" class="sidebar-subitem">New Exchange</a>
        <a href="<%=request.getContextPath()%>/transfer/page.jsp" class="sidebar-subitem">Currency Transfer</a>
        <a href="<%=request.getContextPath()%>/master/exchange/page.jsp" class="sidebar-subitem">Currency Master</a>
      </div>
    </div>
    <% } %>
    <% if (permissions.contains(2)) { %>
    <div class="sidebar-dropdown">
      <a href="#" class="sidebar-item" data-bs-toggle="collapse" data-bs-target="#exchangeReportMenu">
        <i class="fa-solid fa-chart-line"></i>
        <span> Reports</span>
        <i class="fas fa-chevron-down ms-auto"></i>
      </a>
      <div class="collapse sidebar-submenu" id="exchangeReportMenu">
        <a href="<%=request.getContextPath()%>/exchange/report/exchangeReport.jsp" class="sidebar-subitem">Exchange Report</a>
        <a href="<%=request.getContextPath()%>/transfer/report/transferReport.jsp" class="sidebar-subitem">Transfer Report</a>
        <a href="<%=request.getContextPath()%>/exchange/report/stockReport.jsp" class="sidebar-subitem">Current Stock Report</a>
        <a href="<%=request.getContextPath()%>/exchange/report/stockTransactionReport.jsp" class="sidebar-subitem">Stock Trans Report</a>
        <a href="<%=request.getContextPath()%>/exchange/report/ledgerReport.jsp" class="sidebar-subitem">Ledger Report</a>
      </div>
    </div>
    <% } %>

    <% if (permissions.contains(3)) { %>
    <div class="sidebar-dropdown">
      <a href="#" class="sidebar-item" data-bs-toggle="collapse" data-bs-target="#customerMenu">
        <i class="fas fa-users"></i>
        <span>Customer</span>
        <i class="fas fa-chevron-down ms-auto"></i>
      </a>
      <div class="collapse sidebar-submenu" id="customerMenu">
        <a href="<%=request.getContextPath()%>/customer/master/page.jsp" class="sidebar-subitem">Customer Master</a>
        <a href="<%=request.getContextPath()%>/customer/enquiry/page.jsp" class="sidebar-subitem">Customer Enquiry</a>
      </div>
    </div>
    <% } %>
    <% if (permissions.contains(4)) { %>
    <div class="sidebar-dropdown">
      <a href="#" class="sidebar-item" data-bs-toggle="collapse" data-bs-target="#expenseMenu">
        <i class="fas fa-money-bill-wave"></i>
        <span>Expense</span>
        <i class="fas fa-chevron-down ms-auto"></i>
      </a>
      <div class="collapse sidebar-submenu" id="expenseMenu">
        <a href="<%=request.getContextPath()%>/expense/expenseType/expenseType.jsp" class="sidebar-subitem"><i class="fas fa-tags me-2"></i>Expense Type</a>
        <a href="<%=request.getContextPath()%>/expense/expenseEntry/page.jsp" class="sidebar-subitem"><i class="fas fa-receipt me-2"></i>Expense Entry</a>
        <a href="<%=request.getContextPath()%>/expense/expenseReport/page.jsp" class="sidebar-subitem"><i class="fas fa-chart-line me-2"></i>Expense Report</a>
      </div>
    </div>
    <% } %>

    <% if (permissions.contains(6)) { %>
    <div class="sidebar-dropdown">
      <a href="#" class="sidebar-item" data-bs-toggle="collapse" data-bs-target="#additionalIncomeMenu">
        <i class="fa-solid fa-coins"></i>
        <span>Additional Income</span>
        <i class="fas fa-chevron-down ms-auto"></i>
      </a>
      <div class="collapse sidebar-submenu" id="additionalIncomeMenu">
        <a href="<%=request.getContextPath()%>/income/additionalIncome/page.jsp" class="sidebar-subitem"><i class="fa-solid fa-receipt me-2"></i>Income Entry</a>
        <a href="<%=request.getContextPath()%>/income/additionalIncome/report.jsp" class="sidebar-subitem"><i class="fa-solid fa-chart-line me-2"></i>Income Report</a>
      </div>
    </div>
    <% } %>

    <% if (permissions.contains(5)) { %>
    <div class="sidebar-dropdown">
      <a href="#" class="sidebar-item" data-bs-toggle="collapse" data-bs-target="#adminReportMenu">
        <i class="fas fa-chart-pie"></i>
        <span>Admin</span>
        <i class="fas fa-chevron-down ms-auto"></i>
      </a>
      <div class="collapse sidebar-submenu" id="adminReportMenu">
        <a href="<%=request.getContextPath()%>/admin/companyDetails/page.jsp" class="sidebar-subitem">Company Details</a>
        <a href="<%=request.getContextPath()%>/admin/userCreate/page.jsp" class="sidebar-subitem">Create User</a>
        <a href="<%=request.getContextPath()%>/admin/permission/page.jsp" class="sidebar-subitem">Module Permission</a>

      </div>
        </div>
    <% } %>



    

  </div>
</div>

<!-- Sidebar Overlay for Mobile -->
<div class="sidebar-overlay" id="sidebarOverlay"></div>

<script>
document.addEventListener('DOMContentLoaded', function() {
    const sidebar = document.getElementById('sidebar');
    const sidebarToggle = document.getElementById('sidebarToggle');
    const mobileNavToggle = document.getElementById('mobileNavToggle');
    const sidebarOverlay = document.getElementById('sidebarOverlay');
    const body = document.body;
    
    // Check if we're on mobile
    function isMobile() {
        return window.innerWidth <= 768;
    }
    
    // Toggle sidebar (desktop toggle button)
    if (sidebarToggle) {
        sidebarToggle.addEventListener('click', function() {
            if (isMobile()) {
                sidebar.classList.toggle('show');
                sidebarOverlay.classList.toggle('show');
                body.classList.toggle('sidebar-open');
            } else {
                sidebar.classList.toggle('hidden');
                body.classList.toggle('sidebar-hidden');
            }
        });
    }
    
    // Mobile nav toggle button
    if (mobileNavToggle) {
        mobileNavToggle.addEventListener('click', function() {
            sidebar.classList.toggle('show');
            sidebarOverlay.classList.toggle('show');
            body.classList.toggle('sidebar-open');
        });
    }
    
    // Close sidebar when clicking overlay (mobile)
    sidebarOverlay.addEventListener('click', function() {
        sidebar.classList.remove('show');
        sidebarOverlay.classList.remove('show');
        body.classList.remove('sidebar-open');
    });
    
    // Auto-close other menus when opening a new main menu
    const mainMenuToggles = document.querySelectorAll('.sidebar-item[data-bs-toggle="collapse"]');
    mainMenuToggles.forEach(toggle => {
        toggle.addEventListener('click', function(e) {
            const targetId = this.getAttribute('data-bs-target');
            
            // Close all other main menus (not submenus)
            mainMenuToggles.forEach(otherToggle => {
                const otherTargetId = otherToggle.getAttribute('data-bs-target');
                
                // Only close if it's a different main menu (not nested submenu)
                if (otherTargetId !== targetId && !otherToggle.closest('.sidebar-submenu')) {
                    const otherTarget = document.querySelector(otherTargetId);
                    if (otherTarget && otherTarget.classList.contains('show')) {
                        // Use Bootstrap's collapse hide method
                        const bsCollapse = bootstrap.Collapse.getInstance(otherTarget);
                        if (bsCollapse) {
                            bsCollapse.hide();
                        } else {
                            otherTarget.classList.remove('show');
                        }
                        otherToggle.setAttribute('aria-expanded', 'false');
                    }
                }
            });
        });
    });
    
    // Auto-close sibling submenus within the same parent menu
    const subMenuToggles = document.querySelectorAll('.sidebar-submenu-item > .sidebar-subitem[data-bs-toggle="collapse"]');
    subMenuToggles.forEach(toggle => {
        toggle.addEventListener('click', function(e) {
            const targetId = this.getAttribute('data-bs-target');
            const parentMenu = this.closest('.sidebar-submenu');
            
            if (parentMenu) {
                // Find all sibling submenu toggles within the same parent
                const siblingToggles = parentMenu.querySelectorAll('.sidebar-submenu-item > .sidebar-subitem[data-bs-toggle="collapse"]');
                
                siblingToggles.forEach(siblingToggle => {
                    const siblingTargetId = siblingToggle.getAttribute('data-bs-target');
                    
                    // Only close if it's a different submenu
                    if (siblingTargetId !== targetId) {
                        const siblingTarget = document.querySelector(siblingTargetId);
                        if (siblingTarget && siblingTarget.classList.contains('show')) {
                            const bsCollapse = bootstrap.Collapse.getInstance(siblingTarget);
                            if (bsCollapse) {
                                bsCollapse.hide();
                            } else {
                                siblingTarget.classList.remove('show');
                            }
                            siblingToggle.setAttribute('aria-expanded', 'false');
                        }
                    }
                });
            }
        });
    });
    
    // Highlight active menu based on current URL
    const currentPath = window.location.pathname;
    const allSubitems = sidebar.querySelectorAll('.sidebar-subitem');
    const allMainItems = sidebar.querySelectorAll('.sidebar-item');
    
    // Check subitems first
    allSubitems.forEach(subitem => {
        const href = subitem.getAttribute('href');
        if (href && href !== '#' && currentPath.includes(href)) {
            subitem.classList.add('active');
            let parentCollapse = subitem.closest('.sidebar-submenu');
            while (parentCollapse) {
                parentCollapse.classList.add('show');
                const parentToggle = parentCollapse.previousElementSibling;
                if (parentToggle) {
                    parentToggle.classList.add('active');
                    parentToggle.setAttribute('aria-expanded', 'true');
                }
                parentCollapse = parentCollapse.parentElement
                    ? parentCollapse.parentElement.closest('.sidebar-submenu')
                    : null;
            }
        }
    });
    
    // Check main items if no submenu is active
    allMainItems.forEach(item => {
        const href = item.getAttribute('href');
        if (href && href !== '#' && currentPath.includes(href)) {
            item.classList.add('active');
        }
    });
    
    // Close sidebar when clicking any link (mobile)
    // Use event delegation to handle dynamic changes and ensure navigation works
    sidebar.addEventListener('click', function(e) {
        // Find the closest anchor tag
        const link = e.target.closest('a');
        if (!link) return;
        
        // Check if it's a valid link for navigation
        const href = link.getAttribute('href');
        // Check if it's a toggle or a placeholder link
        const isToggle = link.hasAttribute('data-bs-toggle') || href === '#';
        
        if (href && !isToggle) {
            // If on mobile, close sidebar and navigate manually
            if (isMobile()) {
                e.preventDefault(); // Prevent default to avoid race conditions
                
                // Close sidebar
                sidebar.classList.remove('show');
                sidebarOverlay.classList.remove('show');
                body.classList.remove('sidebar-open');
                
                // Navigate manually
                window.location.href = href;
            }
        }
    });
    
    // Handle window resize
    let resizeTimer;
    window.addEventListener('resize', function() {
        clearTimeout(resizeTimer);
        resizeTimer = setTimeout(function() {
            if (!isMobile()) {
                sidebar.classList.remove('show');
                sidebarOverlay.classList.remove('show');
                body.classList.remove('sidebar-open');
            }
        }, 250);
    });
});

// Logout function - works inside iframe
function handleLogout() {
    var contextPath = '<%=request.getContextPath()%>';
    // If inside iframe, redirect the top window
    if (window.top !== window.self) {
        window.top.location.href = contextPath + '/logout.jsp';
    } else {
        // If not in iframe, redirect normally
        window.location.href = contextPath + '/logout.jsp';
    }
}
</script>










