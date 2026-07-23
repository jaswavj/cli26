///////////////// MAIN CONTENT LOADING LOGIC /////////////////

document.addEventListener("DOMContentLoaded", function () {
    const contentDiv = document.getElementById("content");

    // Handle sidebar links with data-url (AJAX loading)
    document.querySelectorAll(".sidebar a[data-url]").forEach(link => {
        link.addEventListener("click", function (e) {
            e.preventDefault();
            
            const url = this.dataset.url;

            // Update active states
            updateActiveState(this);
            
            // Show loading
            contentDiv.innerHTML = `<div class="text-center p-3">Loading...</div>`;

            // Use the unified loadContent function
            window.loadContent(url, "Navigation", "");
        });
    });

    // Handle main menu clicks (collapse toggles)
    document.querySelectorAll(".sidebar .main-menu").forEach(menu => {
        menu.addEventListener("click", function (e) {
            // If it's a regular link, let it navigate normally
            if (this.getAttribute('href') && this.getAttribute('href') !== '#') {
                return;
            }
            
            // If it has data-url, we've already handled it above
            if (this.hasAttribute("data-url")) {
                return;
            }
            
            // Otherwise, it's a menu toggle without navigation
            e.preventDefault();
            
            // Update active state
            updateActiveState(this);
        });
    });

    // Load initial content if specified in URL
    const urlParams = new URLSearchParams(window.location.search);
    const initialPage = urlParams.get('page');
    if (initialPage) {
        const initialLink = document.querySelector(`.sidebar a[data-url="${initialPage}"]`);
        if (initialLink) {
            initialLink.click();
        }
    }
    
    // Initialize handlers for the initial page content
    attachDataUrlHandlers(document);
    attachAjaxForms(document);
});

/////////////////Load content dynamically into #content div for data-url attributes inside the content div
function attachDataUrlHandlers(scope) {
    scope.querySelectorAll("a[data-url]").forEach(link => {
        // Check if this link already has a handler
        if (link.hasAttribute('data-handler-attached')) return;
        link.setAttribute('data-handler-attached', 'true');
        
        link.addEventListener("click", function (e) {
            e.preventDefault();
            const url = this.dataset.url;
            
            // Use the unified loadContent function instead of direct fetch
            window.loadContent(url, "Navigation", "");
        });
    });
}

///////////////////// for forms with class ajax-form inside the content div
function attachAjaxForms(scope) {
    scope.querySelectorAll("form.ajax-form").forEach(form => {
        // Check if this form already has a handler
        if (form.hasAttribute('data-handler-attached')) return;
        form.setAttribute('data-handler-attached', 'true');

        form.addEventListener("submit", function (e) {
            e.preventDefault();
            const url = form.getAttribute("action");
            const contentDiv = document.getElementById("content");

            contentDiv.innerHTML = `<div class="text-center p-3">Submitting...</div>`;

            // Use jQuery to serialize the form data for proper encoding
            const formData = $(form).serialize();
            
            // For debugging: log the form data
            console.log("Form data being sent:", formData);

            fetch(url, {
                method: form.method || "POST",
                headers: {
                    'Content-Type': 'application/x-www-form-urlencoded',
                },
                body: formData
            })
            .then(res => {
                // Check content type to determine if it's HTML or text
                const contentType = res.headers.get('content-type') || '';
                
                if (contentType.includes('text/html')) {
                    // It's HTML, return as text for further processing
                    return res.text().then(text => ({ type: 'html', content: text }));
                } else {
                    // It's text, return as text
                    return res.text().then(text => ({ type: 'text', content: text }));
                }
            })
            .then(result => {
                if (result.type === 'html') {
                    // It's HTML, load it using our unified function
                    window.loadContentHTML(result.content);
                } else {
                    // It's a text response (SUCCESS/ERROR)
                    handleTextResponse(result.content, form);
                }
            })
            .catch(err => {
                contentDiv.innerHTML = `<div class="alert alert-danger">Error: ${err.message}</div>`;
            });
        });
    });
}

////////////// UNIFIED CONTENT LOADING FUNCTIONS //////////////

// For loading content from URLs
window.loadContent = function(url, action, extra) {
    const contentDiv = document.getElementById("content");
    contentDiv.innerHTML = `<div class="text-center p-3">Loading...</div>`;

    fetch(url)
        .then(response => {
            if (!response.ok) throw new Error("Page not found");
            return response.text();
        })
        .then(html => {
            window.loadContentHTML(html);
            console.log(action + " Loaded: " + url);
        })
        .catch(err => {
            console.error("Error loading " + url + ": " + err.message);
            contentDiv.innerHTML = `<div class="alert alert-danger">
                Error loading page: ${err.message}
            </div>`;
        });
};

// For loading HTML content directly
window.loadContentHTML = function(html) {
    const contentDiv = document.getElementById("content");
    
    // Clean up any global variables that might cause conflicts
    cleanupPage();
    
    // Set the HTML content
    contentDiv.innerHTML = html;
    
    // Rebind handlers after new content load
    attachDataUrlHandlers(contentDiv);
    attachAjaxForms(contentDiv);
    
    // Execute scripts safely
    executeScripts(contentDiv);
};

////////////// HELPER FUNCTIONS //////////////

function updateActiveState(activeElement) {
    // Remove active class from all sidebar links
    document.querySelectorAll(".sidebar a").forEach(a => a.classList.remove("active"));
    
    // Add active to clicked element
    activeElement.classList.add("active");
    
    // Also highlight the parent main menu if this is a submenu item
    const parentCollapse = activeElement.closest(".collapse");
    if (parentCollapse) {
        const parentToggle = document.querySelector(`[data-bs-target="#${parentCollapse.id}"], [href="#${parentCollapse.id}"]`);
        if (parentToggle) {
            parentToggle.classList.add("active");
        }
    }
}

function executeScripts(container) {
    const scripts = container.querySelectorAll('script');
    scripts.forEach(oldScript => {
        const newScript = document.createElement('script');
        newScript.textContent = oldScript.textContent;
        
        // Copy attributes
        Array.from(oldScript.attributes).forEach(attr => {
            newScript.setAttribute(attr.name, attr.value);
        });
        
        oldScript.parentNode.replaceChild(newScript, oldScript);
    });
}

function cleanupPage() {
    // Clean up any global variables that might cause conflicts
    if (typeof curStock !== 'undefined') delete window.curStock;
    if (typeof discTypeEl !== 'undefined') delete window.discTypeEl;
    if (typeof discValueEl !== 'undefined') delete window.discValueEl;
}

function handleTextResponse(response, form) {
    const resp = response.trim();
    const contentDiv = document.getElementById("content");

    // For debugging
    console.log("Server response:", resp);
    console.log("Form attributes:", {
        redirect: form.getAttribute('data-redirect'),
        reload: form.getAttribute('data-reload'),
        jQueryRedirect: $(form).data('redirect'),
        jQueryReload: $(form).data('reload')
    });

    if (resp === "SUCCESS") {
        // Get data attributes - check both HTML attributes and jQuery data
        const redirectUrl = form.getAttribute('data-redirect') || $(form).data('redirect');
        const reloadUrl = form.getAttribute('data-reload') || $(form).data('reload');
        
        console.log("Redirect URL found:", redirectUrl);
        console.log("Reload URL found:", reloadUrl);
        
        if (redirectUrl) {
            // Redirect to a new page
            window.loadContent(redirectUrl, "Redirect", "");
        } else if (reloadUrl) {
            // Reload the specified page
            window.loadContent(reloadUrl, "Reload", "");
        } else {
            // Just show message
            showSuccessAlert("Operation completed successfully!");
            
            // If no redirect specified, try to reload the current page after a delay
            setTimeout(() => {
                window.loadContent(window.location.href, "Reload", "");
            }, 1500);
        }
    } else if (resp.startsWith("ERROR")) {
        // Show error in the form itself if possible
        const errorMatch = resp.match(/ERROR:(.*)/);
        const errorMessage = errorMatch ? errorMatch[1].trim() : "An error occurred";
        
        // Try to find error display elements in the form
        const errorDisplay = form.querySelector('.error-message, .alert-danger');
        if (errorDisplay) {
            errorDisplay.textContent = errorMessage;
            errorDisplay.style.display = 'block';
        } else {
            showErrorAlert(errorMessage);
        }
    } else {
        // If it's not SUCCESS or ERROR, it might be HTML content that wasn't detected properly
        console.warn("Unexpected response, treating as HTML:", resp.substring(0, 100) + "...");
        window.loadContentHTML(resp);
    }
}

function showErrorAlert(message) {
    const contentDiv = document.getElementById("content");
    // Remove old alerts
    contentDiv.querySelectorAll(".alert").forEach(alert => alert.remove());
    
    const alertHtml = `
        <div class="alert alert-danger alert-dismissible fade show mt-2" role="alert">
            ${message}
            <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Close"></button>
        </div>`;
    contentDiv.insertAdjacentHTML('afterbegin', alertHtml);
}

function showSuccessAlert(message) {
    const contentDiv = document.getElementById("content");
    // Remove old alerts
    contentDiv.querySelectorAll(".alert").forEach(alert => alert.remove());
    
    const alertHtml = `
        <div class="alert alert-success alert-dismissible fade show mt-2" role="alert">
            ${message}
            <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Close"></button>
        </div>`;
    contentDiv.insertAdjacentHTML('afterbegin', alertHtml);
}

////////////// JQUERY FORM HANDLER (DISABLED TO PREVENT DUPLICATES) //////////////
// This jQuery handler is causing duplicate requests, so we'll disable it
$(document).off("submit", ".ajax-form");