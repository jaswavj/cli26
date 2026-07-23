-- =====================================================
-- Consumables Entry Feature - Database Setup Script
-- =====================================================
-- Purpose: Enable tracking of damaged and internally-used products
-- Date: January 21, 2026
-- 
-- This script is OPTIONAL and only needed if you want to add
-- a separate reason_category column to store categorized reasons.
-- 
-- The feature works WITHOUT this column by storing the category
-- in the existing 'notes' field with a prefix like "[Broken] reason text"
-- =====================================================

-- Option 1: Add reason_category column (OPTIONAL)
-- Uncomment the following line if you want a dedicated column for categories:
-- ALTER TABLE `prod_stock_adjustment` 
--     ADD COLUMN `reason_category` VARCHAR(50) NULL DEFAULT NULL 
--     COMMENT 'Category: Broken, Expired, Office Use, Sample/Demo, etc.' 
--     AFTER `notes`;

-- =====================================================
-- NOTES:
-- =====================================================
-- 1. The prod_stock_adjustment table already supports stockType values:
--    - 1 = Stock Add
--    - 2 = Stock Remove
--    - 3 = Damage (NEW)
--    - 4 = Internal Use (NEW)
--
-- 2. The 'notes' field stores the full reason including category prefix
--    Example: "Damage - [Broken] Item dropped during handling"
--             "Internal Use - [Office Use] For office kitchen"
--
-- 3. The prod_lifecycle table also stores these entries with matching
--    stockAdjType values (3 for Damage, 4 for Internal Use)
--
-- 4. Stock is automatically reduced from prod_batch table
--
-- =====================================================
-- VERIFICATION QUERIES:
-- =====================================================

-- View all damage entries
SELECT 
    p.name AS product_name,
    psa.stock AS quantity,
    psa.notes,
    psa.date,
    u.user_name
FROM prod_stock_adjustment psa
JOIN prod_product p ON psa.product_id = p.id
JOIN users u ON psa.uid = u.id
WHERE psa.stockType = 3
ORDER BY psa.date DESC;

-- View all internal use entries
SELECT 
    p.name AS product_name,
    psa.stock AS quantity,
    psa.notes,
    psa.date,
    u.user_name
FROM prod_stock_adjustment psa
JOIN prod_product p ON psa.product_id = p.id
JOIN users u ON psa.uid = u.id
WHERE psa.stockType = 4
ORDER BY psa.date DESC;

-- Summary of consumables by type
SELECT 
    CASE psa.stockType
        WHEN 3 THEN 'Damage'
        WHEN 4 THEN 'Internal Use'
    END AS type,
    COUNT(*) AS total_entries,
    SUM(psa.stock) AS total_quantity
FROM prod_stock_adjustment psa
WHERE psa.stockType IN (3, 4)
GROUP BY psa.stockType;
