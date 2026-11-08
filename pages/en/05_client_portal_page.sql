-- =================================================================
-- PAGE 5: CLIENT PORTAL  (read-only, customer view)
-- Needs tables from: client_portal_schema.sql
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
  l_company  varchar2(150);
  l_transit  number;
  l_open_amt number;
  l_open_cnt number;
  l_stage    number;
  procedure p(s varchar2) is begin l_h := l_h || s; end;

  procedure step(p_label varchar2, p_on boolean, p_first boolean) is
  begin
    if not p_first then
      p('<div class="dt-line'||case when p_on then ' on' end||'"></div>');
    end if;
    p('<div class="dt-step'||case when p_on then ' on' end||'"><div class="dt-dot"></div>'||p_label||'</div>');
  end;
begin
  select max(company_name) into l_company from clients;
  select count(*) into l_transit from client_orders where status = 'IN_TRANSIT';
  select nvl(sum(amount),0), count(*) into l_open_amt, l_open_cnt
    from client_invoices where status = 'OPEN';

  p('<div class="dt">');
  p('<p class="dt-muted" style="margin:0 0 16px">Welcome back, <b style="color:#1A1A18">'||
      apex_escape.html(l_company)||'</b></p>');

  -- KPI cards
  p('<div class="dt-kpis">');
  p('<div class="dt-kpi"><div class="dt-kpi-label">Orders in transit</div><div class="dt-kpi-value">'||l_transit||'</div></div>');
  p('<div class="dt-kpi"><div class="dt-kpi-label">Open invoices</div><div class="dt-kpi-value">'||to_char(l_open_amt,'FM$999,999,990')||'</div>');
  p('<div class="dt-kpi-sub">'||l_open_cnt||' invoice(s)</div></div>');
  p('</div>');

  -- Order tracking
  p('<div class="dt-card"><div class="dt-card-h"><h2>Order tracking</h2></div><div class="dt-scroll">');
  for o in (select * from v_client_orders order by placed_date desc) loop
    l_stage := case o.status when 'PLACED' then 1 when 'PACKED' then 2
                             when 'IN_TRANSIT' then 3 else 4 end;
    p('<div class="dt-track-row">');
    p('<div class="dt-track-id"><b>'||apex_escape.html(o.order_number)||'</b><br>');
    p('<span class="dt-muted" style="font-size:12px">Placed '||to_char(o.placed_date,'Mon DD')||'</span></div>');
    p('<div class="dt-steps">');
    step('Placed',     l_stage >= 1, true);
    step('Packed',     l_stage >= 2, false);
    step('In transit', l_stage >= 3, false);
    step('Delivered',  l_stage >= 4, false);
    p('</div>');
    p('<div class="dt-eta">'||
        case when o.status = 'DELIVERED'
             then '<span class="dt-green"><b>Delivered '||to_char(o.delivered_date,'Mon DD')||'</b></span>'
             else 'ETA '||nvl(to_char(o.eta_date,'Mon DD'),'TBD') end||'</div>');
    p('</div>');
  end loop;
  p('</div></div>');

  -- Invoices
  p('<div class="dt-card"><div class="dt-card-h"><h2>Invoices</h2></div>');
  p('<div class="dt-scroll"><table class="dt-table"><thead><tr>');
  p('<th>Invoice #</th><th>Amount</th><th>Due date</th><th>Status</th>');
  p('</tr></thead><tbody>');
  for i in (select * from v_client_invoices order by due_date desc) loop
    p('<tr>');
    p('<td><b>'||apex_escape.html(i.invoice_number)||'</b></td>');
    p('<td><b>'||to_char(i.amount,'FM$999,999,990')||'</b></td>');
    p('<td class="dt-muted">'||to_char(i.due_date,'Mon DD, YYYY')||'</td>');
    p('<td><span class="dt-badge '||
        case when i.status = 'PAID' then 'dt-b-ok'
             when i.due_date < trunc(sysdate) then 'dt-b-bad'
             else 'dt-b-warn' end||'">'||
        case when i.status = 'PAID' then 'Paid'
             when i.due_date < trunc(sysdate) then 'Overdue'
             else 'Open' end||'</span></td>');
    p('</tr>');
  end loop;
  p('</tbody></table></div></div>');

  p('</div>');
  return l_h;
end;
