# Approval Workflow — 15-Minute Build Checklist

Do these in order. Copy-paste the exact values given.

---

## 1. Load the data (2 min)

- **SQL Workshop → SQL Commands**
- Paste the full contents of `approval_workflow_schema.sql` → **Run**
- You now have: `departments`, `employees`, `purchase_orders`, and a
  view `v_po_approvals`.

---

## 2. Create the app (1 min)

- **App Builder → Create App**
- Name: `Approval Workflow`
- Theme: leave default (Redwood/Vita)
- **Create Application**

---

## 3. Pages 1 & 2 — Report + Form (5 min)

- Inside the app: **Create Page**
- Choose **Report → Interactive Report**
- **Table/View Owner:** your schema — **Table/View Name:** `V_PO_APPROVALS`
- **Page Name:** `Approvals`
- ✅ Check **"Include Form Page"**
- **Create Page** — this makes Page 1 (report) and Page 2 (form)
  together, fully working, with click-to-edit already wired up.
- Click **Run Application** to confirm both pages load and the report
  shows your 5 sample rows.

---

## 4. Add Approve/Reject to the Form (Page 2) (5 min)

- **Page Designer → Page 2**
- Find the region with the existing **Save/Cancel/Delete** buttons
- **Right-click the region → Create Button** (repeat twice):
  - Button 1 — Label: `Approve` — Name: `APPROVE_BTN`
  - Button 2 — Label: `Reject` — Name: `REJECT_BTN`
- **Processing tab (left side) → Create Process** (repeat twice):
  - **Type:** PL/SQL Code
  - **Name:** `Approve PO`
  - **Server-side Condition → When Button Pressed:** `APPROVE_BTN`
  - **PL/SQL Code:**
    ```sql
    UPDATE purchase_orders
    SET status = 'APPROVED', decided_date = SYSDATE, decided_by = :APP_USER
    WHERE po_id = :P2_PO_ID;
    ```
  - Repeat for **Reject PO**, condition `REJECT_BTN`, same code with
    `status = 'REJECTED'`
- **Save**, then **Run** — open a pending row, click Approve, confirm
  the status updates when you go back to Page 1.

---

## 5. Page 3 — Dashboard (2 min, optional but recommended)

- **Create Page → Blank Page** — Name: `Dashboard`
- Add 2–3 **"Value"** or **Cards** regions with SQL sources:
  ```sql
  SELECT COUNT(*) FROM purchase_orders WHERE status = 'PENDING'
  ```
  ```sql
  SELECT SUM(amount) FROM purchase_orders WHERE status = 'PENDING'
  ```
- **App Builder → Edit App Properties → Home Link** → point it to this
  page, so it's the first thing the client sees.

---

## You're done

Run the app, click through Dashboard → Approvals → click a pending
row → Approve/Reject → confirm it updates. That's your live demo.

**Before the client call:** Shared Components → Theme Roller → swap
the accent color to something close to their brand. Takes 2 minutes
and makes it look custom-built for them.
