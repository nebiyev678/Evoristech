-- =================================================================
-- SƏHİFƏ 1: TƏSDİQLƏR  (Approvals)
-- Cədvəllər: approval_workflow_schema.sql
-- Həmçinin yapışdırın: 00_shared_styles.css (Inline CSS)
--                      00_shared_javascript.js (Function & Global Variable Declaration)
-- =================================================================


-- -----------------------------------------------------------------
-- [A] REGION SOURCE
-- Create Region > Type: Dynamic Content
-- Source > Language: PL/SQL > "PL/SQL Function Body returning a CLOB"
-- Appearance > Template: Blank with Attributes
-- -----------------------------------------------------------------
declare
  l_h        clob;
  l_pending  number;
  l_value    number;
  l_approved number;
  l_rejected number;
  procedure p(s varchar2) is begin l_h := l_h || s; end;
begin
  select count(*), nvl(sum(amount),0) into l_pending, l_value
    from purchase_orders where status = 'PENDING';
  select count(*) into l_approved
    from purchase_orders
   where status = 'APPROVED' and decided_date >= trunc(sysdate,'IW');
  select count(*) into l_rejected
    from purchase_orders where status = 'REJECTED';

  p('<div class="dt">');

  -- Göstərici kartları
  p('<div class="dt-kpis">');
  p('<div class="dt-kpi"><div class="dt-kpi-label">Gözləyir</div><div class="dt-kpi-value">'||l_pending||'</div></div>');
  p('<div class="dt-kpi"><div class="dt-kpi-label">Bu həftə təsdiqlənib</div><div class="dt-kpi-value dt-green">'||l_approved||'</div></div>');
  p('<div class="dt-kpi"><div class="dt-kpi-label">Gözləyən ümumi məbləğ</div><div class="dt-kpi-value">'||to_char(l_value,'FM999G999G990')||' ₼</div></div>');
  p('<div class="dt-kpi"><div class="dt-kpi-label">Rədd edilib</div><div class="dt-kpi-value dt-red">'||l_rejected||'</div></div>');
  p('</div>');

  -- Sorğular cədvəli
  p('<div class="dt-card"><div class="dt-card-h"><h2>Satınalma sorğuları</h2></div>');
  p('<div class="dt-scroll"><table class="dt-table"><thead><tr>');
  p('<th>Sorğu №</th><th>Sorğu edən</th><th>Şöbə</th><th>Təsvir</th><th>Məbləğ</th><th>Tarix</th><th>Status</th><th>Əməliyyat</th>');
  p('</tr></thead><tbody>');

  for r in (select * from v_po_approvals order by created_date desc) loop
    p('<tr>');
    p('<td><b>'||apex_escape.html(r.po_number)||'</b></td>');
    p('<td>'||apex_escape.html(r.requester)||'</td>');
    p('<td class="dt-muted">'||apex_escape.html(r.department_name)||'</td>');
    p('<td class="dt-muted">'||apex_escape.html(r.description)||'</td>');
    p('<td><b>'||to_char(r.amount,'FM999G999G990')||' ₼</b></td>');
    p('<td class="dt-muted">'||to_char(r.created_date,'DD.MM.YYYY')||'</td>');
    p('<td><span class="dt-badge '||
        case r.status when 'PENDING'  then 'dt-b-warn'
                      when 'APPROVED' then 'dt-b-ok'
                      else 'dt-b-bad' end||'">'||
        case r.status when 'PENDING'  then 'Gözləyir'
                      when 'APPROVED' then 'Təsdiqlənib'
                      else 'Rədd edilib' end||'</span></td>');
    p('<td>');
    if r.status = 'PENDING' then
      p('<button type="button" class="dt-btn" onclick="dtAction(''PO_DECISION'','||r.po_id||',''APPROVED'',''Bu sorğunu təsdiqləyirsiniz?'')">Təsdiqlə</button>');
      p('<button type="button" class="dt-btn dt-btn-ghost" onclick="dtAction(''PO_DECISION'','||r.po_id||',''REJECTED'',''Bu sorğunu rədd edirsiniz?'')">Rədd et</button>');
    else
      p('<span class="dt-muted" style="font-size:12px">'||apex_escape.html(r.decided_by)||'</span>');
    end if;
    p('</td></tr>');
  end loop;

  p('</tbody></table></div></div>');
  p('</div>');
  return l_h;
end;


-- -----------------------------------------------------------------
-- [B] AJAX CALLBACK PROCESS
-- Processing tab > "Ajax Callback" üzərində sağ klik > Create Process
--   Name: PO_DECISION      <-- dəqiq bu ad olmalıdır
--   Type: Execute Code (PL/SQL)
-- -----------------------------------------------------------------
begin
  if apex_application.g_x02 not in ('APPROVED','REJECTED') then
    raise_application_error(-20001, 'Yanlış qərar');
  end if;

  update purchase_orders
     set status       = apex_application.g_x02,
         decided_date = sysdate,
         decided_by   = :APP_USER
   where po_id  = to_number(apex_application.g_x01)
     and status = 'PENDING';

  htp.p('OK');
end;
