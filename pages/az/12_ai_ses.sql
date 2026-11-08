-- =================================================================
-- EVORIS — AI REGIONU ÜÇÜN SƏS GİRİŞİ
-- App 104 · Səhifə 2 (Dashboard) · AI Region
--
-- Web Speech API brauzerdə işləyir: server tərəfi dəyişmir,
-- açar lazım deyil, pul tutmur. Mətn hazır olduqda mövcud
-- dtAi() funksiyası çağırılır — AI_ASSISTANT prosesi dəyişmir.
--
-- ŞƏRTLƏR
--   * HTTPS — OCI-də var
--   * Chrome / Edge. Brave və bəzi Chromium qurğularında işləmir
--   * Mikrofona icazə — istifadəçi bir dəfə verir
-- =================================================================


-- -----------------------------------------------------------------
-- [A] MİKROFON DÜYMƏSİ
-- AI Region > Source > HTML Code içində, «aiCmd» input-unun
-- YANINA əlavə edin (eyni flex sətrində).
-- -----------------------------------------------------------------
/*
<button type="button" id="evMic" class="ev-mic" onclick="evVoice()"
        title="Səslə danış" aria-label="Səslə danış">
  <svg class="ev-mic-i" viewBox="0 0 24 24" width="18" height="18" fill="none"
       stroke="currentColor" stroke-width="2" stroke-linecap="round"
       stroke-linejoin="round" aria-hidden="true">
    <rect x="9" y="2" width="6" height="11" rx="3"></rect>
    <path d="M5 11a7 7 0 0 0 14 0"></path>
    <path d="M12 18v3"></path>
  </svg>
</button>
*/

-- Düymənin ALTINA, input sətrindən sonra — vəziyyət sətri:
/*
<div class="ev-voice-bar" id="evVoiceBar" hidden>
  <span class="ev-voice-dot" aria-hidden="true"></span>
  <span class="ev-voice-msg" id="evVoiceMsg" role="status" aria-live="polite"></span>
  <button type="button" class="ev-voice-cancel" id="evVoiceCancel"
          onclick="evVoiceCancel()" hidden>Ləğv et</button>
</div>
*/


-- -----------------------------------------------------------------
-- [B] CSS
-- Səhifə 2 > CSS > Inline (mövcud blokun sonuna)
-- -----------------------------------------------------------------
/*
.ev-mic{
  display:inline-flex; align-items:center; justify-content:center;
  width:38px; height:38px; flex:none; padding:0;
  border:1px solid #E3E1DB; border-radius:9px;
  background:#FFFFFF; color:#0C6E6E; cursor:pointer;
  transition:background .15s ease, color .15s ease, border-color .15s ease;
}
.ev-mic:hover{background:#F4F3EF}
.ev-mic:focus-visible{outline:none;box-shadow:0 0 0 3px rgba(12,110,110,.25)}
.ev-mic[disabled]{opacity:.45;cursor:default}

.ev-mic.listening{
  background:#0C6E6E; color:#FFFFFF; border-color:#0C6E6E;
  animation:ev-pulse 1.3s ease-in-out infinite;
}

@keyframes ev-pulse{
  0%,100%{box-shadow:0 0 0 0 rgba(12,110,110,.45)}
  50%    {box-shadow:0 0 0 7px rgba(12,110,110,0)}
}

.ev-voice-bar{
  display:flex; align-items:center; gap:8px;
  margin-top:8px; font-size:13px; color:#6B6A64;
}
.ev-voice-dot{
  width:7px; height:7px; border-radius:50%;
  background:#B9C6C5; flex:none;
}
.ev-voice-bar.live   .ev-voice-dot{background:#0C6E6E;animation:ev-blink 1s infinite}
.ev-voice-bar.sending .ev-voice-dot{background:#B7791F}
.ev-voice-bar.err    .ev-voice-dot{background:#B3261E}
.ev-voice-bar.err    .ev-voice-msg{color:#B3261E}

@keyframes ev-blink{50%{opacity:.25}}

.ev-voice-msg{flex:1;min-width:0}

.ev-voice-cancel{
  flex:none; padding:3px 10px;
  border:1px solid #E3E1DB; border-radius:7px;
  background:#FFFFFF; color:#16302F;
  font-size:12px; font-weight:600; cursor:pointer;
}
.ev-voice-cancel:hover{background:#F4F3EF}

@media (prefers-reduced-motion:reduce){
  .ev-mic.listening{animation:none}
  .ev-voice-bar.live .ev-voice-dot{animation:none}
}
*/


-- -----------------------------------------------------------------
-- [C] JAVASCRIPT
-- Səhifə 2 > JavaScript > "Function and Global Variable Declaration"
-- Əvvəlki evVoice funksiyasını BU BLOKLA tam əvəz edin.
-- -----------------------------------------------------------------
/*
// ---------- vəziyyət ----------
var evRec     = null;    // SpeechRecognition obyekti
var evOn      = false;   // dinləyirik?
var evLang    = 'az-AZ'; // ilk cəhd; dəstəklənmirsə tr-TR-ə keçir
var evSendT   = null;    // göndərmə taymeri
var evHeard   = '';      // tanınmış mətn

function evBar(cls, msg, showCancel) {
  var bar = document.getElementById('evVoiceBar');
  var m   = document.getElementById('evVoiceMsg');
  var c   = document.getElementById('evVoiceCancel');
  if (!bar) return;
  bar.hidden = !msg;
  bar.className = 'ev-voice-bar' + (cls ? ' ' + cls : '');
  if (m) m.textContent = msg || '';
  if (c) c.hidden = !showCancel;
}

function evMicOn(on) {
  var b = document.getElementById('evMic');
  if (b) b.classList.toggle('listening', on);
  evOn = on;
}

// ---------- əsas ----------
function evVoice() {
  // ikinci klik = dayandır
  if (evOn) { evVoiceStop(); return; }

  var SR = window.SpeechRecognition || window.webkitSpeechRecognition;
  if (!SR) {
    evBar('err', 'Bu brauzer səs tanımanı dəstəkləmir. Chrome istifadə edin.');
    return;
  }

  evVoiceCancel();          // gözləyən göndərmə varsa ləğv et
  evHeard = '';

  evRec = new SR();
  evRec.lang            = evLang;
  evRec.interimResults  = true;
  evRec.continuous      = false;
  evRec.maxAlternatives = 1;

  evRec.onstart = function () {
    evMicOn(true);
    evBar('live', 'Dinləyirəm… danışın');
  };

  evRec.onresult = function (ev) {
    var txt = '', fin = false;
    for (var i = 0; i < ev.results.length; i++) {
      txt += ev.results[i][0].transcript;
      if (ev.results[i].isFinal) fin = true;
    }
    evHeard = txt;

    var box = document.getElementById('aiCmd');
    if (box) box.value = txt;              // canlı yazılır

    if (fin) { evRec.stop(); }
  };

  evRec.onerror = function (ev) {
    evMicOn(false);
    switch (ev.error) {
      case 'no-speech':
        evBar('err', 'Səs eşidilmədi. Mikrofonu yoxlayın və yenidən cəhd edin.');
        break;
      case 'not-allowed':
      case 'service-not-allowed':
        evBar('err', 'Mikrofona icazə verilmədi. Ünvan sətrindəki kilid işarəsindən icazə verin.');
        break;
      case 'network':
        evBar('err', 'Səs xidmətinə qoşulmaq olmadı. Şəbəkəni yoxlayın.');
        break;
      case 'language-not-supported':
        if (evLang === 'az-AZ') {          // bir dəfə türk dilinə keç
          evLang = 'tr-TR';
          evBar('', 'Azərbaycan dili dəstəklənmir — türk dili ilə cəhd edilir…');
          setTimeout(evVoice, 300);
          return;
        }
        evBar('err', 'Səs tanıma bu dil üçün mövcud deyil.');
        break;
      case 'aborted':
        evBar('', '');
        break;
      default:
        evBar('err', 'Səs tanıma xətası: ' + ev.error);
    }
  };

  evRec.onend = function () {
    evMicOn(false);
    var t = (evHeard || '').trim();
    if (!t) return;                        // xəta mesajı onerror-da verilib

    // ---- təhlükəsizlik pəncərəsi ----
    // AI_ASSISTANT məlumatı DƏYİŞƏ bilər (MOVE_TICKET).
    // Səhv eşidilibsə istifadəçi dayandıra bilsin deyə
    // dərhal yox, 2 saniyə sonra göndərilir.
    evBar('sending', '« ' + t + ' » göndərilir…', true);
    evSendT = setTimeout(function () {
      evSendT = null;
      evBar('', '');
      if (typeof dtAi === 'function') dtAi();
    }, 2000);
  };

  try {
    evRec.start();
  } catch (e) {
    evMicOn(false);
    evBar('err', 'Başlatmaq olmadı: ' + e.message);
  }
}

function evVoiceStop() {
  if (evRec) { try { evRec.stop(); } catch (e) {} }
  evMicOn(false);
}

function evVoiceCancel() {
  if (evSendT) { clearTimeout(evSendT); evSendT = null; }
  evBar('', '');
}

// Esc = dayandır / ləğv et
document.addEventListener('keydown', function (e) {
  if (e.key !== 'Escape') return;
  if (evOn)   evVoiceStop();
  if (evSendT) evVoiceCancel();
});
*/


-- -----------------------------------------------------------------
-- [D] YOXLAMA
--
-- 1. Düyməyə klik → düymə yaşıl olur, «Dinləyirəm… danışın» çıxır
-- 2. Danışın → mətn input-da canlı görünür
-- 3. Susun → «... göndərilir…» + «Ləğv et» düyməsi, 2 saniyə
-- 4. Gözləyin → AI cavab verir.  Və ya «Ləğv et» / Esc → dayanır
-- 5. Dinləyərkən düyməyə ikinci dəfə klik → dayanır
--
-- NƏ ÜÇÜN 2 SANİYƏ GÖZLƏYİR
-- AI_ASSISTANT prosesi MOVE_TICKET ilə məlumatı dəyişə bilir.
-- Səs səhv eşidilsə, dərhal göndərilən əmr məlumatı dəyişərdi.
-- 2 saniyəlik pəncərə istifadəçiyə dayandırmaq imkanı verir.
-- Əsl həll: AI_ASSISTANT-da yazma əməliyyatları üçün
-- təsdiq addımı + icazə yoxlaması (ayrıca iş).
--
-- DİL
-- İlk cəhd az-AZ. Brauzer dəstəkləmirsə bir dəfə tr-TR-ə keçir və
-- sessiya ərzində orada qalır. Hansının daha dəqiq olduğunu
-- yoxlamaq üçün konsolda:  evLang='tr-TR'; evVoice();
-- -----------------------------------------------------------------
