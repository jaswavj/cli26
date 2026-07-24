-- Expense payment method and bill ledger integration (bill_type = 5)

INSERT IGNORE INTO ce_bill_type (id, name) VALUES (5, 'expense');

ALTER TABLE expense_entry
    ADD COLUMN payment_id INT NULL AFTER amount;

ALTER TABLE ce_bill_ledger DROP FOREIGN KEY fk_ce_bill_ledger_customer;
ALTER TABLE ce_bill_ledger MODIFY customer_id INT NULL;
ALTER TABLE ce_bill_ledger
    ADD CONSTRAINT fk_ce_bill_ledger_customer FOREIGN KEY (customer_id) REFERENCES ce_customer (id);
