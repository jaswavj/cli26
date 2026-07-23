# Consumables Entry Feature

## Overview
Track damaged and internally-used products (office use, samples, testing, etc.) with detailed categorization and reporting.

## Features Added

### 1. Entry Options
- **Damage**: Track broken, expired, damaged in transit, or quality issue items
- **Internal Use**: Track office use, samples/demos, staff use, testing

### 2. Reason Categories
When selecting Damage or Internal Use, you can choose from predefined categories:
- Broken
- Expired
- Damaged in Transit
- Quality Issue
- Office Use
- Sample/Demo
- Staff Use
- Testing
- Other

### 3. Stock Impact
- Automatically reduces stock from inventory
- Validates against current stock (cannot remove more than available)
- Records full audit trail in prod_lifecycle table

### 4. Reporting
- Filter by stock type (Add, Remove, Damage, Internal Use)
- Filter by product and date range
- Color-coded badges:
  - Green: Stock Added
  - Red: Stock Removed
  - Orange: Damage
  - Blue: Internal Use

## How to Use

### Recording a Consumable Entry

1. Navigate to: **Product → Master → Stock**
2. Search for the product
3. Select the type:
   - "Damage" for damaged/expired items
   - "Internal Use" for items used internally
4. Choose a reason category from the dropdown
5. Enter quantity (validated against current stock)
6. Provide detailed notes in the text area
7. Click "Update"

### Viewing Reports

1. Navigate to: **Reports → Stock Adjustment Report**
2. Select date range
3. (Optional) Filter by product
4. (Optional) Filter by stock type (Damage, Internal Use, etc.)
5. Click "Generate Report"
6. Export to Excel or print as needed

## Database Structure

### Tables Used

#### prod_stock_adjustment
Stores all stock adjustment entries including damage and internal use.

| Field | Type | Description |
|-------|------|-------------|
| id | INT | Auto-increment primary key |
| product_id | INT | Reference to prod_product |
| batch_id | INT | Reference to prod_batch |
| stockType | INT | 1=Add, 2=Remove, 3=Damage, 4=Internal Use |
| stock | INT | Quantity adjusted |
| date | DATE | Entry date |
| time | TIME | Entry time |
| notes | TEXT | Reason with category prefix |
| uid | INT | User who made the entry |

#### prod_lifecycle
Complete history of all stock movements.

| Field | Description |
|-------|-------------|
| stockAdjType | 3=Damage, 4=Internal Use |
| stock_out | Quantity removed |
| notes | Full reason text |

#### prod_batch
Current stock quantities (automatically updated).

## File Changes

### Frontend (JSP)
- `product/master/stock/stock1.jsp` - Entry form with new options and category dropdown
- `product/master/stock/stock2.jsp` - Save logic for new stock types
- `reports/stockAdj/page.jsp` - Filter form with stock type selector
- `reports/stockAdj/page0.jsp` - Report display with color-coded badges

### Backend (Java)
- `WEB-INF/classes/product/productBean.java`:
  - `removeStockForDamage()` - Handles damage entries (stockType=3)
  - `removeStockForInternalUse()` - Handles internal use entries (stockType=4)
  - `getStockAdjReport()` - Updated to filter by stock type

### Database
- `database/consumables_entry_setup.sql` - Optional schema changes and verification queries

## Examples

### Example 1: Recording Damaged Items
1. Search for "Soap Bar Premium"
2. Select Type: "Damage"
3. Category: "Broken"
4. Quantity: 5
5. Reason: "Damaged during shelf restocking"
6. Result: Stock reduced by 5, entry logged as "Damage - [Broken] Damaged during shelf restocking"

### Example 2: Recording Internal Use
1. Search for "Cleaning Spray"
2. Select Type: "Internal Use"
3. Category: "Office Use"
4. Quantity: 2
5. Reason: "For office cleaning supplies"
6. Result: Stock reduced by 2, entry logged as "Internal Use - [Office Use] For office cleaning supplies"

### Example 3: Viewing Damage Report
1. Go to Reports → Stock Adjustment Report
2. Set date range: Last 30 days
3. Stock Type: "Damage"
4. View all damage entries with quantities and reasons
5. Export to Excel for analysis

## Benefits

1. **Inventory Accuracy**: Track all stock reductions, not just sales
2. **Loss Prevention**: Identify patterns in damaged items
3. **Cost Analysis**: Calculate cost of damaged/consumed items
4. **Audit Trail**: Complete history of who recorded what and when
5. **Compliance**: Document internal use for tax/accounting purposes

## Technical Notes

- Stock validation prevents over-removal
- All operations use database transactions (rollback on error)
- Category prefix stored in notes field: "[Category] reason text"
- Backward compatible: existing reports work without changes
- Color scheme matches application theme

## Future Enhancements (Optional)

1. Add cost calculation for damaged/consumed items
2. Create dedicated consumables report with charts
3. Add approval workflow for high-value consumables
4. Integrate with accounting system
5. Add batch-specific tracking for expiry management

## Support

For questions or issues, contact the development team or refer to the main application documentation.
