-- Currency transfer (give / get) with customer
-- Run once on saiexchangedb

CREATE TABLE IF NOT EXISTS ce_currency_transfer (
    id INT AUTO_INCREMENT PRIMARY KEY,
    customer_id INT NOT NULL,
    currency_id INT NOT NULL,
    transfer_type TINYINT NOT NULL COMMENT '1=Give, 2=Get',
    quantity DECIMAL(18, 4) NOT NULL,
    transfer_date DATE NOT NULL,
    notes TEXT NULL,
    status TINYINT NOT NULL DEFAULT 0 COMMENT '0=Open, 1=Returned',
    return_date DATE NULL,
    uid INT NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    KEY idx_ce_currency_transfer_customer (customer_id),
    KEY idx_ce_currency_transfer_currency (currency_id),
    KEY idx_ce_currency_transfer_date (transfer_date),
    KEY idx_ce_currency_transfer_type (transfer_type),
    KEY idx_ce_currency_transfer_status (status),
    CONSTRAINT fk_ce_currency_transfer_customer FOREIGN KEY (customer_id) REFERENCES ce_customer (id),
    CONSTRAINT fk_ce_currency_transfer_currency FOREIGN KEY (currency_id) REFERENCES ce_currency (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

ALTER TABLE ce_currency_stock_transaction
    ADD COLUMN transfer_id INT NULL AFTER adjustment_id,
    ADD KEY idx_ce_stock_txn_transfer (transfer_id);
