package util;

import jakarta.servlet.*;
import jakarta.servlet.http.*;
import java.io.IOException;

/**
 * HttpsEnforcementFilter - Fixes Mixed Content errors when application is behind HTTPS reverse proxy
 * 
 * This filter detects when requests come through an HTTPS proxy (via standard headers)
 * and ensures that response.sendRedirect() generates HTTPS URLs instead of HTTP URLs.
 * 
 * This prevents "Mixed Content" browser errors where HTTPS pages try to redirect to HTTP URLs.
 */
public class HttpsEnforcementFilter implements Filter {
    
    public void init(FilterConfig config) throws ServletException {
        // No initialization needed
    }
    
    public void doFilter(ServletRequest req, ServletResponse res, FilterChain chain) 
            throws IOException, ServletException {
        
        HttpServletRequest request = (HttpServletRequest) req;
        HttpServletResponse response = (HttpServletResponse) res;
        
        // Check if request came through HTTPS proxy by examining common proxy headers
        String proto = request.getHeader("X-Forwarded-Proto");
        String forwardedSSL = request.getHeader("X-Forwarded-SSL");
        String cloudFrontProto = request.getHeader("CloudFront-Forwarded-Proto");
        
        // If any header indicates HTTPS, wrap the request to return HTTPS scheme
        if ("https".equalsIgnoreCase(proto) || 
            "on".equalsIgnoreCase(forwardedSSL) ||
            "https".equalsIgnoreCase(cloudFrontProto)) {
            
            // Wrap the request to override scheme-related methods
            request = new HttpServletRequestWrapper(request) {
                @Override
                public String getScheme() {
                    return "https";
                }
                
                @Override
                public int getServerPort() {
                    return 443;
                }
                
                @Override
                public boolean isSecure() {
                    return true;
                }
                
                @Override
                public StringBuffer getRequestURL() {
                    StringBuffer url = new StringBuffer();
                    url.append("https://");
                    url.append(getServerName());
                    
                    // Don't append port for standard HTTPS port
                    if (getServerPort() != 443) {
                        url.append(":");
                        url.append(getServerPort());
                    }
                    
                    url.append(getRequestURI());
                    return url;
                }
            };
        }
        
        // Continue the filter chain with the potentially wrapped request
        chain.doFilter(request, response);
    }
    
    public void destroy() {
        // No cleanup needed
    }
}
