# Page 4 "Receive Stock" — Build in Page Designer (App 102)

Your export shows Page 4 exists with just a Breadcrumb region — nothing
else yet. Here's everything to add, matching the design we planned.
Do this directly in **App Builder → App 102 → Page 4**, ~10 minutes.

---

## 1. Add a region for item details

- **Page Designer → right-click page tree → Create Region**
- Title: `Item Details`
- Type: `Static Content`

---

## 2. Add display items (read-only, inside that region)

Create each as a **Text Field** page item, set **Read Only = Yes**:

| Item name          | Label          | Source type | Source value                          |
|---------------------|----------------|-------------|----------------------------------------|
| `P4_ITEM_ID`        | (hidden)       | —           | set to `Hidden`, no label needed       |
| `P4_SKU`             | SKU            | SQL Query   | `select sku from inventory_items where item_id = :P4_ITEM_ID` |
| `P4_ITEM_NAME`       | Item           | SQL Query   | `select item_name from inventory_items where item_id = :P4_ITEM_ID` |
| `P4_CATEGORY`        | Category       | SQL Query   | `select c.category_name from inventory_items i join budget_categories c on c.category_id = i.category_id where i.item_id = :P4_ITEM_ID` |
| `P4_QTY_ON_HAND`     | Qty on hand    | SQL Query   | `select qty_on_hand from inventory_items where item_id = :P4_ITEM_ID` |
| `P4_REORDER_POINT`   | Reorder point  | SQL Query   | `select reorder_point from inventory_items where item_id = :P4_ITEM_ID` |
| `P4_UNIT_COST`       | Unit cost      | SQL Query   | `select unit_cost from inventory_items where item_id = :P4_ITEM_ID` |

Set each item's **Source → "Used" = "Always, replacing any existing value in session state"** so it refreshes each visit.

---

## 3. Add a second region: "Receive Stock"

- **Create Region** — Title: `Receive Stock`, Type: `Static Content`
- Add these **editable** items inside it:

| Item name         | Type        | Label              |
|--------------------|-------------|---------------------|
| `P4_RECEIVE_QTY`   | Number Field | Quantity received  |
| `P4_VENDOR`        | Text Field   | Vendor              |
| `P4_RECEIVE_COST`  | Number Field | Total cost          |

---

## 4. Add the button

- Inside the "Receive Stock" region: **Create Button**
- Button Name: `RECEIVE_BTN`
- Label: `Log Receipt & Update Stock`
- Action: `Submit Page`

---

## 5. Add the processing logic

- **Processing section (left panel) → Create Process**
- Name: `Update Stock & Log Receipt`
- Type: `PL/SQL Code`
- **Server-side Condition → When Button Pressed:** `RECEIVE_BTN`
- **PL/SQL Code:**
  ```sql
  UPDATE inventory_items
  SET qty_on_hand = qty_on_hand + :P4_RECEIVE_QTY
  WHERE item_id = :P4_ITEM_ID;

  INSERT INTO inventory_transactions
    (item_id, category_id, transaction_type, quantity, amount, vendor, transaction_date)
  SELECT :P4_ITEM_ID, category_id, 'RECEIPT', :P4_RECEIVE_QTY, :P4_RECEIVE_COST, :P4_VENDOR, SYSDATE
  FROM inventory_items WHERE item_id = :P4_ITEM_ID;
  ```
- Add a **Success Message**: `Stock updated.`
- Add a **Branch** after the process → back to Page 4 itself (so the
  refreshed quantity shows immediately), or to Page 1 (Inventory report).

---

## 6. Link into this page from the Inventory report (Page 1)

So Page 4 knows *which* item it's showing:

- On Page 1's Interactive Report, edit the column you want clickable
  (e.g. Item Name) → **Link → Target = Page in this Application**
- **Page:** 4
- **Set Items:** `P4_ITEM_ID` = `#ITEM_ID#` (the column from your report)

---

## Test it

Run the app → Inventory (Page 1) → click a low-stock item → Page 4
loads with that item's details → enter a quantity → click the button
→ stock updates → back on Page 1, the status badge should update from
Low/Out of stock accordingly.

That's the full "Receive Stock" logic, wired to your real schema.
