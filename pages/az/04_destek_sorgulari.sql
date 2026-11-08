-- =================================================================
-- SƏHİFƏ 4: DƏSTƏK SORĞULARI  (Helpdesk kanban)
-- Cədvəllər: helpdesk_ticketing_schema.sql
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
  l_h clob;
  procedure p(s varchar2) is begin l_h := l_h || s; end;

  procedure render_column(p_status varchar2, p_label varchar2,
                          p_btn_label varchar2, p_next varchar2) is
    l_cnt number;
  begin
    select count(*) into l_cnt from tickets where status = p_status;
    p('<div>');
    p('<div class="dt-col-h"><span>'||p_label||'</span><span class="dt-count">'||l_cnt||'</span></div>');
    for t in (select * from v_tickets where status = p_status
               order by case priority when 'URGENT' then 1 when 'MEDIUM' then 2 else 3 end,
                        created_date) loop
      p('<div class="dt-ticket '||
          case when p_status = 'RESOLVED' then 'done'
               else 'p-'||lower(t.priority) end||'">');
      p('<div class="dt-ticket-id">№'||t.ticket_id||' &middot; '||to_char(t.created_date,'DD.MM.YYYY')||'</div>');
      p('<div class="dt-ticket-t">'||apex_escape.html(t.subject)||'</div>');
      p('<div class="dt-ticket-f"><span class="dt-badge '||
          case t.priority when 'URGENT' then 'dt-b-bad'
                          when 'MEDIUM' then 'dt-b-warn'
                          else 'dt-b-neutral' end||'">'||
          case t.priority when 'URGENT' then 'Təcili'
                          when 'MEDIUM' then 'Orta'
                          else 'Aşağı' end||'</span>');
      p('<span>'||apex_escape.html(nvl(t.agent_name, t.requester_name))||'</span></div>');
      if p_next is not null then
        p('<button type="button" class="dt-btn" onclick="dtAction(''TICKET_STATUS'','||t.ticket_id||','''||p_next||''')">'||p_btn_label||'</button>');
      end if;
      p('</div>');
    end loop;
    p('</div>');
  end;
begin
  p('<div class="dt"><div class="dt-kanban">');
  render_column('NEW',         'Yeni',                   'İcraya başla',  'IN_PROGRESS');
  render_column('IN_PROGRESS', 'İcradadır',              'Həll edildi',   'RESOLVED');
  render_column('WAITING',     'Sorğu edəni gözləyir',   'Davam et',      'IN_PROGRESS');
  render_column('RESOLVED',    'Həll edilib',            null,            null);
  p('</div></div>');
  return l_h;
end;


-- -----------------------------------------------------------------
-- [B] AJAX CALLBACK PROCESS
--   Name: TICKET_STATUS     <-- dəqiq bu ad olmalıdır
--   Type: Execute Code (PL/SQL)
-- -----------------------------------------------------------------
begin
  if apex_application.g_x02 not in ('NEW','IN_PROGRESS','WAITING','RESOLVED') then
    raise_application_error(-20001, 'Yanlış status');
  end if;

  update tickets
     set status        = apex_application.g_x02,
         resolved_date = case when apex_application.g_x02 = 'RESOLVED' then sysdate end,
         agent_id      = nvl(agent_id, (select min(agent_id) from agents))
   where ticket_id = to_number(apex_application.g_x01);

  htp.p('OK');
end;
