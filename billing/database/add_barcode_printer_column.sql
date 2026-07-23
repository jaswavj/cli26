-- Add barcode_printer column to company_details table
-- This allows users to configure a separate printer for barcode labels
-- through the admin UI instead of editing Java code

-- Add the column (if it doesn't exist)
ALTER TABLE company_details ADD COLUMN barcode_printer VARCHAR(255);

-- Optional: Set default value for existing installation
-- UPDATE company_details SET barcode_printer = 'SNBC TVSE LP 46 NEO BPLE' WHERE id = 1;

-- Verify the change
-- SELECT id, shop_name, printer_name, barcode_printer FROM company_details;
