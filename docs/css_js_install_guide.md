# Installing custom.css / custom.js in APEX (5 min)

## 1. Upload the files

- **App Builder → your app → Shared Components → Static Application Files**
- **Upload File** → select `custom.css`
- **Upload File** again → select `custom.js`

## 2. Reference them app-wide

- **App Builder → your app → Edit Application Definition**
- **User Interface** tab
- Under **CSS → File URLs**, add:
  ```
  #APP_IMAGES#custom.css
  ```
- Under **JavaScript → File URLs**, add:
  ```
  #APP_IMAGES#custom.js
  ```
- **Apply Changes**

## 3. Add the Google Fonts (matches the mockup typography)

- **Shared Components → Edit Page 0 (Global Page)** (or any page's
  **Page Attributes → HTML Header**)
- Paste:
  ```html
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link href="https://fonts.googleapis.com/css2?family=Manrope:wght@500;700;800&family=IBM+Plex+Sans:wght@400;500;600&display=swap" rel="stylesheet">
  ```
  Putting this on Page 0 applies it to every page in the app.

## 4. Use the badge classes on your Interactive Report

On the `STATUS` column of your Inventory or Approvals report:

- **Column → Type:** keep as is, but set the column to render as
  **HTML Expression** (Column Attributes → "Escape special characters" = No)
- **HTML Expression:**
  ```html
  <span class="badge
    #STATUS# == 'Pending' ? 'badge-pending' :
    #STATUS# == 'Approved' ? 'badge-approved' :
    #STATUS# == 'Rejected' ? 'badge-rejected' :
    #STATUS# == 'In stock' ? 'badge-instock' :
    #STATUS# == 'Low stock' ? 'badge-lowstock' : 'badge-outstock'
  ">#STATUS#</span>
  ```
  (APEX substitution doesn't do ternaries directly — simplest robust
  way is a small `CASE` in your SQL that outputs the exact class name
  as a column, e.g. `status_class`, then use
  `<span class="badge #STATUS_CLASS#">#STATUS#</span>`.)

## 5. Use the KPI card classes on the Dashboard

On each "Value"/"Cards" region on Page 3 (Dashboard):

- **Region → Appearance → CSS Classes:** `kpi-card`
- Inside, wrap your label/value markup with `kpi-label` / `kpi-value`
  classes if you're using a Static Content region with custom HTML,
  or apply the classes via the Cards region's template options if
  using the native Cards type.

## 6. Wire up the optional JS behaviors

- **Confirm before Approve/Reject:** Page Designer → your button →
  **Advanced → Execute JavaScript Code** (or add a Dynamic Action on
  Click): `confirmAction('Approve this request?');`
- **Budget overage warning:** Dynamic Action on `P4_RECEIVE_COST`,
  Event = Change, Action = Execute JavaScript Code, calling
  `checkBudgetOverage(...)` as shown in the comments in `custom.js`.

---

Once installed, Theme Roller (Shared Components → Theme Roller) still
works for quick global color swaps per client — it layers on top of
this without conflicting, since these classes reference CSS variables
rather than hardcoded colors everywhere.
