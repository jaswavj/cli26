-- Advance / purchase-balance payment support
-- Run once on saiexchangedb

INSERT IGNORE INTO ce_bill_type (id, name) VALUES (6, 'advance payment');

CREATE TABLE IF NOT EXISTS ce_cus_advance_payment (
    id INT AUTO_INCREMENT PRIMARY KEY,
    customer_id INT NOT NULL,
    amount DECIMAL(18, 4) NOT NULL,
    notes TEXT NULL,
    payment_id INT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    KEY idx_ce_cus_advance_payment_customer (customer_id),
    KEY idx_ce_cus_advance_payment_payment (payment_id),
    CONSTRAINT fk_ce_cus_advance_payment_customer FOREIGN KEY (customer_id) REFERENCES ce_customer (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
