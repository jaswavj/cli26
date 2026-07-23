-- ============================================================
-- Day Book — Manual Opening Balance
-- Run once on your MySQL database
-- ============================================================
CREATE TABLE IF NOT EXISTS daybook_opening_balance (
    id            INT AUTO_INCREMENT PRIMARY KEY,
    balance_date  DATE NOT NULL,
    amount        DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    balance_type  VARCHAR(10) NOT NULL DEFAULT 'cash' COMMENT 'cash or bank',
    notes         VARCHAR(255) DEFAULT NULL,
    uid           INT DEFAULT NULL,
    entry_date    DATE NOT NULL,
    entry_time    TIME NOT NULL,
    is_active     TINYINT(1) NOT NULL DEFAULT 1,
    INDEX idx_balance_date (balance_date),
    INDEX idx_active_date (is_active, balance_date),
    INDEX idx_balance_type (balance_type, is_active, balance_date)
);

-- Example:
-- INSERT INTO daybook_opening_balance (balance_date, amount, notes, uid, entry_date, entry_time)
-- VALUES ('2026-07-01', 5000.00, 'Opening cash in hand', 1, CURDATE(), CURTIME());
