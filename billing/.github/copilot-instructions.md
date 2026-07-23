# Copilot Instructions for Billing Application

## Overview
This is a JSP-based billing and reporting system with a modular directory structure. The application is organized by feature (billing, product, reports, admin) and uses server-side Java (JSP, servlets) with static assets (JS, CSS) and Java libraries in `WEB-INF/lib`.

## Architecture & Major Components
- **JSP Pages**: UI and business logic are tightly coupled in JSP files, grouped by feature (e.g., `billing/`, `product/`, `reports/`, `admin/`).
- **Java Classes**: Backend logic resides in `WEB-INF/classes/`, organized by domain (billing, product, user, util, etc.).
- **Assets**: Shared JS/CSS in `assets/common/` and `assets/css/`.
- **Reports**: Specialized reporting modules under `reports/` (e.g., GST, sales, stock).
- **Admin**: User and permission management in `admin/`.

## Developer Workflows
- **Build/Deploy**: No build scripts found; typically, update JSPs and Java classes, then redeploy the WAR or update exploded files in the servlet container.
- **Debugging**: Debug by editing JSPs and Java classes, then reload in browser. Use logs or temporary output in JSPs for diagnostics.
- **Testing**: No automated tests detected. Manual testing via browser is standard.

## Project-Specific Conventions
- **Feature Folders**: Each major feature has its own folder with related JSPs and backend classes.
- **JSP Naming**: Pages often use `page.jsp`, `details.jsp`, `edit.jsp`, etc. for CRUD and reporting views.
- **Action Pages**: Actions (e.g., `saveBill.jsp`, `cancelAction.jsp`) are separated from UI pages.
- **Assets**: Use shared JS/CSS from `assets/common/` for UI consistency.
- **Java Libraries**: External dependencies are managed via JARs in `WEB-INF/lib/`.

## Integration Points
- **Database**: Likely accessed via backend Java classes (see `WEB-INF/classes/billing/`, `product/`, etc.).
- **External Libraries**: Common Java libraries (Apache Commons, BoneCP, etc.) in `WEB-INF/lib/`.
- **Cross-Component Communication**: JSPs call backend Java classes for data and actions; assets are included via `<script>`/`<link>` tags.

## Examples
- To add a new report, create a folder in `reports/`, add JSPs for UI, and backend classes in `WEB-INF/classes/reports/`.
- To update billing logic, edit JSPs in `billing/` and corresponding Java classes in `WEB-INF/classes/billing/`.
- For UI changes, update shared assets in `assets/common/` or `assets/css/`.

## Key Files & Directories
- `billing/`, `product/`, `reports/`, `admin/`: Feature modules
- `WEB-INF/classes/`: Backend Java code
- `WEB-INF/lib/`: Java dependencies
- `assets/common/`, `assets/css/`: Shared assets

---
For questions or missing conventions, ask the user for clarification or examples from their workflow.