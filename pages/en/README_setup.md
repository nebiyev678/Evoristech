# APEX Client Demo Templates: Page Code Pack

Five pages matching the "APEX Client Demo Templates" canvas. Each page is
**one region plus (optionally) one Ajax process**. You don't need page
items, a CSS file upload or `#APP_FILES#`.

| File | Page | Needs schema | Buttons? |
|---|---|---|---|
| 01_approvals_page.sql | Approvals | approval_workflow_schema.sql | Approve / Reject |
| 02_inventory_page.sql | Inventory + Budget | inventory_budget_schema.sql | Receive stock |
| 03_executive_dashboard_page.sql | Executive Dashboard | executive_dashboard_schema.sql | none |
| 04_helpdesk_page.sql | Helpdesk kanban | helpdesk_ticketing_schema.sql | Start / Resolve / Resume |
| 05_client_portal_page.sql | Client Portal | client_portal_schema.sql | none |

You can put all five pages in **one app** (e.g. your App 102) as long as
you've run all five schema scripts in the same workspace.

---

## Setup per page (about 3 minutes each)

**1. Create the page**
Create Page, then **Blank Page**. Name it (e.g. `Approvals`) and tick
**Create Navigation Menu Entry** so it appears in the sidebar.

**2. Add the styles**
Click the **page name** at the top of the left tree, then in the right
panel go to **CSS > Inline**. Paste all of `00_shared_styles.css`.

**3. Add the JavaScript** (only Approvals, Inventory and Helpdesk)
Same page properties, **JavaScript > Function and Global Variable
Declaration**. Paste all of `00_shared_javascript.js`.

**4. Create the region**
Right-click **Body**, then **Create Region**.
- Type: **Dynamic Content**
- Source > Language: **PL/SQL**, **PL/SQL Function Body returning a CLOB**
- Paste section **[A]** from the page's .sql file (from `declare` to the
  final `end;`)
- Appearance > Template: **Blank with Attributes**

**5. Create the Ajax process** (only pages with buttons)
Click the **Processing** tab (second icon on the left panel). Right-click
**Ajax Callback**, then **Create Process**.
- Name: exactly as written in section **[B]** (`PO_DECISION`,
  `RECEIVE_STOCK` or `TICKET_STATUS`)
- Type: **Execute Code**
- Paste section **[B]**

**6. Save and Run.**

---

## How it works (so you can explain it to clients)

- The region runs PL/SQL that reads your tables and outputs the designed
  HTML, so KPIs, tables and badges are always live data.
- Each button calls `dtAction(...)`, which sends the row ID to the
  Ajax process by name. The process updates the table and the page
  reloads with fresh numbers.

## If something goes wrong

- **Page shows the raw code or an error in the region:** check you
  picked *Function Body returning a CLOB* and pasted only section [A].
- **Button does nothing:** the JavaScript wasn't pasted on that page, or
  the Ajax process name doesn't match exactly (it's case-sensitive).
- **"Action failed" alert:** open DevTools, Network tab, click the failed
  `wwv_flow.ajax` request and the Response shows the PL/SQL error.
- **ORA-00942 table or view does not exist:** run that page's schema
  script first.
- **Unstyled page:** the Inline CSS wasn't pasted on *that* page (each
  page needs its own copy).

## Reusing for a client pitch

Once all five pages work, **App Builder > your app > Export**. That
export is APEX-generated, so it's a real import file you can install in
any workspace in one click.
