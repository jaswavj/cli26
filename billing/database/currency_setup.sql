-- Currency Exchange: currency master + exchange limits per existing currency
-- Run on saiexchangedb

CREATE TABLE IF NOT EXISTS ce_currency (
    id INT AUTO_INCREMENT PRIMARY KEY,
    currency_code VARCHAR(10) NOT NULL,
    currency_name VARCHAR(100) NOT NULL,
    is_active TINYINT(1) NOT NULL DEFAULT 1,
    is_base TINYINT(1) NOT NULL DEFAULT 0,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uk_ce_currency_code (currency_code),
    KEY idx_ce_currency_active (is_active),
    KEY idx_ce_currency_base (is_base)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Limits of NEW currency against each EXISTING currency at add/edit time
-- Example: adding INR when USD exists -> currency_id=INR, ref_currency_id=USD, min/max
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

-- Migration if old ce_currency had min_value / max_value columns:
-- ALTER TABLE ce_currency DROP COLUMN min_value, DROP COLUMN max_value;
