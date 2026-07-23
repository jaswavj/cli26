-- ============================================================
-- Day Book Opening Balance — add Cash / Bank type
-- Run once on your MySQL database
-- ============================================================

ALTER TABLE daybook_opening_balance
    ADD COLUMN balance_type VARCHAR(10) NOT NULL DEFAULT 'cash'
        COMMENT 'cash = Cash Book opening, bank = Day Book bank opening'
        AFTER amount;

-- Existing rows default to cash (Cash Book)
UPDATE daybook_opening_balance SET balance_type = 'cash' WHERE balance_type IS NULL OR balance_type = '';

ALTER TABLE daybook_opening_balance
    ADD INDEX idx_balance_type (balance_type, is_active, balance_date);
