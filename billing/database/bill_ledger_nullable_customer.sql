-- Allow ce_bill_ledger rows without customer (e.g. expense bill_type = 5)
-- Run if expense save fails with: Field 'customer_id' doesn't have a default value

ALTER TABLE ce_bill_ledger DROP FOREIGN KEY fk_ce_bill_ledger_customer;
ALTER TABLE ce_bill_ledger MODIFY customer_id INT NULL;
ALTER TABLE ce_bill_ledger
    ADD CONSTRAINT fk_ce_bill_ledger_customer FOREIGN KEY (customer_id) REFERENCES ce_customer (id);
