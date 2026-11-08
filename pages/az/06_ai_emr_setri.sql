-- =================================================================
-- AI ƏMR SƏTRİ  (AI Command Bar)
-- Dəstək sorğuları və anbar üçün təbii dildə idarəetmə
--
-- TƏLƏBLƏR:
--   1. Workspace Utilities > Generative AI > servis yaradın,
--      Static ID: MAIN_AI
--   2. helpdesk_ticketing_schema.sql və inventory_budget_schema.sql
--   3. 00_shared_styles.css səhifədə Inline CSS kimi
--
-- TƏHLÜKƏSİZLİK PRİNSİPİ:
--   Model YALNIZ niyyəti JSON kimi qaytarır. SQL yazmır, icra etmir.
--   Hansı əməliyyatın mümkün olduğunu aşağıdakı PL/SQL qərar verir.
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
  l_h := '<div class="dt">'||
         '<div class="dt-card"><div class="dt-card-b">'||
         '<div style="display:flex;gap:10px;align-items:center">'||
         '<input type="text" id="aiCmd" class="dt-ai-input" '||
         'placeholder="Məsələn: 4823 nömrəli sorğunu tap" '||
         'onkeydown="if(event.key===''Enter'')dtAi()">'||
         '<button type="button" class="dt-btn" onclick="dtAi()">Göndər</button>'||
         '</div>'||
         '<div style="margin-top:10px;font-size:12px;color:#6B6A64">'||
         'Nümunələr: «təcili sorğuları göstər» &middot; '||
         '«4821 nömrəli sorğunu icraya başlat» &middot; '||
         '«stoku az olan məhsullar» &middot; «həftəlik xülasə»'||
         '</div>'||
         '<div id="aiOut" style="margin-top:16px"></div>'||
         '</div></div></div>';
  return l_h;
end;


-- -----------------------------------------------------------------
-- [B] AJAX CALLBACK PROCESS
--   Name: AI_COMMAND        <-- dəqiq bu ad
--   Type: Execute Code (PL/SQL)
-- -----------------------------------------------------------------
declare
  l_input    varchar2(4000) := apex_application.g_x01;
  l_json     clob;
  l_action   varchar2(50);
  l_id       number;
  l_status   varchar2(30);
  l_priority varchar2(20);
  l_out      clob := '';
  l_cnt      number := 0;
  l_data     clob := '';

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
  -- 1. Model yalnız niyyəti JSON kimi qaytarır
  ------------------------------------------------------------------
  l_json := apex_ai.generate_text(
    p_system_prompt =>
      'İstifadəçinin sorğusunu JSON-a çevir. YALNIZ JSON qaytar, '||
      'izahat və markdown yazma. Struktur: '||
      '{"action":"...","ticket_id":null,"status":null,"priority":null,"sku":null,"qty":null}. '||
      'İcazəli action dəyərləri: FIND_TICKET (nömrə ilə tap), '||
      'LIST_TICKETS (prioritet və ya statusa görə siyahı), '||
      'MOVE_TICKET (statusu dəyiş), LOW_STOCK (stoku az məhsullar), '||
      'SUMMARY (xülasə), UNKNOWN (anlaşılmadı). '||
      'status dəyərləri: NEW, IN_PROGRESS, WAITING, RESOLVED. '||
      'priority dəyərləri: URGENT, MEDIUM, LOW.',
    p_prompt            => l_input,
    p_service_static_id => 'MAIN_AI');

  -- Modelin bəzən əlavə etdiyi ``` işarələrini təmizlə
  l_json := regexp_replace(l_json, '```(json)?', '');

  l_action   := upper(json_value(l_json, '$.action'));
  l_id       := json_value(l_json, '$.ticket_id' returning number);
  l_status   := upper(json_value(l_json, '$.status'));
  l_priority := upper(json_value(l_json, '$.priority'));

  ------------------------------------------------------------------
  -- 2. Yalnız icazəli əməliyyatlar icra olunur
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
               where (l_priority is null or priority = l_priority)
                 and (l_status   is null or status   = l_status)
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
      p('<p class="dt-green"><b>№'||l_id||' sorğusunun statusu dəyişdirildi: '||
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

  elsif l_action = 'SUMMARY' then
    for t in (select ticket_id, subject, priority, status from v_tickets) loop
      l_data := l_data || t.ticket_id||'|'||t.subject||'|'||
                t.priority||'|'||t.status||chr(10);
    end loop;
    p('<p>'||apex_escape.html(
        apex_ai.generate_text(
          p_system_prompt => 'Azərbaycan dilində qısa xülasə yaz. Maksimum 5 cümlə.',
          p_prompt        => 'Bu dəstək sorğularını təhlil et:'||chr(10)||l_data,
          p_service_static_id => 'MAIN_AI'))||'</p>');

  else
    p('<p>Sorğunu başa düşmədim. Nümunə: «4821 nömrəli sorğunu tap» '||
      'və ya «təcili sorğuları göstər».</p>');
  end if;

  htp.p(l_out);
exception
  when others then
    htp.p('<p class="dt-red">Xəta: '||apex_escape.html(sqlerrm)||'</p>');
end;


-- -----------------------------------------------------------------
-- [C] JAVASCRIPT
-- Page Designer > səhifə adı > JavaScript >
-- "Function and Global Variable Declaration"
-- -----------------------------------------------------------------
/*
function dtAi() {
  var txt = document.getElementById('aiCmd').value;
  if (!txt) return;
  var out = document.getElementById('aiOut');
  out.innerHTML = '<p class="dt-muted">Düşünürəm...</p>';
  apex.server.process('AI_COMMAND', { x01: txt }, { dataType: 'text' })
    .done(function (data) { out.innerHTML = data; })
    .fail(function (j, t, e) {
      out.innerHTML = '<p style="color:#B3261E">Xəta: ' + (e || t) + '</p>';
    });
}
*/


-- -----------------------------------------------------------------
-- [D] ƏLAVƏ CSS — Inline CSS-ə əlavə edin
-- -----------------------------------------------------------------
/*
.dt-ai-input{flex:1;padding:10px 14px;border:1px solid #D8D6CF;
  border-radius:8px;font-size:14px;font-family:inherit}
.dt-ai-input:focus{outline:none;border-color:#0C6E6E}
*/
