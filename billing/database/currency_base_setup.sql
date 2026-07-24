-- Base currency flag on ce_currency (only one is_base=1 allowed)
-- Run once on saiexchangedb

ALTER TABLE ce_currency
    ADD COLUMN is_base TINYINT(1) NOT NULL DEFAULT 0 AFTER is_active,
    ADD KEY idx_ce_currency_base (is_base);
