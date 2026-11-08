-- ============================================================
-- Executive Dashboard — Demo Schema
-- Run in APEX: SQL Workshop > SQL Commands
-- ============================================================

BEGIN EXECUTE IMMEDIATE 'DROP TABLE orders CASCADE CONSTRAINTS';
EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE regions CASCADE CONSTRAINTS';
EXCEPTION WHEN OTHERS THEN NULL; END;
/

CREATE TABLE regions (
  region_id     NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  region_name   VARCHAR2(60) NOT NULL
);

CREATE TABLE orders (
  order_id      NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  order_number  VARCHAR2(20) NOT NULL,
  region_id     NUMBER NOT NULL REFERENCES regions(region_id),
  customer_name VARCHAR2(150),
  amount        NUMBER(12,2) NOT NULL,
  order_date    DATE DEFAULT SYSDATE,
  fulfilled_date DATE,
  status        VARCHAR2(20) DEFAULT 'OPEN'
                  CHECK (status IN ('OPEN','FULFILLED','CANCELLED','PAST_DUE'))
);

INSERT INTO regions (region_name) VALUES ('Northeast');
INSERT INTO regions (region_name) VALUES ('Midwest');
INSERT INTO regions (region_name) VALUES ('South');
INSERT INTO regions (region_name) VALUES ('West');

INSERT INTO orders (order_number, region_id, customer_name, amount, order_date, fulfilled_date, status)
  VALUES ('SO-88210', 1, 'Harborview Retail', 18400, SYSDATE-7, SYSDATE-2, 'FULFILLED');
INSERT INTO orders (order_number, region_id, customer_name, amount, order_date, status)
  VALUES ('SO-88244', 1, 'Crestline Supply', 9200, SYSDATE-3, 'OPEN');
INSERT INTO orders (order_number, region_id, customer_name, amount, order_date, status)
  VALUES ('SO-88251', 2, 'Prairie Wholesale', 14750, SYSDATE-2, 'OPEN');
INSERT INTO orders (order_number, region_id, customer_name, amount, order_date, status)
  VALUES ('SO-88203', 3, 'Southgate Mercantile', 6300, SYSDATE-9, 'PAST_DUE');
INSERT INTO orders (order_number, region_id, customer_name, amount, order_date, fulfilled_date, status)
  VALUES ('SO-88190', 4, 'Pacific Rim Traders', 22100, SYSDATE-11, SYSDATE-6, 'FULFILLED');
INSERT INTO orders (order_number, region_id, customer_name, amount, order_date, status)
  VALUES ('SO-88260', 2, 'Lakeside Distributors', 5100, SYSDATE-1, 'OPEN');

COMMIT;

CREATE OR REPLACE VIEW v_orders_detail AS
SELECT o.order_id, o.order_number, r.region_name, o.customer_name,
       o.amount, o.order_date, o.fulfilled_date, o.status
FROM orders o JOIN regions r ON r.region_id = o.region_id;

CREATE OR REPLACE VIEW v_region_summary AS
SELECT r.region_name, NVL(SUM(o.amount),0) AS total_revenue, COUNT(o.order_id) AS order_count
FROM regions r LEFT JOIN orders o ON o.region_id = r.region_id AND o.status <> 'CANCELLED'
GROUP BY r.region_name;
