# Inventory & Budget Tracker — 15-Minute Build Checklist

## 1. Load the data (2 min)

- **SQL Workshop → SQL Commands**
- Paste all of `inventory_budget_schema.sql` → **Run**
- Creates `budget_categories`, `inventory_items`, `inventory_transactions`,
  plus views `v_inventory_status` and `v_budget_summary`.

---

## 2. Create the app (1 min)

- **App Builder → Create App**
- Name: `Inventory & Budget Tracker`
- **Create Application**

---

## 3. Pages 1 & 2 — Inventory report + item form (5 min)

- **Create Page → Report → Interactive Report**
- **Table/View Name:** `V_INVENTORY_STATUS`
- **Page Name:** `Inventory`
- ✅ **"Include Form Page"**
- **Create Page** — Page 1 (report) + Page 2 (item detail form) done.
- **Run Application** to confirm the report loads with the 5 sample
  items and status shows correctly (Low stock / Out of stock / In stock).

### Add "Receive Stock" logic to Page 2

- **Page Designer → Page 2**
- **Create Item** next to Save/Cancel: two number/text page items —
  `P2_RECEIVE_QTY` (Quantity received) and `P2_RECEIVE_COST` (Total cost)
- **Create Button** — Label: `Log Receipt & Update Stock`, Name: `RECEIVE_BTN`
- **Processing → Create Process**:
  - **Type:** PL/SQL Code
  - **When Button Pressed:** `RECEIVE_BTN`
  - **PL/SQL Code:**
    ```sql
    UPDATE inventory_items
    SET qty_on_hand = qty_on_hand + :P2_RECEIVE_QTY
    WHERE item_id = :P2_ITEM_ID;

    INSERT INTO inventory_transactions
      (item_id, category_id, transaction_type, quantity, amount, transaction_date)
    SELECT :P2_ITEM_ID, category_id, 'RECEIPT', :P2_RECEIVE_QTY, :P2_RECEIVE_COST, SYSDATE
    FROM inventory_items WHERE item_id = :P2_ITEM_ID;
    ```
- **Save and Run** — open a low-stock item, enter a quantity, click the
  button, confirm the stock count and status update when you return to
  Page 1.

---

## 4. Page 3 — Dashboard (3 min)

- **Create Page → Blank Page** — Name: `Dashboard`
- Add 3–4 **Cards/Value** regions with SQL sources:
  ```sql
  SELECT SUM(extended_value) FROM v_inventory_status
  ```
  ```sql
  SELECT COUNT(*) FROM v_inventory_status WHERE status != 'In stock'
  ```
  ```sql
  SELECT SUM(budget_amount) FROM budget_categories
  ```
  ```sql
  SELECT SUM(spent) FROM v_budget_summary
  ```
- Add a **Classic Report** below sourced from `v_budget_summary` to show
  budget-by-category with `pct_used` — or a **Progress Bar** column
  formatting if your theme supports it.
- **App Builder → Edit App Properties → Home Link** → set to this page.

---

## You're done

Dashboard → Inventory → click a low-stock item → log a receipt → confirm
stock updates and the dashboard totals change. That's your working demo.

**Before the client call:** Theme Roller → set the accent color to match
the prospect's brand.
