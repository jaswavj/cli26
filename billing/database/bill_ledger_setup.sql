-- Bill type master and ledger for customer account transactions
-- ce_bill_type already exists in DB with:
-- 1 = advance, 2 = due, 3 = due collection, 4 = exchange bill

CREATE TABLE IF NOT EXISTS ce_bill_type (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    UNIQUE KEY uk_ce_bill_type_name (name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT IGNORE INTO ce_bill_type (id, name) VALUES
(1, 'advance'),
(2, 'due'),
(3, 'due collection'),
(4, 'exchange bill');

CREATE TABLE IF NOT EXISTS ce_bill_ledger (
    id INT AUTO_INCREMENT PRIMARY KEY,
    customer_id INT NOT NULL,
    bill_type INT NOT NULL,
    bill_id INT NOT NULL,
    advance DECIMAL(18, 4) NOT NULL DEFAULT 0.0000,
    final_advance DECIMAL(18, 4) NOT NULL DEFAULT 0.0000,
    due DECIMAL(18, 4) NOT NULL DEFAULT 0.0000,
    final_due DECIMAL(18, 4) NOT NULL DEFAULT 0.0000,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    KEY idx_ce_bill_ledger_customer (customer_id),
    KEY idx_ce_bill_ledger_type (bill_type),
    KEY idx_ce_bill_ledger_bill (bill_type, bill_id),
    CONSTRAINT fk_ce_bill_ledger_customer FOREIGN KEY (customer_id) REFERENCES ce_customer (id),
    CONSTRAINT fk_ce_bill_ledger_type FOREIGN KEY (bill_type) REFERENCES ce_bill_type (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
