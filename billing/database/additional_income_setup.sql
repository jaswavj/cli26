-- Additional Income (bill_type = 7)
-- Run once on saiexchangedb

INSERT IGNORE INTO ce_bill_type (id, name) VALUES (7, 'additional income');

INSERT IGNORE INTO user_modules (id, module_name) VALUES (6, 'Additional Income');

CREATE TABLE IF NOT EXISTS ce_additional_income (
    id INT AUTO_INCREMENT PRIMARY KEY,
    particular VARCHAR(255) NOT NULL,
    amount DECIMAL(18, 4) NOT NULL,
    description TEXT NULL,
    income_date DATETIME NOT NULL,
    uid INT NOT NULL,
    is_active TINYINT(1) NOT NULL DEFAULT 1,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    KEY idx_ce_additional_income_date (income_date),
    KEY idx_ce_additional_income_active (is_active)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
