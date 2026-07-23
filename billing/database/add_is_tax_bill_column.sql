-- Add is_tax_bill column to prod_bill table
-- is_tax_bill: 1 = Tax Bill (default), 0 = Non-Tax Bill
-- This allows separate bill numbering for tax and non-tax bills

ALTER TABLE `prod_bill` ADD COLUMN `is_tax_bill` TINYINT(1) DEFAULT 1 AFTER `attender_id`;
ALTER TABLE `prod_bill` ADD INDEX `idx_is_tax_bill` (`is_tax_bill`);

-- Update existing bills to be tax bills by default
UPDATE `prod_bill` SET `is_tax_bill` = 1 WHERE `is_tax_bill` IS NULL;
