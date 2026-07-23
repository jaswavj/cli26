-- Add attender_id column to prod_bill table
ALTER TABLE `prod_bill` ADD COLUMN `attender_id` INT DEFAULT NULL AFTER `price_category`;
ALTER TABLE `prod_bill` ADD INDEX `idx_attender_id` (`attender_id`);
