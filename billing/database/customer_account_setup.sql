-- ============================================================
-- customer_account table
-- One row per customer, created automatically when customer is added
-- ============================================================
CREATE TABLE IF NOT EXISTS customer_account (
    id          INT AUTO_INCREMENT PRIMARY KEY,
    customer_id INT NOT NULL,
    advance     DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    balance     DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    UNIQUE KEY uq_customer (customer_id),
    FOREIGN KEY (customer_id) REFERENCES customers(id) ON DELETE CASCADE
);

-- Back-fill existing customers (run once if customers already exist)
INSERT INTO customer_account (customer_id, advance, balance)
SELECT id, 0.00, 0.00
FROM customers
WHERE id NOT IN (SELECT customer_id FROM customer_account);
