-- ============================================================
-- Client Self-Service Portal — Demo Schema
-- Run in APEX: SQL Workshop > SQL Commands
-- ============================================================

BEGIN EXECUTE IMMEDIATE 'DROP TABLE client_invoices CASCADE CONSTRAINTS';
EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE client_orders CASCADE CONSTRAINTS';
EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE clients CASCADE CONSTRAINTS';
EXCEPTION WHEN OTHERS THEN NULL; END;
/

CREATE TABLE clients (
  client_id     NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  company_name  VARCHAR2(150) NOT NULL,
  account_number VARCHAR2(20)
);

CREATE TABLE client_orders (
  order_id      NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  client_id     NUMBER NOT NULL REFERENCES clients(client_id),
  order_number  VARCHAR2(20) NOT NULL,
  placed_date   DATE DEFAULT SYSDATE,
  eta_date      DATE,
  delivered_date DATE,
  status        VARCHAR2(20) DEFAULT 'PLACED'
                  CHECK (status IN ('PLACED','PACKED','IN_TRANSIT','DELIVERED'))
);

CREATE TABLE client_invoices (
  invoice_id    NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  client_id     NUMBER NOT NULL REFERENCES clients(client_id),
  invoice_number VARCHAR2(20) NOT NULL,
  amount        NUMBER(12,2) NOT NULL,
  due_date      DATE,
  status        VARCHAR2(10) DEFAULT 'OPEN' CHECK (status IN ('OPEN','PAID'))
);

INSERT INTO clients (company_name, account_number) VALUES ('Northwind Retail Group', '38214');

INSERT INTO client_orders (client_id, order_number, placed_date, eta_date, status)
  VALUES (1, 'SO-88210', SYSDATE-7, SYSDATE, 'IN_TRANSIT');
INSERT INTO client_orders (client_id, order_number, placed_date, delivered_date, status)
  VALUES (1, 'SO-88176', SYSDATE-12, SYSDATE-9, 'DELIVERED');
INSERT INTO client_orders (client_id, order_number, placed_date, eta_date, status)
  VALUES (1, 'SO-88244', SYSDATE-3, SYSDATE+4, 'PLACED');

INSERT INTO client_invoices (client_id, invoice_number, amount, due_date, status)
  VALUES (1, 'INV-5510', 8420, SYSDATE+15, 'OPEN');
INSERT INTO client_invoices (client_id, invoice_number, amount, due_date, status)
  VALUES (1, 'INV-5498', 6440, SYSDATE-5, 'OPEN');
INSERT INTO client_invoices (client_id, invoice_number, amount, due_date, status)
  VALUES (1, 'INV-5477', 3120, SYSDATE-20, 'PAID');

COMMIT;

CREATE OR REPLACE VIEW v_client_orders AS
SELECT o.order_id, c.company_name, o.order_number, o.placed_date,
       o.eta_date, o.delivered_date, o.status
FROM client_orders o JOIN clients c ON c.client_id = o.client_id;

CREATE OR REPLACE VIEW v_client_invoices AS
SELECT i.invoice_id, c.company_name, i.invoice_number, i.amount,
       i.due_date, i.status
FROM client_invoices i JOIN clients c ON c.client_id = i.client_id;
