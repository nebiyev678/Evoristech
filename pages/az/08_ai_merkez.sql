-- =================================================================
-- VAHİD AI MƏRKƏZİ
-- Əmrlər (tap, siyahı, statusu dəyiş) + Təhlil (hesablamalar)
-- bir sətirdə birləşdirilib.
--
-- 06 və 07 fayllarını əvəz edir. Hər ikisini ayrı saxlamaq
-- istəmirsinizsə, bu faylı istifadə edin.
--
-- TƏLƏBLƏR: helpdesk_ticketing_schema.sql
--           inventory_budget_schema.sql
--           executive_dashboard_schema.sql
--           Generative AI servis, Static ID: MAIN_AI
-- =================================================================


-- -----------------------------------------------------------------
-- [A] REGION SOURCE
-- Create Region > Type: Dynamic Content
-- Source: PL/SQL Function Body returning a CLOB
-- Appearance > Template: Blank with Attributes
-- -----------------------------------------------------------------
declare
  l_h clob;
begin
  l_h := '<div class="dt"><div class="ai-bar">'||
         '<div class="ai-bar-row">'||
         '<svg class="ai-bar-icon" viewBox="0 0 24 24" fill="none" '||
         'stroke="currentColor" stroke-width="2" stroke-linecap="round">'||
         '<circle cx="11" cy="11" r="7"/><path d="M20 20l-4.5-4.5"/></svg>'||
         '<input type="text" id="aiCmd" class="ai-bar-input" '||
         'placeholder="Sual verin və ya əmr yazın..." '||
         'onkeydown="if(event.key===''Enter'')dtAi()">'||
         '<button type="button" class="ai-bar-btn" onclick="dtAi()">Göndər</button>'||
         '</div>'||
         '<div class="ai-bar-hints">'||
         '<span class="ai-chip" onclick="dtAiSet(''təcili sorğuları göstər'')">təcili sorğular</span>'||
         '<span class="ai-chip" onclick="dtAiSet(''4821 nömrəli sorğunu tap'')">nömrə ilə tap</span>'||
         '<span class="ai-chip" onclick="dtAiSet(''stoku az olan məhsullar'')">az stok</span>'||
         '<span class="ai-chip" onclick="dtAiSet(''region üzrə cəmi gəlir'')">region üzrə gəlir</span>'||
         '<span class="ai-chip" onclick="dtAiSet(''status üzrə orta məbləğ'')">orta məbləğ</span>'||
         '<span class="ai-chip" onclick="dtAiSet(''həftəlik xülasə'')">həftəlik xülasə</span>'||
         '</div>'||
         '<div id="aiOut" class="ai-bar-out"></div>'||
         '</div></div>';
  return l_h;
end;


-- -----------------------------------------------------------------
-- [B] AJAX CALLBACK PROCESS
--   Name: AI_ASSISTANT     <-- dəqiq bu ad
--   Type: Execute Code (PL/SQL)
-- -----------------------------------------------------------------
declare
  l_input   varchar2(4000) := apex_application.g_x01;
  l_json    clob;
  l_action  varchar2(30);
  l_id      number;
  l_status  varchar2(30);
  l_prio    varchar2(20);
  l_metric  varchar2(20);
  l_dim     varchar2(20);
  l_ostat   varchar2(20);
  l_days    number;
  l_out     clob := '';
  l_rows    clob := '';
  l_data    clob := '';
  l_total   number := 0;
  l_cnt     number := 0;
  l_label   varchar2(100);
  l_dimname varchar2(100);

  procedure p(s varchar2) is begin l_out := l_out || s; end;

  procedure row_ticket(t v_tickets%rowtype) is
  begin
    p('<tr><td><b>№'||t.ticket_id||'</b></td>');
    p('<td>'||apex_escape.html(t.subject)||'</td>');
    p('<td>'||case t.priority when 'URGENT' then 'Təcili'
                              when 'MEDIUM' then 'Orta'
                              else 'Aşağı' end||'</td>');
    p('<td>'||case t.status when 'NEW' then 'Yeni'
                            when 'IN_PROGRESS' then 'İcradadır'
                            when 'WAITING' then 'Gözləyir'
                            else 'Həll edilib' end||'</td></tr>');
  end;
begin
  ------------------------------------------------------------------
  -- 1. Model niyyəti müəyyən edir (heç bir hesablama aparmır)
  ------------------------------------------------------------------
  l_json := apex_ai.generate_text(
    p_system_prompt =>
      'İstifadəçinin sorğusunu JSON-a çevir. YALNIZ JSON qaytar, '||
      'izahat və markdown yazma. Struktur: '||
      '{"action":"...","ticket_id":null,"status":null,"priority":null,'||
      '"metric":null,"dimension":null,"order_status":null,"days":null}. '||
      'İcazəli action dəyərləri: '||
      'FIND_TICKET (sorğunu nömrə ilə tap), '||
      'LIST_TICKETS (prioritet və ya statusa görə siyahı), '||
      'MOVE_TICKET (sorğunun statusunu dəyiş), '||
      'LOW_STOCK (stoku az məhsullar), '||
      'ANALYZE (sifariş məbləğləri üzrə hesablama), '||
      'SUMMARY (mətnlə xülasə), '||
      'UNKNOWN (anlaşılmadı). '||
      'status: NEW, IN_PROGRESS, WAITING, RESOLVED. '||
      'priority: URGENT, MEDIUM, LOW. '||
      'ANALYZE üçün: metric = SUM, AVG, COUNT, MAX, MIN; '||
      'dimension = REGION, STATUS, MONTH, NONE; '||
      'order_status = OPEN, FULFILLED, PAST_DUE, CANCELLED; '||
      'days = son neçə gün (qeyd olunmayıbsa null).',
    p_prompt            => l_input,
    p_service_static_id => 'MAIN_AI');

  l_json := regexp_replace(l_json, '```(json)?', '');

  l_action := upper(json_value(l_json, '$.action'));
  l_id     := json_value(l_json, '$.ticket_id' returning number);
  l_status := upper(json_value(l_json, '$.status'));
  l_prio   := upper(json_value(l_json, '$.priority'));
  l_metric := upper(json_value(l_json, '$.metric'));
  l_dim    := upper(json_value(l_json, '$.dimension'));
  l_ostat  := upper(json_value(l_json, '$.order_status'));
  l_days   := json_value(l_json, '$.days' returning number);

  ------------------------------------------------------------------
  -- 2. Yalnız icazəli əməliyyatlar
  ------------------------------------------------------------------
  if l_action = 'FIND_TICKET' and l_id is not null then
    p('<table class="dt-table"><thead><tr><th>№</th><th>Mövzu</th>'||
      '<th>Prioritet</th><th>Status</th></tr></thead><tbody>');
    for t in (select * from v_tickets where ticket_id = l_id) loop
      row_ticket(t); l_cnt := l_cnt + 1;
    end loop;
    p('</tbody></table>');
    if l_cnt = 0 then
      l_out := '<p>№'||l_id||' nömrəli sorğu tapılmadı.</p>';
    end if;

  elsif l_action = 'LIST_TICKETS' then
    p('<table class="dt-table"><thead><tr><th>№</th><th>Mövzu</th>'||
      '<th>Prioritet</th><th>Status</th></tr></thead><tbody>');
    for t in (select * from v_tickets
               where (l_prio   is null or priority = l_prio)
                 and (l_status is null or status   = l_status)
               order by created_date desc
               fetch first 20 rows only) loop
      row_ticket(t); l_cnt := l_cnt + 1;
    end loop;
    p('</tbody></table><p class="dt-muted">'||l_cnt||' sorğu tapıldı.</p>');

  elsif l_action = 'MOVE_TICKET' and l_id is not null
        and l_status in ('NEW','IN_PROGRESS','WAITING','RESOLVED') then
    update tickets
       set status        = l_status,
           resolved_date = case when l_status = 'RESOLVED' then sysdate end
     where ticket_id = l_id;
    if sql%rowcount = 0 then
      p('<p>№'||l_id||' nömrəli sorğu tapılmadı.</p>');
    else
      p('<p style="color:#1A7F5A"><b>№'||l_id||' sorğusunun statusu dəyişdirildi: '||
        case l_status when 'NEW' then 'Yeni'
                      when 'IN_PROGRESS' then 'İcradadır'
                      when 'WAITING' then 'Gözləyir'
                      else 'Həll edilib' end||'</b></p>');
    end if;

  elsif l_action = 'LOW_STOCK' then
    p('<table class="dt-table"><thead><tr><th>Kod</th><th>Məhsul</th>'||
      '<th>Mövcud</th><th>Status</th></tr></thead><tbody>');
    for i in (select * from v_inventory_status
               where status <> 'In stock' order by qty_on_hand) loop
      p('<tr><td>'||apex_escape.html(i.sku)||'</td>');
      p('<td>'||apex_escape.html(i.item_name)||'</td>');
      p('<td><b>'||i.qty_on_hand||'</b></td>');
      p('<td>'||case i.status when 'Low stock' then 'Stok azdır'
                              else 'Stokda yoxdur' end||'</td></tr>');
      l_cnt := l_cnt + 1;
    end loop;
    p('</tbody></table><p class="dt-muted">'||l_cnt||' məhsul.</p>');

  ------------------------------------------------------------------
  -- HESABLAMA: bütün riyaziyyat SQL-də, model rəqəmə toxunmur
  ------------------------------------------------------------------
  elsif l_action = 'ANALYZE' then
    if l_metric not in ('SUM','AVG','COUNT','MAX','MIN') then l_metric := 'SUM'; end if;
    if l_dim    not in ('REGION','STATUS','MONTH','NONE')  then l_dim    := 'NONE'; end if;
    if l_ostat is not null
       and l_ostat not in ('OPEN','FULFILLED','PAST_DUE','CANCELLED') then
      l_ostat := null;
    end if;
    if l_days is not null and (l_days <= 0 or l_days > 3650) then l_days := null; end if;

    l_label := case l_metric when 'SUM' then 'Cəmi məbləğ'
                             when 'AVG' then 'Orta məbləğ'
                             when 'COUNT' then 'Sifariş sayı'
                             when 'MAX' then 'Ən böyük məbləğ'
                             else 'Ən kiçik məbləğ' end;
    l_dimname := case l_dim when 'REGION' then 'Region'
                            when 'STATUS' then 'Status'
                            when 'MONTH' then 'Ay'
                            else 'Ümumi' end;

    for r in (
      select grp,
             case l_metric when 'SUM' then sum_amt
                           when 'AVG' then avg_amt
                           when 'COUNT' then cnt
                           when 'MAX' then max_amt
                           else min_amt end as val
        from (
          select case l_dim when 'REGION' then region_name
                            when 'STATUS' then status
                            when 'MONTH'  then to_char(order_date,'YYYY-MM')
                            else 'Ümumi' end     as grp,
                 nvl(sum(amount),0) as sum_amt,
                 round(avg(amount),2) as avg_amt,
                 count(*) as cnt,
                 max(amount) as max_amt,
                 min(amount) as min_amt
            from v_orders_detail
           where (l_ostat is null or status = l_ostat)
             and (l_days  is null or order_date >= trunc(sysdate) - l_days)
           group by case l_dim when 'REGION' then region_name
                               when 'STATUS' then status
                               when 'MONTH'  then to_char(order_date,'YYYY-MM')
                               else 'Ümumi' end
        )
       order by val desc
    ) loop
      l_rows := l_rows||'<tr><td><b>'||apex_escape.html(r.grp)||'</b></td>'||
        '<td style="text-align:right"><b>'||
        case when l_metric = 'COUNT' then to_char(r.val,'FM999G999G990')
             else to_char(r.val,'FM999G999G990D00')||' ₼' end||
        '</b></td></tr>';
      l_total := l_total + nvl(r.val,0);
      l_cnt := l_cnt + 1;
    end loop;

    if l_cnt = 0 then
      p('<p>Bu şərtlərə uyğun sifariş tapılmadı.</p>');
    else
      p('<p style="font-size:13px;color:#6B6A64;margin-bottom:10px">'||
        l_label||' &middot; '||l_dimname||' üzrə'||
        case when l_ostat is not null then ' &middot; filtr: '||l_ostat end||
        case when l_days  is not null then ' &middot; son '||l_days||' gün' end||'</p>');
      p('<table class="dt-table"><thead><tr><th>'||l_dimname||'</th>'||
        '<th style="text-align:right">'||l_label||'</th></tr></thead><tbody>');
      p(l_rows);
      if l_cnt > 1 and l_metric in ('SUM','COUNT') then
        p('<tr style="background:#F7F6F2"><td><b>Cəmi</b></td>'||
          '<td style="text-align:right"><b>'||
          case when l_metric = 'COUNT' then to_char(l_total,'FM999G999G990')
               else to_char(l_total,'FM999G999G990D00')||' ₼' end||'</b></td></tr>');
      end if;
      p('</tbody></table>');
      p('<p style="font-size:11px;color:#9C9A91;margin-top:8px">'||
        'Rəqəmlər verilənlər bazasından hesablanıb.</p>');
    end if;

  elsif l_action = 'SUMMARY' then
    for t in (select ticket_id, subject, priority, status from v_tickets) loop
      l_data := l_data||t.ticket_id||'|'||t.subject||'|'||t.priority||'|'||t.status||chr(10);
    end loop;
    p('<p>'||apex_escape.html(
        apex_ai.generate_text(
          p_system_prompt => 'Azərbaycan dilində qısa xülasə yaz. Maksimum 5 cümlə.',
          p_prompt        => 'Bu dəstək sorğularını təhlil et:'||chr(10)||l_data,
          p_service_static_id => 'MAIN_AI'))||'</p>');

  else
    p('<p>Sorğunu başa düşmədim. Nümunə: «4821 nömrəli sorğunu tap», '||
      '«region üzrə cəmi gəlir» və ya «həftəlik xülasə».</p>');
  end if;

  htp.p(l_out);
exception
  when others then
    htp.p('<p style="color:#B3261E">Xəta: '||apex_escape.html(sqlerrm)||'</p>');
end;


-- -----------------------------------------------------------------
-- [C] JAVASCRIPT
-- -----------------------------------------------------------------
/*
function dtAi() {
  var txt = document.getElementById('aiCmd').value;
  if (!txt) return;
  var out = document.getElementById('aiOut');
  out.innerHTML = '<p style="color:#6B6A64">Düşünürəm...</p>';
  apex.server.process('AI_ASSISTANT', { x01: txt }, { dataType: 'text' })
    .done(function (data) { out.innerHTML = data; })
    .fail(function (j, t, e) {
      out.innerHTML = '<p style="color:#B3261E">Xəta: ' + (e || t) + '</p>';
    });
}

function dtAiSet(txt) {
  var el = document.getElementById('aiCmd');
  el.value = txt;
  el.focus();
  dtAi();
}
*/
