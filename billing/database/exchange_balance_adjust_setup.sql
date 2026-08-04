-- Track due/advance offset applied on exchange bills
-- Run once on saiexchangedb

ALTER TABLE ce_currency_exchange
    ADD COLUMN due_adjusted DECIMAL(18, 4) NOT NULL DEFAULT 0.0000 AFTER balance,
    ADD COLUMN advance_adjusted DECIMAL(18, 4) NOT NULL DEFAULT 0.0000 AFTER due_adjusted;
