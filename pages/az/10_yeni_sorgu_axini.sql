-- =================================================================
-- YENİ SORĞU YARATMA — ADDIMLI AXIN (WIZARD)
-- 3 addım: Məlumat → Təfərrüat → Yoxlama və göndərmə
--
-- TƏLƏBLƏR: helpdesk_ticketing_schema.sql (tickets, agents, v_tickets)
--           00_shared_styles.css səhifədə Inline CSS kimi
--
-- Bütün addımlar BİR səhifədədir — JavaScript göstərir/gizlədir.
-- Yalnız sonuncu addımda baza yazılır, ona görə yarımçıq qeyd qalmır.
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
begin
  p('<div class="dt"><div class="wz">');

  ---------------------------------------------------------------- addım göstəricisi
  p('<div class="wz-steps">');
  p('<div class="wz-step active" data-step="1">'||
    '<span class="wz-num">1</span><span class="wz-label">Məlumat</span></div>');
  p('<div class="wz-line"></div>');
  p('<div class="wz-step" data-step="2">'||
    '<span class="wz-num">2</span><span class="wz-label">Təfərrüat</span></div>');
  p('<div class="wz-line"></div>');
  p('<div class="wz-step" data-step="3">'||
    '<span class="wz-num">3</span><span class="wz-label">Yoxlama</span></div>');
  p('</div>');

  ---------------------------------------------------------------- ADDIM 1
  p('<div class="wz-panel" data-panel="1">');
  p('<h2 class="wz-h">Sorğunu kim göndərir?</h2>');
  p('<p class="wz-sub">Sorğu sahibini və təcililik səviyyəsini seçin.</p>');

  p('<div class="wz-field">');
  p('<label for="wzRequester">Sorğu edən</label>');
  p('<input type="text" id="wzRequester" maxlength="120" '||
    'placeholder="Ad və soyad" value="'||apex_escape.html(:APP_USER)||'">');
  p('<div class="wz-err" id="errRequester"></div>');
  p('</div>');

  p('<div class="wz-field">');
  p('<label>Prioritet</label>');
  p('<div class="wz-radios">');
  p('<button type="button" class="wz-radio p-low" data-prio="LOW" '||
    'onclick="wzPrio(this)">Aşağı</button>');
  p('<button type="button" class="wz-radio p-med selected" data-prio="MEDIUM" '||
    'onclick="wzPrio(this)">Orta</button>');
  p('<button type="button" class="wz-radio p-urg" data-prio="URGENT" '||
    'onclick="wzPrio(this)">Təcili</button>');
  p('</div>');
  p('</div>');

  p('<div class="wz-nav"><span></span>'||
    '<button type="button" class="dt-btn" onclick="wzNext(1)">Növbəti →</button></div>');
  p('</div>');

  ---------------------------------------------------------------- ADDIM 2
  p('<div class="wz-panel" data-panel="2" hidden>');
  p('<h2 class="wz-h">Problem nədir?</h2>');
  p('<p class="wz-sub">Qısa başlıq və izah yazın — nə qədər dəqiq olsa, bir o qədər tez həll olunur.</p>');

  p('<div class="wz-field">');
  p('<label for="wzSubject">Mövzu</label>');
  p('<input type="text" id="wzSubject" maxlength="200" '||
    'placeholder="Məsələn: VPN bağlantısı kəsilir" '||
    'oninput="wzCount()">');
  p('<div class="wz-hint"><span id="wzSubjCount">0</span>/200</div>');
  p('<div class="wz-err" id="errSubject"></div>');
  p('</div>');

  p('<div class="wz-field">');
  p('<label for="wzDesc">Təfərrüat</label>');
  p('<textarea id="wzDesc" rows="5" maxlength="1000" '||
    'placeholder="Nə vaxt başladı, nə etdikdə təkrarlanır, hansı xəta mesajı çıxır..."></textarea>');
  p('<div class="wz-err" id="errDesc"></div>');
  p('</div>');

  p('<div class="wz-nav">'||
    '<button type="button" class="dt-btn dt-btn-ghost" onclick="wzBack(2)">← Geri</button>'||
    '<button type="button" class="dt-btn" onclick="wzNext(2)">Növbəti →</button></div>');
  p('</div>');

  ---------------------------------------------------------------- ADDIM 3
  p('<div class="wz-panel" data-panel="3" hidden>');
  p('<h2 class="wz-h">Yoxlayın və göndərin</h2>');
  p('<p class="wz-sub">Məlumatlar düzgündürsə təsdiqləyin. Geri qayıdıb dəyişə bilərsiniz.</p>');

  p('<div class="wz-review" id="wzReview"></div>');

  p('<div class="wz-nav">'||
    '<button type="button" class="dt-btn dt-btn-ghost" onclick="wzBack(3)">← Geri</button>'||
    '<button type="button" class="dt-btn" id="wzSubmit" onclick="wzSave()">Sorğunu göndər</button></div>');
  p('</div>');

  ---------------------------------------------------------------- NƏTİCƏ
  p('<div class="wz-panel wz-done" data-panel="4" hidden>');
  p('<div class="wz-check">');
  p('<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" '||
    'stroke-linecap="round" stroke-linejoin="round"><path d="M20 6L9 17l-5-5"/></svg>');
  p('</div>');
  p('<h2 class="wz-h">Sorğunuz qeydə alındı</h2>');
  p('<p class="wz-sub" id="wzDoneMsg"></p>');
  p('<div class="wz-nav wz-nav-center">'||
    '<button type="button" class="dt-btn dt-btn-ghost" onclick="wzReset()">Yeni sorğu</button>'||
    '<a href="Destek.dc.html" class="dt-btn" style="text-decoration:none">Sorğulara bax</a></div>');
  p('</div>');

  p('</div></div>');
  return l_h;
end;


-- -----------------------------------------------------------------
-- [B] AJAX CALLBACK PROCESS
-- Processing tab > "Ajax Callback" üzərində sağ klik > Create Process
--   Name: CREATE_TICKET     <-- dəqiq bu ad
--   Type: Execute Code (PL/SQL)
-- -----------------------------------------------------------------
declare
  l_requester varchar2(120)  := trim(apex_application.g_x01);
  l_priority  varchar2(20)   := upper(trim(apex_application.g_x02));
  l_subject   varchar2(200)  := trim(apex_application.g_x03);
  l_desc      varchar2(1000) := trim(apex_application.g_x04);
  l_id        number;
begin
  -- Server tərəfi yoxlama (brauzerdən gələn dəyərə etibar edilmir)
  if l_requester is null then
    raise_application_error(-20001, 'Sorğu edən boş ola bilməz');
  end if;
  if l_subject is null or length(l_subject) < 5 then
    raise_application_error(-20002, 'Mövzu ən azı 5 simvol olmalıdır');
  end if;
  if l_priority not in ('LOW','MEDIUM','URGENT') then
    l_priority := 'MEDIUM';
  end if;

  insert into tickets (subject, requester_name, priority, status,
                       created_date, description)
  values (l_subject, l_requester, l_priority, 'NEW',
          sysdate, l_desc)
  returning ticket_id into l_id;

  htp.p(l_id);          -- yeni sorğunun nömrəsi brauzerə qayıdır
end;


-- -----------------------------------------------------------------
-- [C] JAVASCRIPT
-- Page Designer > səhifə adı > JavaScript >
-- "Function and Global Variable Declaration"
-- -----------------------------------------------------------------
/*
var wzData = { requester: '', priority: 'MEDIUM', subject: '', desc: '' };

function wzShow(n) {
  document.querySelectorAll('.wz-panel').forEach(function (el) {
    el.hidden = (parseInt(el.dataset.panel, 10) !== n);
  });
  document.querySelectorAll('.wz-step').forEach(function (el) {
    var s = parseInt(el.dataset.step, 10);
    el.classList.toggle('active', s === n);
    el.classList.toggle('done', s < n);
  });
  var first = document.querySelector('.wz-panel:not([hidden]) input, ' +
                                     '.wz-panel:not([hidden]) textarea');
  if (first) first.focus();
}

function wzPrio(btn) {
  document.querySelectorAll('.wz-radio').forEach(function (b) {
    b.classList.remove('selected');
  });
  btn.classList.add('selected');
  wzData.priority = btn.dataset.prio;
}

function wzCount() {
  document.getElementById('wzSubjCount').textContent =
    document.getElementById('wzSubject').value.length;
}

function wzErr(id, msg) {
  document.getElementById(id).textContent = msg || '';
}

function wzNext(from) {
  if (from === 1) {
    var r = document.getElementById('wzRequester').value.trim();
    if (!r) { wzErr('errRequester', 'Ad daxil edin.'); return; }
    wzErr('errRequester');
    wzData.requester = r;
    wzShow(2);
  } else if (from === 2) {
    var s = document.getElementById('wzSubject').value.trim();
    var d = document.getElementById('wzDesc').value.trim();
    if (s.length < 5) { wzErr('errSubject', 'Mövzu ən azı 5 simvol olmalıdır.'); return; }
    wzErr('errSubject');
    wzData.subject = s;
    wzData.desc = d;
    wzReview();
    wzShow(3);
  }
}

function wzBack(from) { wzShow(from - 1); }

function wzReview() {
  var prioText = { LOW: 'Aşağı', MEDIUM: 'Orta', URGENT: 'Təcili' };
  var prioCls  = { LOW: 'dt-b-neutral', MEDIUM: 'dt-b-warn', URGENT: 'dt-b-bad' };
  var rows = [
    ['Sorğu edən', esc(wzData.requester)],
    ['Prioritet', '<span class="dt-badge ' + prioCls[wzData.priority] + '">' +
                  prioText[wzData.priority] + '</span>'],
    ['Mövzu', esc(wzData.subject)],
    ['Təfərrüat', wzData.desc ? esc(wzData.desc) : '<i class="dt-muted">yazılmayıb</i>']
  ];
  document.getElementById('wzReview').innerHTML = rows.map(function (r) {
    return '<div class="wz-rev-row"><div class="wz-rev-k">' + r[0] +
           '</div><div class="wz-rev-v">' + r[1] + '</div></div>';
  }).join('');
}

function esc(s) {
  return String(s).replace(/[&<>"']/g, function (c) {
    return { '&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;' }[c];
  });
}

function wzSave() {
  var btn = document.getElementById('wzSubmit');
  btn.disabled = true;
  btn.textContent = 'Göndərilir...';

  apex.server.process('CREATE_TICKET', {
    x01: wzData.requester,
    x02: wzData.priority,
    x03: wzData.subject,
    x04: wzData.desc
  }, { dataType: 'text' })
  .done(function (id) {
    document.getElementById('wzDoneMsg').textContent =
      'Sorğu nömrəniz: №' + String(id).trim() + '. Komanda baxdıqda status dəyişəcək.';
    wzShow(4);
  })
  .fail(function (j, t, e) {
    btn.disabled = false;
    btn.textContent = 'Sorğunu göndər';
    apex.message.alert('Göndərilmədi: ' + (e || t));
  });
}

function wzReset() {
  wzData = { requester: '', priority: 'MEDIUM', subject: '', desc: '' };
  document.getElementById('wzSubject').value = '';
  document.getElementById('wzDesc').value = '';
  wzCount();
  document.querySelectorAll('.wz-radio').forEach(function (b) {
    b.classList.toggle('selected', b.dataset.prio === 'MEDIUM');
  });
  var btn = document.getElementById('wzSubmit');
  btn.disabled = false;
  btn.textContent = 'Sorğunu göndər';
  wzShow(1);
}
*/


-- -----------------------------------------------------------------
-- [D] ƏLAVƏ CSS — Inline CSS-ə əlavə edin
-- -----------------------------------------------------------------
/*
.wz{background:#fff;border:1px solid #E3E1DB;border-radius:16px;
  padding:32px 36px;max-width:720px}

.wz-steps{display:flex;align-items:center;margin-bottom:28px}
.wz-step{display:flex;align-items:center;gap:10px;flex-shrink:0}
.wz-num{width:30px;height:30px;border-radius:50%;background:#EDECE6;
  color:#6B6A64;display:flex;align-items:center;justify-content:center;
  font-size:13px;font-weight:700;flex-shrink:0;transition:background .15s,color .15s}
.wz-label{font-size:13px;color:#6B6A64;white-space:nowrap}
.wz-step.active .wz-num{background:#0C6E6E;color:#fff}
.wz-step.active .wz-label{color:#1A1A18;font-weight:600}
.wz-step.done .wz-num{background:#D8F0E4;color:#116B45}
.wz-line{flex:1;height:2px;background:#E3E1DB;margin:0 12px;min-width:20px}

.wz-h{font-family:'Manrope',system-ui,sans-serif;font-size:22px;
  font-weight:800;margin:0 0 6px}
.wz-sub{font-size:14px;color:#6B6A64;margin:0 0 24px;line-height:1.5}

.wz-field{margin-bottom:20px}
.wz-field label{display:block;font-size:12px;font-weight:600;color:#6B6A64;
  margin-bottom:7px;text-transform:uppercase;letter-spacing:.03em}
.wz-field input,.wz-field textarea{width:100%;box-sizing:border-box;
  padding:11px 14px;border:1px solid #D8D6CF;border-radius:9px;
  font-family:inherit;font-size:14px;color:#1A1A18;background:#F7F6F2;
  transition:border-color .15s,background .15s}
.wz-field input:focus,.wz-field textarea:focus{outline:none;
  border-color:#0C6E6E;background:#fff;box-shadow:0 0 0 3px rgba(12,110,110,.10)}
.wz-field textarea{resize:vertical;line-height:1.5}
.wz-hint{font-size:11px;color:#9C9A91;text-align:right;margin-top:4px}
.wz-err{font-size:12px;color:#B3261E;margin-top:5px;min-height:16px}

.wz-radios{display:flex;gap:10px}
.wz-radio{flex:1;padding:12px;border:1px solid #D8D6CF;border-radius:9px;
  background:#fff;font-family:inherit;font-size:14px;font-weight:600;
  color:#6B6A64;cursor:pointer;transition:all .15s}
.wz-radio:hover{border-color:#9C9A91}
.wz-radio.selected{border-width:2px;padding:11px}
.wz-radio.p-low.selected{border-color:#57564F;background:#EDECE6;color:#57564F}
.wz-radio.p-med.selected{border-color:#B7791F;background:#FCEFD9;color:#8A5A12}
.wz-radio.p-urg.selected{border-color:#B3261E;background:#FBEAEA;color:#8C2019}

.wz-review{border:1px solid #E3E1DB;border-radius:12px;overflow:hidden;
  margin-bottom:24px}
.wz-rev-row{display:flex;gap:16px;padding:14px 18px;
  border-bottom:1px solid #EDECE6;font-size:14px}
.wz-rev-row:last-child{border-bottom:none}
.wz-rev-k{width:120px;flex-shrink:0;color:#6B6A64;font-size:12px;
  font-weight:600;text-transform:uppercase;letter-spacing:.03em;padding-top:2px}
.wz-rev-v{flex:1;line-height:1.5;white-space:pre-wrap;word-break:break-word}

.wz-nav{display:flex;justify-content:space-between;align-items:center;
  gap:12px;margin-top:8px}
.wz-nav-center{justify-content:center}
.wz-nav .dt-btn{padding:11px 22px;font-size:14px}
.wz-nav .dt-btn:disabled{opacity:.6;cursor:default}

.wz-done{text-align:center;padding:16px 0}
.wz-check{width:64px;height:64px;border-radius:50%;background:#D8F0E4;
  color:#116B45;display:flex;align-items:center;justify-content:center;
  margin:0 auto 20px}
.wz-check svg{width:32px;height:32px}

@media (max-width:640px){
  .wz{padding:24px 20px}
  .wz-label{display:none}
  .wz-radios{flex-direction:column}
  .wz-rev-row{flex-direction:column;gap:4px}
  .wz-rev-k{width:auto}
}
*/
