-- Payment method master and columns for customer account transactions
-- Run once on saiexchangedb

CREATE TABLE IF NOT EXISTS ce_payment_method (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    is_cash TINYINT(1) NOT NULL DEFAULT 0,
    is_active TINYINT(1) NOT NULL DEFAULT 1,
    UNIQUE KEY uk_ce_payment_method_name (name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT IGNORE INTO ce_payment_method (id, name, is_cash) VALUES
(1, 'Cash', 1),
(2, 'UPI', 0),
(3, 'Credit Card', 0),
(4, 'Debit Card', 0),
(5, 'Cheque', 0),
(6, 'NEFT', 0),
(7, 'IMPS', 0);

ALTER TABLE ce_cus_advance
    ADD COLUMN payment_id INT NULL AFTER notes,
    ADD KEY idx_ce_cus_advance_payment (payment_id);

ALTER TABLE ce_cus_due
    ADD COLUMN payment_id INT NULL AFTER notes,
    ADD KEY idx_ce_cus_due_payment (payment_id);

ALTER TABLE ce_cus_due_collection
    ADD COLUMN payment_id INT NULL AFTER notes,
    ADD KEY idx_ce_cus_due_collection_payment (payment_id);

ALTER TABLE ce_bill_ledger
    ADD COLUMN is_cash DECIMAL(18, 4) NOT NULL DEFAULT 0.0000 AFTER final_due,
    ADD COLUMN is_bank DECIMAL(18, 4) NOT NULL DEFAULT 0.0000 AFTER is_cash,
    ADD COLUMN payment_id INT NULL AFTER is_bank,
    ADD KEY idx_ce_bill_ledger_payment (payment_id);
