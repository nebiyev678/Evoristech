# Executive Dashboard — 15-Minute Build Checklist

## 1. Load data (2 min)
SQL Workshop → SQL Commands → paste `executive_dashboard_schema.sql` → Run.
Creates `regions`, `orders`, and views `v_orders_detail`, `v_region_summary`.

## 2. Create the app (1 min)
App Builder → Create App → Name: `Executive Dashboard` → Create.

## 3. Pages 1 & 2 — Orders report + detail form (5 min)
- Create Page → Report → Interactive Report
- Table/View: `V_ORDERS_DETAIL`, Page Name: `Orders`
- ✅ Include Form Page → creates report (Page 1) + form (Page 2)
- Run to confirm the 6 sample orders show with status.

## 4. Page 3 — Dashboard / Home (5 min)
- Create Page → Blank Page → Name: `Dashboard`
- Add KPI cards (SQL sources):
  ```sql
  SELECT SUM(amount) FROM orders WHERE status <> 'CANCELLED'
  ```
  ```sql
  SELECT COUNT(*) FROM orders WHERE status = 'OPEN'
  ```
  ```sql
  SELECT COUNT(*) FROM orders WHERE status = 'PAST_DUE'
  ```
  ```sql
  SELECT ROUND(SUM(CASE WHEN status='FULFILLED' THEN 1 ELSE 0 END)/COUNT(*)*100)
  FROM orders WHERE status <> 'CANCELLED'
  ```
- Add a **Chart region** (Bar) source: `SELECT region_name, total_revenue FROM v_region_summary`
- Add a **Classic Report** below: 5 most recent orders
  (`SELECT * FROM v_orders_detail ORDER BY order_date DESC FETCH FIRST 5 ROWS ONLY`)
  with a link to Page 1.
- App Builder → Edit App Properties → Home Link → set to this page.

## Test
Dashboard shows live totals pulled straight from `orders` → click into
Orders → click a row → edit status → totals on Dashboard reflect it on
next visit. That's the "always current, no manual refresh" pitch.

**Style it:** use the same `custom.css`/`custom.js` files from before —
the `.kpi-card` and `.progress-track` classes apply directly here too.
