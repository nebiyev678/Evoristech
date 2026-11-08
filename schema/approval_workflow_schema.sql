-- ============================================================
-- Approval Workflow — Demo Schema
-- Run this in APEX: SQL Workshop > SQL Commands (or SQL Scripts)
-- Works in your APEX workspace schema as-is.
-- ============================================================

-- Clean start (safe to ignore errors if tables don't exist yet)
BEGIN
  EXECUTE IMMEDIATE 'DROP TABLE purchase_orders CASCADE CONSTRAINTS';
EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN
  EXECUTE IMMEDIATE 'DROP TABLE employees CASCADE CONSTRAINTS';
EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN
  EXECUTE IMMEDIATE 'DROP TABLE departments CASCADE CONSTRAINTS';
EXCEPTION WHEN OTHERS THEN NULL; END;
/

-- ---------- Tables ----------

CREATE TABLE departments (
  department_id    NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  department_name  VARCHAR2(100) NOT NULL
);

CREATE TABLE employees (
  employee_id      NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  employee_name    VARCHAR2(120) NOT NULL,
  department_id    NUMBER NOT NULL REFERENCES departments(department_id),
  job_title        VARCHAR2(100),
  is_approver      VARCHAR2(1) DEFAULT 'N' CHECK (is_approver IN ('Y','N'))
);

CREATE TABLE purchase_orders (
  po_id            NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  po_number        VARCHAR2(20) NOT NULL,
  requester_id     NUMBER NOT NULL REFERENCES employees(employee_id),
  department_id    NUMBER NOT NULL REFERENCES departments(department_id),
  description      VARCHAR2(300),
  amount           NUMBER(12,2) NOT NULL,
  status           VARCHAR2(20) DEFAULT 'PENDING'
                     CHECK (status IN ('PENDING','APPROVED','REJECTED')),
  created_date     DATE DEFAULT SYSDATE,
  decided_date     DATE,
  decided_by       VARCHAR2(120),
  decision_notes   VARCHAR2(300)
);

-- ---------- Sample data ----------

INSERT INTO departments (department_name) VALUES ('Operations');
INSERT INTO departments (department_name) VALUES ('Logistics');
INSERT INTO departments (department_name) VALUES ('Technology');
INSERT INTO departments (department_name) VALUES ('Admin');

INSERT INTO employees (employee_name, department_id, job_title, is_approver)
  VALUES ('Priya Natarajan', 1, 'Warehouse Lead', 'N');
INSERT INTO employees (employee_name, department_id, job_title, is_approver)
  VALUES ('Marcus Bell', 2, 'Fleet Coordinator', 'N');
INSERT INTO employees (employee_name, department_id, job_title, is_approver)
  VALUES ('Devon Ashwood', 3, 'IT Specialist', 'N');
INSERT INTO employees (employee_name, department_id, job_title, is_approver)
  VALUES ('Ana Souza', 4, 'Facilities Coordinator', 'N');
INSERT INTO employees (employee_name, department_id, job_title, is_approver)
  VALUES ('Jordan Reyes', 1, 'Finance Manager', 'Y');

INSERT INTO purchase_orders (po_number, requester_id, department_id, description, amount, status, created_date)
  VALUES ('PO-2291', 1, 1, 'Replacement pallet racking', 12400, 'PENDING', SYSDATE - 2);
INSERT INTO purchase_orders (po_number, requester_id, department_id, description, amount, status, created_date)
  VALUES ('PO-2290', 2, 2, 'Fleet tire replacement — 4 vehicles', 3180, 'PENDING', SYSDATE - 2);
INSERT INTO purchase_orders (po_number, requester_id, department_id, description, amount, status, created_date, decided_date, decided_by)
  VALUES ('PO-2289', 4, 4, 'Office supplies restock', 860, 'APPROVED', SYSDATE - 3, SYSDATE - 2, 'Jordan Reyes');
INSERT INTO purchase_orders (po_number, requester_id, department_id, description, amount, status, created_date)
  VALUES ('PO-2288', 3, 3, 'Laptop replacements — 6 units', 21900, 'PENDING', SYSDATE - 3);
INSERT INTO purchase_orders (po_number, requester_id, department_id, description, amount, status, created_date, decided_date, decided_by, decision_notes)
  VALUES ('PO-2287', 1, 1, 'Extra forklift rental — 2 weeks', 2140, 'REJECTED', SYSDATE - 4, SYSDATE - 3, 'Jordan Reyes', 'Missing vendor quote');

COMMIT;

-- ---------- Helper view (used by the IR and dashboard pages) ----------

CREATE OR REPLACE VIEW v_po_approvals AS
SELECT
  po.po_id,
  po.po_number,
  e.employee_name AS requester,
  d.department_name,
  po.description,
  po.amount,
  po.status,
  po.created_date,
  po.decided_date,
  po.decided_by,
  po.decision_notes
FROM purchase_orders po
JOIN employees e   ON e.employee_id = po.requester_id
JOIN departments d ON d.department_id = po.department_id;
