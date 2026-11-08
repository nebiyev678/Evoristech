# Approval Workflow — APEX Build Guide (3 pages, ~30–40 min)

This builds a real, working Oracle APEX app: an Interactive Report of
purchase orders, a Form to approve/reject, and a Dashboard home page.
Use it as your reusable client demo — swap the sample data for a
prospect's own scenario before each pitch.

---

## Step 1 — Load the schema

1. In your APEX workspace: **SQL Workshop → SQL Commands**
2. Paste the contents of `approval_workflow_schema.sql` and run it.
   This creates `departments`, `employees`, `purchase_orders`, sample
   data, and a view `v_po_approvals` that joins everything together
   for reporting.

---

## Step 2 — Create the app shell

1. **App Builder → Create App**
2. Name it **"Approval Workflow"**, choose a theme (Vita/Redwood are
   fine), click **Create Application**.

---

## Step 3 — Page 1 & 2: Report + Form (built together)

APEX's built-in wizard creates both pages in one step.

1. Inside your new app: **Create Page → Report → Interactive Report**
2. **Table/View:** `V_PO_APPROVALS`
3. Name the page **"Approvals"**
4. On the next screen, tick **"Include Form Page"** — this
   auto-creates Page 2, a form for editing one PO at a time, linked
   from the report.
5. Finish the wizard.

You now have a working report + edit form. Run the app to confirm.

### Polish the Interactive Report (Page 1)

- Open **Page 1 → Approvals region → STATUS column**
- Set **Type → "Highlight"** or use **Column Formatting → HTML
  Expression** so PENDING/APPROVED/REJECTED render as colored badges:
  ```html
  <span style="padding:3px 10px;border-radius:999px;font-size:11px;
  font-weight:700;
  background:#{case when STATUS='APPROVED' then 'D8F0E4;color:#116B45'
  when STATUS='REJECTED' then 'F6D6D2;color:#8C2019'
  else 'FCEFD9;color:#8A5A12' end}">#STATUS#</span>
  ```
  (APEX Interactive Reports support HTML Expression columns —
  set the column's "Escape special characters" to **No** for this
  one column only.)
- Add a **Filter** on Status (pre-set to PENDING) so the default view
  matches what you'd show a client: "here's what's waiting on you."

### Add Approve/Reject actions (Page 2 — the Form)

1. Open **Page 2 (the form)**
2. **Create → Button**, region: same as Save/Cancel buttons
   - Button 1: label **"Approve"**, name `APPROVE_BTN`
   - Button 2: label **"Reject"**, name `REJECT_BTN`
3. **Create a Page Process** (Processing section) for each button:
   - **Process type:** PL/SQL Code
   - **When Button Pressed:** select the matching button
   - **PL/SQL Code (Approve):**
     ```sql
     UPDATE purchase_orders
     SET status = 'APPROVED',
         decided_date = SYSDATE,
         decided_by = :APP_USER
     WHERE po_id = :P2_PO_ID;
     ```
   - **PL/SQL Code (Reject):** same, with `status = 'REJECTED'`
4. Add a **Branch** after each process back to Page 1 so the user
   lands back on the report after deciding.

That's your working approve/reject loop — no page reload tricks
needed, just standard APEX processing.

---

## Step 4 — Page 3: Dashboard / Home

1. **Create Page → Blank Page**, name it **"Dashboard"**, make it
   your app's Home page (App Builder → Edit App Properties →
   Home Link).
2. Add a **Cards Region** (or 4 separate "Value" regions) at the top,
   each with a SQL source like:
   ```sql
   SELECT COUNT(*) FROM purchase_orders WHERE status = 'PENDING'
   ```
   Repeat for **Approved this week**
   (`decided_date >= TRUNC(SYSDATE,'IW')`), **Total pending value**
   (`SUM(amount) WHERE status='PENDING'`), and **Avg decision time**
   if you want a fourth card.
3. Below the cards, add a **Chart region** (bar or donut) sourced
   from:
   ```sql
   SELECT status, COUNT(*) cnt
   FROM purchase_orders
   GROUP BY status
   ```
4. Add a **Classic Report** or **Cards region** underneath showing
   the 5 most recent POs (`ORDER BY created_date DESC FETCH FIRST 5
   ROWS ONLY`) with a link to Page 1 ("View all approvals").

---

## Step 5 — Theme it for the client

- **App Builder → Shared Components → Theme Roller** to quickly match
  a prospect's brand color before a call (matches the teal accent
  used in the mockups — swap for their brand color in 2 minutes).
- **Shared Components → Logo** — swap in the client's logo if you
  have it, or leave your own branding for a generic pitch.

---

## What to say when demoing

> "This whole thing — three pages, live approve/reject logic, a
> dashboard — took under an hour to build directly on your database.
> No new licensing, no separate hosting. If we build this for real,
> we'd tailor the fields and approval rules to your actual process."

That contrast (their current spreadsheet/email process vs. this in
under an hour) is the pitch — let the build speed do the selling.
