# Client Self-Service Portal — 15-Minute Build Checklist

## 1. Load data (2 min)
SQL Workshop → SQL Commands → paste `client_portal_schema.sql` → Run.
Creates `clients`, `client_orders`, `client_invoices`, and two views.

## 2. Create the app (1 min)
App Builder → Create App → Name: `Client Portal` → Create.

## 3. Page 1 — My Orders (5 min)
- Create Page → Report → Interactive Report
- Table/View: `V_CLIENT_ORDERS`, Page Name: `My Orders`
- Leave "Include Form Page" unchecked (clients view, don't need to edit)
- Run to confirm the 3 sample orders display with status.

Optional polish: format the `STATUS` column as a badge (same technique
as before) so Placed/Packed/In Transit/Delivered are color-coded.

## 4. Page 2 — Invoices (4 min)
- Create Page → Report → Interactive Report
- Table/View: `V_CLIENT_INVOICES`, Page Name: `Invoices`
- Add a Filter default: `STATUS = 'OPEN'` so clients see what they owe first.

## 5. Page 3 — Dashboard / Home (3 min)
- Create Page → Blank Page → Name: `Dashboard`
- KPI cards:
  ```sql
  SELECT COUNT(*) FROM client_orders WHERE status = 'IN_TRANSIT'
  ```
  ```sql
  SELECT SUM(amount) FROM client_invoices WHERE status = 'OPEN'
  ```
- Add a Classic Report of recent orders, linking to Page 1.
- App Builder → Edit App Properties → Home Link → set to this page.

## Test
Dashboard shows live order/invoice counts → click into My Orders → see
tracking status → click into Invoices → see what's open. This is the
"fewer status-check emails for your team" pitch in action.

**Note on real client access:** for an actual client-facing version,
set up **Application Access Control** or a public/guest scheme so each
client only sees their own `client_id` — this demo skips that step
since it's single-client sample data.
