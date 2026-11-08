-- =================================================================
-- PAGE 1: APPROVALS
-- Needs tables from: approval_workflow_schema.sql
-- Also paste: 00_shared_styles.css (Inline CSS)
--             00_shared_javascript.js (Function & Global Variable Declaration)
-- =================================================================


-- -----------------------------------------------------------------
-- [A] REGION SOURCE
-- Create Region > Type: Dynamic Content
-- Source > Language: PL/SQL > "PL/SQL Function Body returning a CLOB"
-- Appearance > Template: Blank with Attributes
-- Paste everything from DECLARE to the final END; below
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

  -- KPI cards
  p('<div class="dt-kpis">');
  p('<div class="dt-kpi"><div class="dt-kpi-label">Pending</div><div class="dt-kpi-value">'||l_pending||'</div></div>');
  p('<div class="dt-kpi"><div class="dt-kpi-label">Approved this week</div><div class="dt-kpi-value dt-green">'||l_approved||'</div></div>');
  p('<div class="dt-kpi"><div class="dt-kpi-label">Total pending value</div><div class="dt-kpi-value">'||to_char(l_value,'FM$999,999,990')||'</div></div>');
  p('<div class="dt-kpi"><div class="dt-kpi-label">Rejected</div><div class="dt-kpi-value dt-red">'||l_rejected||'</div></div>');
  p('</div>');

  -- Requests table
  p('<div class="dt-card"><div class="dt-card-h"><h2>Purchase order requests</h2></div>');
  p('<div class="dt-scroll"><table class="dt-table"><thead><tr>');
  p('<th>PO #</th><th>Requested by</th><th>Department</th><th>Description</th><th>Amount</th><th>Date</th><th>Status</th><th>Action</th>');
  p('</tr></thead><tbody>');

  for r in (select * from v_po_approvals order by created_date desc) loop
    p('<tr>');
    p('<td><b>'||apex_escape.html(r.po_number)||'</b></td>');
    p('<td>'||apex_escape.html(r.requester)||'</td>');
    p('<td class="dt-muted">'||apex_escape.html(r.department_name)||'</td>');
    p('<td class="dt-muted">'||apex_escape.html(r.description)||'</td>');
    p('<td><b>'||to_char(r.amount,'FM$999,999,990')||'</b></td>');
    p('<td class="dt-muted">'||to_char(r.created_date,'Mon DD')||'</td>');
    p('<td><span class="dt-badge '||
        case r.status when 'PENDING'  then 'dt-b-warn'
                      when 'APPROVED' then 'dt-b-ok'
                      else 'dt-b-bad' end||'">'||initcap(r.status)||'</span></td>');
    p('<td>');
    if r.status = 'PENDING' then
      p('<button type="button" class="dt-btn" onclick="dtAction(''PO_DECISION'','||r.po_id||',''APPROVED'',''Approve this request?'')">Approve</button>');
      p('<button type="button" class="dt-btn dt-btn-ghost" onclick="dtAction(''PO_DECISION'','||r.po_id||',''REJECTED'',''Reject this request?'')">Reject</button>');
    else
      p('<span class="dt-muted" style="font-size:12px">by '||apex_escape.html(r.decided_by)||'</span>');
    end if;
    p('</td></tr>');
  end loop;

  p('</tbody></table></div></div>');
  p('</div>');
  return l_h;
end;


-- -----------------------------------------------------------------
-- [B] AJAX CALLBACK PROCESS  (makes Approve / Reject work)
-- Page Designer > Processing tab (2nd tab on the left) >
-- right-click "Ajax Callback" > Create Process
--   Name: PO_DECISION      <-- must be exactly this
--   Type: Execute Code (PL/SQL)
-- Paste the block below
-- -----------------------------------------------------------------
begin
  if apex_application.g_x02 not in ('APPROVED','REJECTED') then
    raise_application_error(-20001, 'Invalid decision');
  end if;

  update purchase_orders
     set status       = apex_application.g_x02,
         decided_date = sysdate,
         decided_by   = :APP_USER
   where po_id  = to_number(apex_application.g_x01)
     and status = 'PENDING';

  htp.p('OK');
end;
