-- Customer Management tables for Currency Exchange
-- Run on saiexchangedb

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

CREATE TABLE IF NOT EXISTS ce_customer (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(150) NOT NULL,
    phone_number VARCHAR(20) NULL,
    address TEXT NULL,
    notes TEXT NULL,
    is_active TINYINT(1) NOT NULL DEFAULT 1,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    KEY idx_ce_customer_name (name),
    KEY idx_ce_customer_phone (phone_number),
    KEY idx_ce_customer_active (is_active)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS ce_customer_account (
    id INT AUTO_INCREMENT PRIMARY KEY,
    customer_id INT NOT NULL,
    advance DECIMAL(18, 4) NOT NULL DEFAULT 0.0000,
    due DECIMAL(18, 4) NOT NULL DEFAULT 0.0000,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uk_ce_customer_account (customer_id),
    CONSTRAINT fk_ce_customer_account_customer FOREIGN KEY (customer_id) REFERENCES ce_customer (id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS ce_cus_advance (
    id INT AUTO_INCREMENT PRIMARY KEY,
    customer_id INT NOT NULL,
    amount DECIMAL(18, 4) NOT NULL,
    notes TEXT NULL,
    payment_id INT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    KEY idx_ce_cus_advance_customer (customer_id),
    KEY idx_ce_cus_advance_payment (payment_id),
    CONSTRAINT fk_ce_cus_advance_customer FOREIGN KEY (customer_id) REFERENCES ce_customer (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS ce_cus_due (
    id INT AUTO_INCREMENT PRIMARY KEY,
    customer_id INT NOT NULL,
    amount DECIMAL(18, 4) NOT NULL,
    notes TEXT NULL,
    payment_id INT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    KEY idx_ce_cus_due_customer (customer_id),
    KEY idx_ce_cus_due_payment (payment_id),
    CONSTRAINT fk_ce_cus_due_customer FOREIGN KEY (customer_id) REFERENCES ce_customer (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS ce_cus_due_collection (
    id INT AUTO_INCREMENT PRIMARY KEY,
    customer_id INT NOT NULL,
    amount DECIMAL(18, 4) NOT NULL,
    notes TEXT NULL,
    payment_id INT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    KEY idx_ce_cus_due_collection_customer (customer_id),
    KEY idx_ce_cus_due_collection_payment (payment_id),
    CONSTRAINT fk_ce_cus_due_collection_customer FOREIGN KEY (customer_id) REFERENCES ce_customer (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

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
