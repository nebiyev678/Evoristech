-- =================================================================
-- İDARƏ PANELİ — AI TƏHLİL BLOKU
-- Sifariş məbləğləri üzərində təbii dildə hesablama
--
-- TƏLƏBLƏR: executive_dashboard_schema.sql (orders, regions,
--           v_orders_detail, v_region_summary)
--           Generative AI servis, Static ID: MAIN_AI
--
-- PRİNSİP: model YALNIZ hansı hesablamanın aparılacağını seçir.
--          Bütün riyaziyyat SQL-də aparılır. Model rəqəm hesablamır.
-- =================================================================


-- -----------------------------------------------------------------
-- [A] REGION SOURCE  (mövcud panel səhifəsinə əlavə region)
-- Create Region > Type: Dynamic Content
-- Source: PL/SQL Function Body returning a CLOB
-- Appearance > Template: Blank with Attributes
-- -----------------------------------------------------------------
declare
  l_h clob;
begin
  l_h := '<div class="dt"><div class="dt-card">'||
         '<div class="dt-card-h"><h2>Təhlil sorğusu</h2></div>'||
         '<div class="dt-card-b">'||
         '<div style="display:flex;gap:10px;align-items:center">'||
         '<input type="text" id="anCmd" class="dt-ai-input" '||
         'placeholder="Məsələn: region üzrə orta sifariş məbləği" '||
         'onkeydown="if(event.key===''Enter'')dtAnaliz()">'||
         '<button type="button" class="dt-btn" onclick="dtAnaliz()">Hesabla</button>'||
         '</div>'||
         '<div style="margin-top:10px;font-size:12px;color:#6B6A64">'||
         'Nümunələr: «region üzrə cəmi gəlir» &middot; '||
         '«status üzrə orta məbləğ» &middot; '||
         '«son 30 günün aylıq gəliri» &middot; '||
         '«açıq sifarişlərin cəmi region üzrə»'||
         '</div>'||
         '<div id="anOut" style="margin-top:16px"></div>'||
         '</div></div></div>';
  return l_h;
end;


-- -----------------------------------------------------------------
-- [B] AJAX CALLBACK PROCESS
--   Name: AI_ANALIZ        <-- dəqiq bu ad
--   Type: Execute Code (PL/SQL)
-- -----------------------------------------------------------------
declare
  l_input   varchar2(4000) := apex_application.g_x01;
  l_json    clob;
  l_metric  varchar2(30);
  l_dim     varchar2(30);
  l_status  varchar2(30);
  l_days    number;
  l_out     clob := '';
  l_rows    clob := '';
  l_total   number := 0;
  l_cnt     number := 0;
  l_label   varchar2(100);
  l_dimname varchar2(100);

  procedure p(s varchar2) is begin l_out := l_out || s; end;
begin
  ------------------------------------------------------------------
  -- 1. Model yalnız hesablama növünü seçir (rəqəm hesablamır)
  ------------------------------------------------------------------
  l_json := apex_ai.generate_text(
    p_system_prompt =>
      'İstifadəçinin sorğusunu JSON-a çevir. YALNIZ JSON qaytar. '||
      'Struktur: {"metric":"...","dimension":"...","status":null,"days":null}. '||
      'metric dəyərləri: SUM (cəmi məbləğ), AVG (orta məbləğ), '||
      'COUNT (sifariş sayı), MAX (ən böyük), MIN (ən kiçik). '||
      'dimension dəyərləri: REGION, STATUS, MONTH, NONE. '||
      'status dəyərləri (filtr üçün, yoxdursa null): OPEN, FULFILLED, '||
      'PAST_DUE, CANCELLED. '||
      'days: son N günü göstərir, qeyd olunmayıbsa null.',
    p_prompt            => l_input,
    p_service_static_id => 'MAIN_AI');

  l_json := regexp_replace(l_json, '```(json)?', '');

  l_metric := upper(json_value(l_json, '$.metric'));
  l_dim    := upper(json_value(l_json, '$.dimension'));
  l_status := upper(json_value(l_json, '$.status'));
  l_days   := json_value(l_json, '$.days' returning number);

  -- Yalnız icazəli dəyərlər qəbul olunur
  if l_metric not in ('SUM','AVG','COUNT','MAX','MIN') then
    l_metric := 'SUM';
  end if;
  if l_dim not in ('REGION','STATUS','MONTH','NONE') then
    l_dim := 'NONE';
  end if;
  if l_status is not null
     and l_status not in ('OPEN','FULFILLED','PAST_DUE','CANCELLED') then
    l_status := null;
  end if;
  if l_days is not null and (l_days <= 0 or l_days > 3650) then
    l_days := null;
  end if;

  l_label := case l_metric
               when 'SUM'   then 'Cəmi məbləğ'
               when 'AVG'   then 'Orta məbləğ'
               when 'COUNT' then 'Sifariş sayı'
               when 'MAX'   then 'Ən böyük məbləğ'
               else              'Ən kiçik məbləğ' end;
  l_dimname := case l_dim
                 when 'REGION' then 'Region'
                 when 'STATUS' then 'Status'
                 when 'MONTH'  then 'Ay'
                 else               'Ümumi' end;

  ------------------------------------------------------------------
  -- 2. BÜTÜN HESABLAMA SQL-DƏ APARILIR
  --    Model heç bir rəqəmə toxunmur. SQL mətni sabitdir,
  --    dəyişənlər yalnız bind kimi istifadə olunur.
  ------------------------------------------------------------------
  for r in (
    select grp,
           case l_metric
             when 'SUM'   then sum_amt
             when 'AVG'   then avg_amt
             when 'COUNT' then cnt
             when 'MAX'   then max_amt
             else              min_amt
           end as val
      from (
        select case l_dim
                 when 'REGION' then region_name
                 when 'STATUS' then status
                 when 'MONTH'  then to_char(order_date,'YYYY-MM')
                 else               'Ümumi'
               end                      as grp,
               nvl(sum(amount),0)       as sum_amt,
               round(avg(amount),2)     as avg_amt,
               count(*)                 as cnt,
               max(amount)              as max_amt,
               min(amount)              as min_amt
          from v_orders_detail
         where (l_status is null or status = l_status)
           and (l_days   is null or order_date >= trunc(sysdate) - l_days)
         group by case l_dim
                    when 'REGION' then region_name
                    when 'STATUS' then status
                    when 'MONTH'  then to_char(order_date,'YYYY-MM')
                    else               'Ümumi'
                  end
      )
     order by val desc
  ) loop
    l_rows := l_rows ||
      '<tr><td><b>'||apex_escape.html(r.grp)||'</b></td>'||
      '<td style="text-align:right"><b>'||
      case when l_metric = 'COUNT'
           then to_char(r.val,'FM999G999G990')
           else to_char(r.val,'FM999G999G990D00')||' ₼' end||
      '</b></td></tr>';
    l_total := l_total + nvl(r.val,0);
    l_cnt   := l_cnt + 1;
  end loop;

  ------------------------------------------------------------------
  -- 3. Nəticəni göstər
  ------------------------------------------------------------------
  if l_cnt = 0 then
    p('<p>Bu şərtlərə uyğun sifariş tapılmadı.</p>');
  else
    p('<p style="font-size:13px;color:#6B6A64;margin-bottom:10px">'||
      l_label||' &middot; '||l_dimname||' üzrə'||
      case when l_status is not null then ' &middot; filtr: '||l_status end||
      case when l_days   is not null then ' &middot; son '||l_days||' gün' end||
      '</p>');
    p('<table class="dt-table"><thead><tr><th>'||l_dimname||'</th>'||
      '<th style="text-align:right">'||l_label||'</th></tr></thead><tbody>');
    p(l_rows);
    if l_cnt > 1 and l_metric in ('SUM','COUNT') then
      p('<tr style="background:#F7F6F2"><td><b>Cəmi</b></td>'||
        '<td style="text-align:right"><b>'||
        case when l_metric = 'COUNT'
             then to_char(l_total,'FM999G999G990')
             else to_char(l_total,'FM999G999G990D00')||' ₼' end||
        '</b></td></tr>');
    end if;
    p('</tbody></table>');
    p('<p style="font-size:11px;color:#9C9A91;margin-top:8px">'||
      'Rəqəmlər verilənlər bazasından hesablanıb.</p>');
  end if;

  htp.p(l_out);
exception
  when others then
    htp.p('<p style="color:#B3261E">Xəta: '||apex_escape.html(sqlerrm)||'</p>');
end;


-- -----------------------------------------------------------------
-- [C] JAVASCRIPT — səhifənin "Function and Global Variable
--     Declaration" bölməsinə əlavə edin
-- -----------------------------------------------------------------
/*
function dtAnaliz() {
  var txt = document.getElementById('anCmd').value;
  if (!txt) return;
  var out = document.getElementById('anOut');
  out.innerHTML = '<p style="color:#6B6A64">Hesablanır...</p>';
  apex.server.process('AI_ANALIZ', { x01: txt }, { dataType: 'text' })
    .done(function (data) { out.innerHTML = data; })
    .fail(function (j, t, e) {
      out.innerHTML = '<p style="color:#B3261E">Xəta: ' + (e || t) + '</p>';
    });
}
*/
