-- Counter currency (giving/receiving) for exchange transactions
-- Run once on saiexchangedb

ALTER TABLE ce_currency_exchange
    ADD COLUMN counter_currency_id INT NULL AFTER amount,
    ADD COLUMN counter_amount DECIMAL(18, 4) NULL AFTER counter_currency_id,
    ADD KEY idx_ce_currency_exchange_counter (counter_currency_id);

-- Set existing rows to INR if possible
UPDATE ce_currency_exchange e
INNER JOIN ce_currency c ON c.currency_code = 'INR'
SET e.counter_currency_id = c.id, e.counter_amount = e.amount
WHERE e.counter_currency_id IS NULL;

ALTER TABLE ce_currency_exchange
    MODIFY COLUMN counter_currency_id INT NOT NULL,
    MODIFY COLUMN counter_amount DECIMAL(18, 4) NOT NULL,
    ADD CONSTRAINT fk_ce_currency_exchange_counter FOREIGN KEY (counter_currency_id) REFERENCES ce_currency (id);
