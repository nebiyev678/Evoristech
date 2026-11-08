-- =================================================================
-- DƏSTƏK SORĞULARI — SÜRÜŞDÜRMƏ (DRAG & DROP) İLƏ
-- 04_destek_sorgulari.sql faylını əvəz edir.
--
-- Kartı siçanla tutub başqa sütuna atmaq mümkündür.
-- Geriyə hərəkət də işləyir (İcradadır -> Yeni).
-- Düymələr saxlanılıb: telefon və planşetdə sürüşdürmə işləmir.
--
-- Ajax proses dəyişmir — TICKET_STATUS eynidir.
-- =================================================================


-- -----------------------------------------------------------------
-- [A] REGION SOURCE
-- Create Region > Type: Dynamic Content
-- Source: PL/SQL Function Body returning a CLOB
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

    -- Sütun özü atma zonasıdır (data-status atributu vacibdir)
    p('<div class="kb-col" data-status="'||p_status||'" '||
      'ondragover="kbOver(event)" ondragleave="kbLeave(event)" '||
      'ondrop="kbDrop(event)">');
    p('<div class="dt-col-h"><span>'||p_label||'</span>'||
      '<span class="dt-count" data-count="'||p_status||'">'||l_cnt||'</span></div>');
    p('<div class="kb-body">');

    for t in (select * from v_tickets where status = p_status
               order by case priority when 'URGENT' then 1
                                      when 'MEDIUM' then 2
                                      else 3 end, created_date) loop
      p('<div class="dt-ticket kb-card '||
          case when p_status = 'RESOLVED' then 'done'
               else 'p-'||lower(t.priority) end||'" '||
        'draggable="true" data-id="'||t.ticket_id||'" '||
        'ondragstart="kbStart(event)" ondragend="kbEnd(event)">');
      p('<div class="dt-ticket-id">№'||t.ticket_id||' &middot; '||
        to_char(t.created_date,'DD.MM.YYYY')||'</div>');
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
        p('<button type="button" class="dt-btn kb-btn" '||
          'onclick="dtAction(''TICKET_STATUS'','||t.ticket_id||','''||p_next||''')">'||
          p_btn_label||'</button>');
      end if;
      p('</div>');
    end loop;

    p('</div></div>');
  end;
begin
  p('<div class="dt">');
  p('<p class="kb-hint">Kartı tutub başqa sütuna sürüşdürün. '||
    'Səhv olarsa geri qaytara bilərsiniz.</p>');
  p('<div class="dt-kanban">');
  render_column('NEW',         'Yeni',                 'İcraya başla', 'IN_PROGRESS');
  render_column('IN_PROGRESS', 'İcradadır',            'Həll edildi',  'RESOLVED');
  render_column('WAITING',     'Sorğu edəni gözləyir', 'Davam et',     'IN_PROGRESS');
  render_column('RESOLVED',    'Həll edilib',          'Yenidən aç',   'NEW');
  p('</div></div>');
  return l_h;
end;


-- -----------------------------------------------------------------
-- [B] JAVASCRIPT
-- Page Designer > səhifə adı > JavaScript >
-- "Function and Global Variable Declaration"
-- (dtAction funksiyası 00_shared_javascript_az.js-dən lazımdır)
-- -----------------------------------------------------------------
/*
var kbDragged = null;
var kbFromCol = null;

function kbStart(ev) {
  kbDragged = ev.currentTarget;
  kbFromCol = kbDragged.closest('.kb-col');
  kbDragged.classList.add('dragging');
  ev.dataTransfer.effectAllowed = 'move';
  ev.dataTransfer.setData('text/plain', kbDragged.dataset.id);
}

function kbEnd(ev) {
  if (kbDragged) kbDragged.classList.remove('dragging');
}

function kbOver(ev) {
  if (!kbDragged) return;
  ev.preventDefault();                   // bu olmasa atmaq mümkün olmur
  ev.currentTarget.classList.add('kb-over');
}

function kbLeave(ev) {
  ev.currentTarget.classList.remove('kb-over');
}

function kbDrop(ev) {
  ev.preventDefault();
  var col = ev.currentTarget;
  col.classList.remove('kb-over');
  if (!kbDragged) return;

  var newStatus = col.dataset.status;
  var oldStatus = kbFromCol ? kbFromCol.dataset.status : null;
  if (newStatus === oldStatus) return;   // eyni sütun — heç nə etmə

  var id   = kbDragged.dataset.id;
  var card = kbDragged;
  var from = kbFromCol;

  // 1. Kartı dərhal köçür (istifadəçi gözləmir)
  col.querySelector('.kb-body').appendChild(card);
  kbRecolor(card, newStatus);
  kbCount(oldStatus, -1);
  kbCount(newStatus, 1);
  card.classList.add('saving');

  // 2. Serverə yaz
  apex.server.process('TICKET_STATUS',
    { x01: id, x02: newStatus }, { dataType: 'text' }
  ).done(function () {
    card.classList.remove('saving');
    kbButton(card, newStatus);
    apex.message.showPageSuccess('№' + id + ' köçürüldü');
  }).fail(function (j, t, e) {
    // 3. Alınmadısa geri qaytar
    card.classList.remove('saving');
    if (from) {
      from.querySelector('.kb-body').appendChild(card);
      kbRecolor(card, oldStatus);
      kbCount(newStatus, -1);
      kbCount(oldStatus, 1);
      kbButton(card, oldStatus);
    }
    apex.message.alert('Yadda saxlanılmadı: ' + (e || t));
  });

  kbDragged = null;
  kbFromCol = null;
}

// Sütun başlığındaki sayı dəyiş
function kbCount(status, delta) {
  if (!status) return;
  var el = document.querySelector('[data-count="' + status + '"]');
  if (el) el.textContent = Math.max(0, parseInt(el.textContent, 10) + delta);
}

// Həll edilmiş sütununda kartın görünüşünü dəyiş
function kbRecolor(card, status) {
  card.classList.toggle('done', status === 'RESOLVED');
}

// Kartın düyməsini yeni statusa uyğunlaşdır
function kbButton(card, status) {
  var map = {
    'NEW':         ['İcraya başla', 'IN_PROGRESS'],
    'IN_PROGRESS': ['Həll edildi',  'RESOLVED'],
    'WAITING':     ['Davam et',     'IN_PROGRESS'],
    'RESOLVED':    ['Yenidən aç',   'NEW']
  };
  var btn = card.querySelector('.kb-btn');
  var cfg = map[status];
  if (btn && cfg) {
    btn.textContent = cfg[0];
    btn.setAttribute('onclick',
      "dtAction('TICKET_STATUS'," + card.dataset.id + ",'" + cfg[1] + "')");
  }
}
*/


-- -----------------------------------------------------------------
-- [C] ƏLAVƏ CSS — Inline CSS-ə əlavə edin
-- -----------------------------------------------------------------
/*
.kb-hint{font-size:13px;color:#6B6A64;margin:0 0 14px}

.kb-col{border-radius:14px;padding:6px;transition:background .15s,outline .15s;
  outline:2px dashed transparent;outline-offset:-4px}
.kb-col.kb-over{background:#EFF7F6;outline-color:#0C6E6E}
.kb-body{min-height:120px}

.kb-card{cursor:grab;user-select:none;transition:opacity .15s,transform .15s}
.kb-card:active{cursor:grabbing}
.kb-card.dragging{opacity:.45;transform:rotate(1.5deg)}
.kb-card.saving{opacity:.6;pointer-events:none}

@media (max-width:900px){
  .kb-card{cursor:default}
  .kb-hint{display:none}
}
*/
