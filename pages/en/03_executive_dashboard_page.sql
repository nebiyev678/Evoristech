-- =================================================================
-- PAGE 3: EXECUTIVE DASHBOARD  (read-only, no buttons)
-- Needs tables from: executive_dashboard_schema.sql
-- Also paste: 00_shared_styles.css (Inline CSS)
-- No JavaScript or Ajax process needed on this page
-- =================================================================


-- -----------------------------------------------------------------
-- [A] REGION SOURCE
-- Create Region > Type: Dynamic Content
-- Source > Language: PL/SQL > "PL/SQL Function Body returning a CLOB"
-- Appearance > Template: Blank with Attributes
-- -----------------------------------------------------------------
declare
  l_h        clob;
  l_revenue  number;
  l_open     number;
  l_pastdue  number;
  l_rate     number;
  l_max      number;
  procedure p(s varchar2) is begin l_h := l_h || s; end;
begin
  select nvl(sum(case when status <> 'CANCELLED' then amount end),0),
         sum(case when status = 'OPEN' then 1 else 0 end),
         sum(case when status = 'PAST_DUE' then 1 else 0 end),
         round(100 * sum(case when status = 'FULFILLED' then 1 else 0 end)
               / nullif(sum(case when status <> 'CANCELLED' then 1 else 0 end),0), 1)
    into l_revenue, l_open, l_pastdue, l_rate
    from orders;
  select nullif(max(total_revenue),0) into l_max from v_region_summary;

  p('<div class="dt">');

  -- KPI cards
  p('<div class="dt-kpis">');
  p('<div class="dt-kpi"><div class="dt-kpi-label">Revenue</div><div class="dt-kpi-value">'||to_char(l_revenue,'FM$999,999,990')||'</div></div>');
  p('<div class="dt-kpi"><div class="dt-kpi-label">Open orders</div><div class="dt-kpi-value">'||l_open||'</div></div>');
  p('<div class="dt-kpi"><div class="dt-kpi-label">Past due</div><div class="dt-kpi-value dt-red">'||l_pastdue||'</div></div>');
  p('<div class="dt-kpi"><div class="dt-kpi-label">Fulfillment rate</div><div class="dt-kpi-value dt-green">'||nvl(to_char(l_rate),'0')||'%</div></div>');
  p('</div>');

  p('<div class="dt-grid2">');

  -- Recent orders
  p('<div class="dt-card"><div class="dt-card-h"><h2>Recent orders</h2></div>');
  p('<div class="dt-scroll"><table class="dt-table"><thead><tr>');
  p('<th>Order #</th><th>Customer</th><th>Region</th><th>Amount</th><th>Status</th>');
  p('</tr></thead><tbody>');
  for r in (select * from v_orders_detail order by order_date desc fetch first 8 rows only) loop
    p('<tr>');
    p('<td><b>'||apex_escape.html(r.order_number)||'</b></td>');
    p('<td>'||apex_escape.html(r.customer_name)||'</td>');
    p('<td class="dt-muted">'||apex_escape.html(r.region_name)||'</td>');
    p('<td><b>'||to_char(r.amount,'FM$999,999,990')||'</b></td>');
    p('<td><span class="dt-badge '||
        case r.status when 'FULFILLED' then 'dt-b-ok'
                      when 'OPEN'      then 'dt-b-warn'
                      when 'PAST_DUE'  then 'dt-b-bad'
                      else 'dt-b-neutral' end||'">'||initcap(replace(r.status,'_',' '))||'</span></td>');
    p('</tr>');
  end loop;
  p('</tbody></table></div></div>');

  -- Revenue by region bars
  p('<div class="dt-card"><div class="dt-card-h"><h2>Revenue by region</h2></div><div class="dt-card-b">');
  for g in (select * from v_region_summary order by total_revenue desc) loop
    p('<div class="dt-bar"><div class="dt-bar-top"><span>'||apex_escape.html(g.region_name)||'</span>');
    p('<b>'||to_char(g.total_revenue,'FM$999,999,990')||'</b></div>');
    p('<div class="dt-track"><div class="dt-fill" style="width:'||
        nvl(round(100 * g.total_revenue / l_max),0)||'%"></div></div></div>');
  end loop;
  p('</div></div>');

  p('</div>');  -- grid
  p('</div>');
  return l_h;
end;
