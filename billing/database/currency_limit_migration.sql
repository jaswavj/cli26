-- Run this ONLY if you already created ce_currency with min_value / max_value columns

CREATE TABLE IF NOT EXISTS ce_currency_limit (
    id INT AUTO_INCREMENT PRIMARY KEY,
    currency_id INT NOT NULL,
    ref_currency_id INT NOT NULL,
    min_value DECIMAL(18, 4) NOT NULL DEFAULT 0.0000,
    max_value DECIMAL(18, 4) NOT NULL DEFAULT 0.0000,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uk_ce_currency_limit_pair (currency_id, ref_currency_id),
    KEY idx_ce_currency_limit_ref (ref_currency_id),
    CONSTRAINT fk_ce_limit_currency FOREIGN KEY (currency_id) REFERENCES ce_currency (id) ON DELETE CASCADE,
    CONSTRAINT fk_ce_limit_ref_currency FOREIGN KEY (ref_currency_id) REFERENCES ce_currency (id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

ALTER TABLE ce_currency DROP COLUMN IF EXISTS min_value;
ALTER TABLE ce_currency DROP COLUMN IF EXISTS max_value;
