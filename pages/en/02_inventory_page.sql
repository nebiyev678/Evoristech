-- =================================================================
-- PAGE 2: INVENTORY (with budget tracking)
-- Needs tables from: inventory_budget_schema.sql
-- Also paste: 00_shared_styles.css (Inline CSS)
--             00_shared_javascript.js (Function & Global Variable Declaration)
-- =================================================================


-- -----------------------------------------------------------------
-- [A] REGION SOURCE
-- Create Region > Type: Dynamic Content
-- Source > Language: PL/SQL > "PL/SQL Function Body returning a CLOB"
-- Appearance > Template: Blank with Attributes
-- -----------------------------------------------------------------
declare
  l_h      clob;
  l_value  number;
  l_low    number;
  l_budget number;
  l_spent  number;
  l_pct    number;
  procedure p(s varchar2) is begin l_h := l_h || s; end;
begin
  select nvl(sum(extended_value),0),
         sum(case when status <> 'In stock' then 1 else 0 end)
    into l_value, l_low
    from v_inventory_status;
  select nvl(sum(budget_amount),0), nvl(sum(spent),0)
    into l_budget, l_spent
    from v_budget_summary;

  p('<div class="dt">');

  -- KPI cards
  p('<div class="dt-kpis">');
  p('<div class="dt-kpi"><div class="dt-kpi-label">Inventory value</div><div class="dt-kpi-value">'||to_char(l_value,'FM$999,999,990')||'</div></div>');
  p('<div class="dt-kpi"><div class="dt-kpi-label">Low / out of stock</div><div class="dt-kpi-value dt-red">'||l_low||'</div></div>');
  p('<div class="dt-kpi"><div class="dt-kpi-label">Quarter budget</div><div class="dt-kpi-value">'||to_char(l_budget,'FM$999,999,990')||'</div></div>');
  p('<div class="dt-kpi"><div class="dt-kpi-label">Spent to date</div><div class="dt-kpi-value dt-green">'||to_char(l_spent,'FM$999,999,990')||'</div></div>');
  p('</div>');

  -- Inventory table
  p('<div class="dt-card"><div class="dt-card-h"><h2>Inventory</h2></div>');
  p('<div class="dt-scroll"><table class="dt-table"><thead><tr>');
  p('<th>SKU</th><th>Item</th><th>Category</th><th>Bin</th><th>On hand</th><th>Unit cost</th><th>Reorder at</th><th>Status</th><th>Action</th>');
  p('</tr></thead><tbody>');

  for r in (select * from v_inventory_status order by
              case status when 'Out of stock' then 1 when 'Low stock' then 2 else 3 end, sku) loop
    p('<tr'||case when r.status <> 'In stock' then ' class="dt-alert"' end||'>');
    p('<td class="dt-muted">'||apex_escape.html(r.sku)||'</td>');
    p('<td><b>'||apex_escape.html(r.item_name)||'</b></td>');
    p('<td class="dt-muted">'||apex_escape.html(r.category_name)||'</td>');
    p('<td class="dt-muted">'||apex_escape.html(r.bin_location)||'</td>');
    p('<td><b>'||r.qty_on_hand||'</b></td>');
    p('<td class="dt-muted">'||to_char(r.unit_cost,'FM$999,990.00')||'</td>');
    p('<td class="dt-muted">'||r.reorder_point||'</td>');
    p('<td><span class="dt-badge '||
        case r.status when 'In stock'  then 'dt-b-ok'
                      when 'Low stock' then 'dt-b-bad'
                      else 'dt-b-neutral' end||'">'||apex_escape.html(r.status)||'</span></td>');
    p('<td><button type="button" class="dt-btn" onclick="dtReceive('||r.item_id||')">Receive</button></td>');
    p('</tr>');
  end loop;
  p('</tbody></table></div></div>');

  -- Budget by category
  p('<div class="dt-card"><div class="dt-card-h"><h2>Budget by category</h2></div><div class="dt-card-b">');
  for b in (select * from v_budget_summary order by category_name) loop
    l_pct := least(nvl(b.pct_used,0), 100);
    p('<div class="dt-bar"><div class="dt-bar-top"><span>'||apex_escape.html(b.category_name)||'</span>');
    p('<b>'||to_char(b.spent,'FM$999,999,990')||' / '||to_char(b.budget_amount,'FM$999,999,990')||'</b></div>');
    p('<div class="dt-track"><div class="dt-fill'||
        case when b.pct_used >= 100 then ' over' when b.pct_used >= 85 then ' warn' end||
        '" style="width:'||l_pct||'%"></div></div></div>');
  end loop;
  p('</div></div>');

  p('</div>');
  return l_h;
end;


-- -----------------------------------------------------------------
-- [B] AJAX CALLBACK PROCESS  (makes the Receive button work)
-- Processing tab > right-click "Ajax Callback" > Create Process
--   Name: RECEIVE_STOCK     <-- must be exactly this
--   Type: Execute Code (PL/SQL)
-- Updates stock AND logs the spend against the category budget
-- -----------------------------------------------------------------
declare
  l_id  number := to_number(apex_application.g_x01);
  l_qty number := to_number(apex_application.g_x02);
begin
  if l_qty is null or l_qty <= 0 then
    raise_application_error(-20001, 'Invalid quantity');
  end if;

  update inventory_items
     set qty_on_hand = qty_on_hand + l_qty
   where item_id = l_id;

  insert into inventory_transactions
    (item_id, category_id, transaction_type, quantity, amount, transaction_date)
  select item_id, category_id, 'RECEIPT', l_qty, round(l_qty * unit_cost, 2), sysdate
    from inventory_items
   where item_id = l_id;

  htp.p('OK');
end;
