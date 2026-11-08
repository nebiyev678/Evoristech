-- =================================================================
-- EVORIS — OFFLINE SƏHİFƏSİ (PWA)
-- App 104 · Progressive Web App > Offline Page
--
-- Bu səhifə şəbəkə olmadıqda göstərilir. Deməli:
--   * VERİLƏNLƏR BAZASINA müraciət edə BİLMƏZ — offline halda sorğu
--     işləməyəcək. Heç bir PL/SQL region, heç bir cədvəl sorğusu.
--   * XARİCİ FAYL yükləyə BİLMƏZ — Google Fonts offline açılmır.
--     Ona görə şriftlər sistem şriftlərinə düşür. Bu normaldır.
--   * Səhifə PUBLIC olmalıdır — sessiya yoxdur.
--   * Hər şey inline: SVG, CSS, JS.
-- =================================================================


-- -----------------------------------------------------------------
-- [1] SƏHİFƏ YARADIN
-- App Builder > App 104 > Create Page > Blank Page
--   Page Number:  101
--   Name:         Offline
--   Page Mode:    Normal
--   Breadcrumb:   - do not use breadcrumbs -
--   Navigation:   Navigation Menu = yoxdur (gizlədin)
--
-- Sonra Page Designer-də səhifənin adına klik edin və təyin edin:
--   Security > Authentication:        Page Is Public      <-- VACİB
--   Security > Page Access Protection: Unrestricted
--   Appearance > Page Template:        Minimal (No Navigation)
--   Navigation > Navigation Menu:      gizlədin
--
-- [2] PWA-ya BAĞLAYIN
-- Edit Application Definition > Progressive Web App >
--   Offline Page:  101
-- Yadda saxladıqdan sonra service worker yenidən yaradılır.
-- -----------------------------------------------------------------


-- -----------------------------------------------------------------
-- [A] REGION
-- Body > sağ klik > Create Region
--   Name:      Offline
--   Type:      Static Content
--   Template:  Blank with Attributes
--   Aşağıdakı HTML-i Source > HTML Code sahəsinə yapışdırın
-- -----------------------------------------------------------------
/*
<div class="ev-off">
  <div class="ev-off-card">

    <p class="ev-off-logo">
      <span class="ev-off-mark">
        <svg width="22" height="22" viewBox="16 16 88 88" role="img" aria-label="Evoris">
          <rect x="16" y="16" width="16" height="88" rx="8" fill="#16302F"></rect>
          <rect x="40" y="16" width="64" height="16" rx="8" fill="#0C6E6E"></rect>
          <rect x="48" y="52" width="44" height="16" rx="8" fill="#0C6E6E"></rect>
          <rect x="40" y="88" width="64" height="16" rx="8" fill="#0C6E6E"></rect>
        </svg>
      </span>voris</p>

    <div class="ev-off-icon" aria-hidden="true">
      <svg width="64" height="64" viewBox="0 0 48 48" fill="none" stroke="#0C6E6E" stroke-width="2.6"
           stroke-linecap="round">
        <path d="M6 18a26 26 0 0 1 36 0"      opacity=".22"/>
        <path d="M12 25a18 18 0 0 1 24 0"     opacity=".45"/>
        <path d="M18 32a10 10 0 0 1 12 0"     opacity=".75"/>
        <circle cx="24" cy="39" r="1.9" fill="#0C6E6E" stroke="none"/>
        <path d="M9 9 39 39" stroke="#B3261E" stroke-width="3"/>
      </svg>
    </div>

    <h1 class="ev-off-title">İnternet bağlantısı yoxdur</h1>

    <p class="ev-off-text">
      Cihazınız şəbəkəyə qoşulu deyil. Bağlantı bərpa olunan kimi
      səhifə avtomatik yenilənəcək.
    </p>

    <button type="button" class="ev-off-btn" id="evOffRetry"
            onclick="evOffTry()">Yenidən cəhd et</button>

    <p class="ev-off-status" id="evOffStatus" role="status" aria-live="polite">
      Bağlantı gözlənilir…
    </p>

  </div>
</div>
*/


-- -----------------------------------------------------------------
-- [B] INLINE CSS
-- Page Designer > səhifənin adı (ağacın başı) > CSS > Inline
--
-- QEYD: Google Fonts @import BURADA YOXDUR və olmamalıdır —
-- offline halda yüklənmir və səhifəni ləngidir. Manrope və
-- IBM Plex Sans sistemdə varsa istifadə olunur, yoxsa sistem
-- şriftinə düşür.
-- -----------------------------------------------------------------
/*
.ev-off{
  min-height:100vh;
  margin:0;
  display:flex;
  align-items:center;
  justify-content:center;
  padding:24px;
  box-sizing:border-box;
  background:#F4F3EF;
  font-family:'IBM Plex Sans','Segoe UI',system-ui,-apple-system,sans-serif;
  color:#16302F;
}

.ev-off-card{
  width:100%;
  max-width:420px;
  background:#FFFFFF;
  border:1px solid #E3E1DB;
  border-radius:18px;
  box-shadow:0 2px 14px rgba(22,48,47,.06);
  padding:40px 32px 32px;
  text-align:center;
  box-sizing:border-box;
}

/* logotip — işarə «E» hərfinin yerinə */
.ev-off-logo{
  margin:0 0 28px;
  font-family:'Manrope','Segoe UI',system-ui,sans-serif;
  font-size:30px;
  font-weight:800;
  letter-spacing:-0.9px;
  line-height:1;
  color:#16302F;
  white-space:nowrap;
}
.ev-off-mark{
  display:inline-block;
  vertical-align:baseline;
  margin-right:2px;
}
.ev-off-mark svg{display:block;width:22px;height:22px}

.ev-off-icon{margin:0 auto 22px;width:64px;height:64px}
.ev-off-icon svg{display:block;width:100%;height:100%}

.ev-off-title{
  margin:0 0 10px;
  font-family:'Manrope','Segoe UI',system-ui,sans-serif;
  font-size:21px;
  font-weight:700;
  letter-spacing:-0.3px;
  line-height:1.3;
}

.ev-off-text{
  margin:0 0 26px;
  font-size:15px;
  line-height:1.6;
  color:#6B6A64;
}

.ev-off-btn{
  display:inline-block;
  width:100%;
  padding:13px 22px;
  border:none;
  border-radius:10px;
  background:#0C6E6E;
  color:#FFFFFF;
  font-family:'IBM Plex Sans','Segoe UI',system-ui,sans-serif;
  font-size:15px;
  font-weight:600;
  cursor:pointer;
  transition:background .15s ease;
}
.ev-off-btn:hover{background:#095857}
.ev-off-btn:focus-visible{
  outline:none;
  box-shadow:0 0 0 3px rgba(12,110,110,.28);
}
.ev-off-btn:disabled{
  background:#B9C6C5;
  cursor:default;
}

.ev-off-status{
  margin:16px 0 0;
  font-size:13px;
  color:#9C9A91;
  min-height:19px;
}
.ev-off-status.ok{color:#0C6E6E;font-weight:600}

@media (max-width:380px){
  .ev-off-card{padding:32px 22px 26px}
  .ev-off-title{font-size:19px}
}
*/


-- -----------------------------------------------------------------
-- [C] JAVASCRIPT
-- Page Designer > səhifənin adı > JavaScript >
--   "Function and Global Variable Declaration"
--
-- Bağlantı bərpa olunduqda səhifəni özü yeniləyir, ona görə
-- istifadəçinin düyməni basması şərt deyil.
-- -----------------------------------------------------------------
/*
var evOffBusy = false;

function evOffSay(msg, ok) {
  var el = document.getElementById('evOffStatus');
  if (!el) return;
  el.textContent = msg;
  el.classList.toggle('ok', !!ok);
}

function evOffBack() {
  evOffSay('Bağlantı bərpa olundu — yüklənir…', true);
  setTimeout(function () { location.reload(); }, 600);
}

function evOffTry() {
  if (evOffBusy) return;
  evOffBusy = true;

  var btn = document.getElementById('evOffRetry');
  if (btn) { btn.disabled = true; btn.textContent = 'Yoxlanılır…'; }
  evOffSay('Bağlantı yoxlanılır…');

  // navigator.onLine yalnız şəbəkə kartına baxır — real sorğu daha
  // etibarlıdır. Keş cavab verməsin deyə cache:'no-store'.
  fetch(location.pathname + '?evping=' + Date.now(), {
    method: 'HEAD',
    cache: 'no-store'
  }).then(function () {
    evOffBack();
  }).catch(function () {
    evOffBusy = false;
    if (btn) { btn.disabled = false; btn.textContent = 'Yenidən cəhd et'; }
    evOffSay('Hələ bağlantı yoxdur. Bir az sonra yenidən cəhd edin.');
  });
}

// Brauzer özü bildirdikdə
window.addEventListener('online', evOffBack);

// Fon yoxlaması — hər 5 saniyə, istifadəçi heç nə etməsə də
setInterval(function () {
  if (!evOffBusy && navigator.onLine) evOffTry();
}, 5000);

// Açılışda vəziyyəti yaz
if (navigator.onLine) {
  evOffSay('Server əlçatan deyil. Yenidən cəhd edilir…');
}
*/


-- -----------------------------------------------------------------
-- YOXLAMA
-- 1. Səhifə 101-i adi halda açın — dizayn düzgün görünürmü.
-- 2. Chrome DevTools > Network > Throttling = Offline.
-- 3. Tətbiqin hər hansı səhifəsini yeniləyin → offline səhifəsi
--    görünməlidir.
-- 4. Throttling = No throttling → səhifə 5 saniyə içində özü
--    yenilənməlidir.
--
-- Offline səhifəsi GÖRÜNMÜRSƏ:
--   DevTools > Application > Service Workers > Unregister,
--   sonra səhifəni yeniləyin. Köhnə service worker hələ də
--   yaddaşdadır — PWA parametrləri dəyişdikdən sonra bir dəfə
--   belə olur.
-- -----------------------------------------------------------------
