-- Manual stock add/remove with reason
-- Run once on saiexchangedb (after currency_exchange_setup.sql)

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

ALTER TABLE ce_currency_stock_transaction
    MODIFY COLUMN exchange_id INT NULL,
    ADD COLUMN adjustment_id INT NULL AFTER exchange_id,
    ADD KEY idx_ce_stock_txn_adjustment (adjustment_id);

-- Drop FK on exchange_id if exists so NULL is allowed (MySQL may need this on existing DB)
-- ALTER TABLE ce_currency_stock_transaction DROP FOREIGN KEY fk_ce_stock_txn_exchange;

ALTER TABLE ce_currency_stock_transaction
    ADD CONSTRAINT fk_ce_stock_txn_adjustment FOREIGN KEY (adjustment_id) REFERENCES ce_currency_stock_adjustment (id);
