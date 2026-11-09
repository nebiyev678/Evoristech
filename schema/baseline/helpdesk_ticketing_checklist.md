# Helpdesk Ticketing — 15-Minute Build Checklist

## 1. Load data (2 min)
SQL Workshop → SQL Commands → paste `helpdesk_ticketing_schema.sql` → Run.
Creates `agents`, `tickets`, and view `v_tickets`.

## 2. Create the app (1 min)
App Builder → Create App → Name: `Helpdesk Ticketing` → Create.

## 3. Pages 1 & 2 — Tickets report + detail form (5 min)
- Create Page → Report → Interactive Report
- Table/View: `V_TICKETS`, Page Name: `Tickets`
- ✅ Include Form Page → Page 1 (report) + Page 2 (ticket detail)
- Run to confirm all 6 sample tickets show.

### Add status-change buttons (Page 2)
- Create two buttons next to Save/Cancel:
  - `START_BTN` — Label: `Start Progress`
  - `RESOLVE_BTN` — Label: `Mark Resolved`
- Processing → Create Process (repeat for each):
  - Type: PL/SQL Code
  - When Button Pressed: `START_BTN`
    ```sql
    UPDATE tickets SET status = 'IN_PROGRESS' WHERE ticket_id = :P2_TICKET_ID;
    ```
  - When Button Pressed: `RESOLVE_BTN`
    ```sql
    UPDATE tickets
    SET status = 'RESOLVED', resolved_date = SYSDATE
    WHERE ticket_id = :P2_TICKET_ID;
    ```
- Branch back to Page 1 after each.

## 4. Page 3 — Dashboard (optional, 3 min)
- Create Page → Blank Page → Name: `Dashboard`
- Cards with counts by status:
  ```sql
  SELECT COUNT(*) FROM tickets WHERE status = 'NEW'
  ```
  ```sql
  SELECT COUNT(*) FROM tickets WHERE status = 'IN_PROGRESS'
  ```
  ```sql
  SELECT COUNT(*) FROM tickets WHERE status = 'RESOLVED'
  ```
- Set as Home page (App Builder → Edit App Properties → Home Link).

## Test
Tickets report → open a New ticket → Start Progress → status updates
→ open again → Mark Resolved → resolved_date stamps automatically.

**Style it:** apply `badge-pending`/`badge-instock`-style classes from
`custom.css` to the priority/status columns via HTML Expression, same
technique as the Approvals report.
