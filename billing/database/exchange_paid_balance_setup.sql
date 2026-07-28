-- Add paid / balance columns to currency exchange
-- Run once on saiexchangedb

ALTER TABLE ce_currency_exchange
    ADD COLUMN paid DECIMAL(18, 4) NOT NULL DEFAULT 0.0000 AFTER counter_amount,
    ADD COLUMN balance DECIMAL(18, 4) NOT NULL DEFAULT 0.0000 AFTER paid;

-- Backfill existing rows as fully paid
UPDATE ce_currency_exchange
SET paid = counter_amount, balance = 0.0000
WHERE paid = 0 AND balance = 0 AND counter_amount > 0;
