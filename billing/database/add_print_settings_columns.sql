-- Add print settings columns to company_details table
-- Run this SQL script to add print_type and printer_name fields

ALTER TABLE company_details 
ADD COLUMN print_type INT DEFAULT 1 COMMENT 'Print format: 1=Thermal, 2=A4',
ADD COLUMN printer_name VARCHAR(255) DEFAULT '' COMMENT 'Printer sharing name for thermal printing';

-- Update existing records to have default values
UPDATE company_details 
SET print_type = 1, printer_name = '' 
WHERE print_type IS NULL;

-- Verification query
SELECT id, shop_name, print_type, printer_name FROM company_details;
