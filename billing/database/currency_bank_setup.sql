-- Bank currency flag on ce_currency (only one is_bank=1 allowed)
-- Run once on saiexchangedb

ALTER TABLE ce_currency
    ADD COLUMN is_bank TINYINT(1) NOT NULL DEFAULT 0 AFTER is_base,
    ADD KEY idx_ce_currency_bank (is_bank);
