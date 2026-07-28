-- Currency Exchange transaction, stock, and stock transaction tables
-- Run once on saiexchangedb

CREATE TABLE IF NOT EXISTS ce_currency_exchange (
    id INT AUTO_INCREMENT PRIMARY KEY,
    customer_id INT NOT NULL,
    exchange_type TINYINT NOT NULL COMMENT '1=Purchase, 2=Sale',
    exchange_date DATE NOT NULL,
    currency_id INT NOT NULL,
    amount DECIMAL(18, 4) NOT NULL,
    counter_currency_id INT NOT NULL,
    counter_amount DECIMAL(18, 4) NOT NULL,
    paid DECIMAL(18, 4) NOT NULL DEFAULT 0.0000,
    balance DECIMAL(18, 4) NOT NULL DEFAULT 0.0000,
    payment_id INT NOT NULL,
    notes TEXT NULL,
    uid INT NOT NULL,
    is_cancelled TINYINT(1) NOT NULL DEFAULT 0,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    KEY idx_ce_currency_exchange_customer (customer_id),
    KEY idx_ce_currency_exchange_currency (currency_id),
    KEY idx_ce_currency_exchange_date (exchange_date),
    KEY idx_ce_currency_exchange_type (exchange_type),
    KEY idx_ce_currency_exchange_payment (payment_id),
    KEY idx_ce_currency_exchange_cancelled (is_cancelled),
    CONSTRAINT fk_ce_currency_exchange_customer FOREIGN KEY (customer_id) REFERENCES ce_customer (id),
    CONSTRAINT fk_ce_currency_exchange_currency FOREIGN KEY (currency_id) REFERENCES ce_currency (id),
    CONSTRAINT fk_ce_currency_exchange_counter FOREIGN KEY (counter_currency_id) REFERENCES ce_currency (id),
    CONSTRAINT fk_ce_currency_exchange_payment FOREIGN KEY (payment_id) REFERENCES ce_payment_method (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS ce_currency_stock (
    id INT AUTO_INCREMENT PRIMARY KEY,
    currency_id INT NOT NULL,
    quantity DECIMAL(18, 4) NOT NULL DEFAULT 0.0000,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uk_ce_currency_stock_currency (currency_id),
    CONSTRAINT fk_ce_currency_stock_currency FOREIGN KEY (currency_id) REFERENCES ce_currency (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS ce_currency_stock_adjustment (
    id INT AUTO_INCREMENT PRIMARY KEY,
    currency_id INT NOT NULL,
    adjustment_type TINYINT NOT NULL COMMENT '1=Add Stock, 2=Remove Stock',
    quantity DECIMAL(18, 4) NOT NULL,
    reason TEXT NOT NULL,
    uid INT NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    KEY idx_ce_stock_adj_currency (currency_id),
    KEY idx_ce_stock_adj_type (adjustment_type),
    CONSTRAINT fk_ce_stock_adj_currency FOREIGN KEY (currency_id) REFERENCES ce_currency (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS ce_currency_stock_transaction (
    id INT AUTO_INCREMENT PRIMARY KEY,
    exchange_id INT NULL,
    adjustment_id INT NULL,
    currency_id INT NOT NULL,
    txn_type TINYINT NOT NULL COMMENT '1=Purchase In, 2=Sale Out, 3=Stock Add, 4=Stock Remove',
    quantity DECIMAL(18, 4) NOT NULL,
    before_qty DECIMAL(18, 4) NOT NULL DEFAULT 0.0000,
    after_qty DECIMAL(18, 4) NOT NULL DEFAULT 0.0000,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    KEY idx_ce_stock_txn_exchange (exchange_id),
    KEY idx_ce_stock_txn_adjustment (adjustment_id),
    KEY idx_ce_stock_txn_currency (currency_id),
    KEY idx_ce_stock_txn_type (txn_type),
    CONSTRAINT fk_ce_stock_txn_exchange FOREIGN KEY (exchange_id) REFERENCES ce_currency_exchange (id),
    CONSTRAINT fk_ce_stock_txn_adjustment FOREIGN KEY (adjustment_id) REFERENCES ce_currency_stock_adjustment (id),
    CONSTRAINT fk_ce_currency_stock_txn_currency FOREIGN KEY (currency_id) REFERENCES ce_currency (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
