-- ============================================================
-- Inventory & Budget Tracker — Demo Schema
-- Run this in APEX: SQL Workshop > SQL Commands
-- ============================================================

BEGIN EXECUTE IMMEDIATE 'DROP TABLE inventory_transactions CASCADE CONSTRAINTS';
EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE inventory_items CASCADE CONSTRAINTS';
EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE budget_categories CASCADE CONSTRAINTS';
EXCEPTION WHEN OTHERS THEN NULL; END;
/

-- ---------- Tables ----------

CREATE TABLE budget_categories (
  category_id     NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  category_name   VARCHAR2(100) NOT NULL,
  budget_amount   NUMBER(12,2) NOT NULL,
  period_label    VARCHAR2(30) DEFAULT 'Q3 2026'
);

CREATE TABLE inventory_items (
  item_id         NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  sku             VARCHAR2(30) NOT NULL,
  item_name       VARCHAR2(150) NOT NULL,
  category_id     NUMBER NOT NULL REFERENCES budget_categories(category_id),
  bin_location    VARCHAR2(30),
  qty_on_hand     NUMBER DEFAULT 0,
  reorder_point   NUMBER DEFAULT 0,
  unit_cost       NUMBER(10,2) DEFAULT 0
);

CREATE TABLE inventory_transactions (
  transaction_id    NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  item_id           NUMBER NOT NULL REFERENCES inventory_items(item_id),
  category_id       NUMBER NOT NULL REFERENCES budget_categories(category_id),
  transaction_type  VARCHAR2(10) DEFAULT 'RECEIPT'
                      CHECK (transaction_type IN ('RECEIPT','USAGE','ADJUST')),
  quantity          NUMBER NOT NULL,
  amount            NUMBER(12,2) DEFAULT 0,
  vendor            VARCHAR2(120),
  transaction_date  DATE DEFAULT SYSDATE,
  notes             VARCHAR2(300)
);

-- ---------- Sample data ----------

INSERT INTO budget_categories (category_name, budget_amount) VALUES ('Warehouse Supplies', 15000);
INSERT INTO budget_categories (category_name, budget_amount) VALUES ('Safety Equipment', 8000);
INSERT INTO budget_categories (category_name, budget_amount) VALUES ('Office & Admin', 5000);
INSERT INTO budget_categories (category_name, budget_amount) VALUES ('Equipment & Tools', 20000);

INSERT INTO inventory_items (sku, item_name, category_id, bin_location, qty_on_hand, reorder_point, unit_cost)
  VALUES ('MD-1042', 'Galvanized Pipe Fitting 3/4"', 1, 'A-12-3', 840, 200, 3.20);
INSERT INTO inventory_items (sku, item_name, category_id, bin_location, qty_on_hand, reorder_point, unit_cost)
  VALUES ('MD-2210', 'Industrial Caster Wheel 6"', 4, 'C-04-1', 18, 50, 14.50);
INSERT INTO inventory_items (sku, item_name, category_id, bin_location, qty_on_hand, reorder_point, unit_cost)
  VALUES ('MD-3387', 'Safety Glasses, Clear (case)', 2, 'B-01-7', 312, 75, 1.85);
INSERT INTO inventory_items (sku, item_name, category_id, bin_location, qty_on_hand, reorder_point, unit_cost)
  VALUES ('MD-4459', 'Hex Bolt M10x40 (box of 100)', 1, 'A-08-2', 4, 25, 9.10);
INSERT INTO inventory_items (sku, item_name, category_id, bin_location, qty_on_hand, reorder_point, unit_cost)
  VALUES ('MD-6620', 'Nitrile Gloves, Large (case)', 2, 'B-02-4', 0, 40, 22.00);

INSERT INTO inventory_transactions (item_id, category_id, transaction_type, quantity, amount, vendor, transaction_date)
  VALUES (1, 1, 'RECEIPT', 500, 1600, 'Fastco Supply', SYSDATE - 40);
INSERT INTO inventory_transactions (item_id, category_id, transaction_type, quantity, amount, vendor, transaction_date)
  VALUES (4, 1, 'RECEIPT', 200, 1820, 'Fastco Supply', SYSDATE - 22);
INSERT INTO inventory_transactions (item_id, category_id, transaction_type, quantity, amount, vendor, transaction_date)
  VALUES (2, 4, 'RECEIPT', 40, 580, 'Industrial Wheel Co', SYSDATE - 15);
INSERT INTO inventory_transactions (item_id, category_id, transaction_type, quantity, amount, vendor, transaction_date)
  VALUES (3, 2, 'RECEIPT', 300, 555, 'SafetyFirst Inc', SYSDATE - 10);

COMMIT;

-- ---------- Views used by the app ----------

CREATE OR REPLACE VIEW v_inventory_status AS
SELECT
  i.item_id, i.sku, i.item_name, c.category_name, i.bin_location,
  i.qty_on_hand, i.reorder_point, i.unit_cost,
  ROUND(i.qty_on_hand * i.unit_cost, 2) AS extended_value,
  CASE
    WHEN i.qty_on_hand = 0 THEN 'Out of stock'
    WHEN i.qty_on_hand <= i.reorder_point THEN 'Low stock'
    ELSE 'In stock'
  END AS status
FROM inventory_items i
JOIN budget_categories c ON c.category_id = i.category_id;

CREATE OR REPLACE VIEW v_budget_summary AS
SELECT
  c.category_id, c.category_name, c.budget_amount,
  NVL(SUM(t.amount), 0) AS spent,
  c.budget_amount - NVL(SUM(t.amount), 0) AS remaining,
  ROUND(NVL(SUM(t.amount), 0) / c.budget_amount * 100) AS pct_used
FROM budget_categories c
LEFT JOIN inventory_transactions t
  ON t.category_id = c.category_id AND t.transaction_type = 'RECEIPT'
GROUP BY c.category_id, c.category_name, c.budget_amount;
