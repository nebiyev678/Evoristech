-- =================================================================
-- EVORIS TECH LOGOSU — APEX GİRİŞ SƏHİFƏSİ (Səhifə 99999)
--
-- İşarə «E» hərfinin yerinə keçir: [işarə]voris Tech
-- Inline SVG-dir — fayl yükləmək və #APP_FILES# istinadı lazım deyil.
-- =================================================================


-- -----------------------------------------------------------------
-- [A] LOGO BÖLGƏSİ
-- Page Designer > Səhifə 99999 > Body > sağ klik > Create Region
--   Name:        Logo
--   Type:        Static Content
--   Layout > Parent Region:  Login       <-- VACİB
--   Layout > Sequence:       5           (digər elementlərdən əvvəl)
--   Appearance > Template:   Blank with Attributes
--
-- «Parent Region» təyin edilmədikdə logo kartdan KƏNARDA,
-- ayrıca zolaqda görünür. Bu sahə Layout bölməsindədir və
-- açılan siyahıdan giriş bölgəsinin adı seçilir.
-- Aşağıdakı HTML-i Source > HTML Code sahəsinə yapışdırın
-- -----------------------------------------------------------------
/*
<p class="ev-logo"><span class="ev-mark-wrap"><svg class="ev-mark" viewBox="16 16 88 88" role="img" aria-label="E"><rect x="16" y="16" width="16" height="88" rx="8" fill="#16302F"></rect><rect x="40" y="16" width="64" height="16" rx="8" fill="#0C6E6E"></rect><rect x="48" y="52" width="44" height="16" rx="8" fill="#0C6E6E"></rect><rect x="40" y="88" width="64" height="16" rx="8" fill="#0C6E6E"></rect></svg></span>voris</p>
*/


-- -----------------------------------------------------------------
-- [B] CSS
-- Page Designer > səhifənin adına klik (sol ağacın başı) >
-- sağ paneldə: CSS > Inline
-- -----------------------------------------------------------------
/*
@import url('https://fonts.googleapis.com/css2?family=Manrope:wght@700;800&family=IBM+Plex+Sans:wght@400;500;600&display=swap');

.t-PageBody--login{
  background:#F4F3EF;
  font-family:'IBM Plex Sans',system-ui,sans-serif;
}

/* Logotip: işarə mətn xəttinin üstündə dayanır */
.ev-logo{
  margin:0 0 28px;
  text-align:center;
  font-family:'Manrope',system-ui,sans-serif;
  font-size:42px;
  font-weight:800;
  letter-spacing:-1.2px;
  line-height:1;
  color:#16302F;
  white-space:nowrap;
}
.ev-mark-wrap{
  display:inline-block;      /* alt kənarı mətn xəttinə oturur */
  vertical-align:baseline;
  margin-right:2px;
}
.ev-mark{display:block;width:30px;height:30px}

/* Giriş kartı */
.t-Login-region{
  border:1px solid #E3E1DB;
  border-radius:18px;
  box-shadow:0 2px 14px rgba(22,48,47,.06);
}
.t-Login-region .t-Login-logo{display:none}   /* APEX-in öz loqo yeri */

.t-Login-region .t-Button--hot,
.t-PageBody--login .t-Button--hot{
  background-color:#0C6E6E;
  border-color:#0C6E6E;
  font-weight:700;
}
.t-Login-region .t-Button--hot:hover,
.t-PageBody--login .t-Button--hot:hover{
  background-color:#095857;
  border-color:#095857;
}

.t-PageBody--login .t-Form-fieldContainer .t-Form-inputContainer input:focus{
  border-color:#0C6E6E;
  box-shadow:0 0 0 3px rgba(12,110,110,.12);
}

@media (max-width:480px){
  .ev-logo{font-size:34px;letter-spacing:-0.9px}
  .ev-mark{width:24px;height:24px}
}
*/


-- -----------------------------------------------------------------
-- [C] TÜND FONLU VARİANT (istəyə bağlı)
-- [B]-dəki .t-PageBody--login qaydasını bununla əvəz edin və
-- bölgədəki SVG rənglərini #FFFFFF / #4FB3B3 ilə dəyişin
-- -----------------------------------------------------------------
/*
.t-PageBody--login{
  background:#16302F;
  font-family:'IBM Plex Sans',system-ui,sans-serif;
}
.ev-logo{color:#FFFFFF}
.t-Login-region{
  background:#FFFFFF;
  border:none;
  border-radius:18px;
  box-shadow:0 8px 32px rgba(0,0,0,.28);
}
*/


-- -----------------------------------------------------------------
-- [D] FAVICON
-- Edit Application Definition > User Interface > Favicon HTML
-- Yoxdursa: Səhifə 99999 > Page Attributes > HTML Header
-- -----------------------------------------------------------------
/*
<link rel="icon" type="image/svg+xml" href="data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 120 120'%3E%3Crect x='16' y='16' width='16' height='88' rx='8' fill='%2316302F'/%3E%3Crect x='40' y='16' width='64' height='16' rx='8' fill='%230C6E6E'/%3E%3Crect x='48' y='52' width='44' height='16' rx='8' fill='%230C6E6E'/%3E%3Crect x='40' y='88' width='64' height='16' rx='8' fill='%230C6E6E'/%3E%3C/svg%3E">
*/


-- -----------------------------------------------------------------
-- [E] NAVİQASİYA PANELİNDƏKİ LOGO (giriş etdikdən sonra)
-- Edit Application Definition > User Interface > Logo
--   Logo Type: Custom (versiyanızda varsa) > aşağıdakı HTML
-- Custom yoxdursa: Logo Type = Image, evoris-mark.svg faylını
-- Static Application Files-a yükləyin: #APP_FILES#evoris-mark.svg
-- -----------------------------------------------------------------
/*
<span style="font-family:'Manrope',sans-serif;font-size:20px;font-weight:800;letter-spacing:-0.4px;color:#FFFFFF;white-space:nowrap"><span style="display:inline-block;vertical-align:baseline;margin-right:1px"><svg viewBox="16 16 88 88" role="img" aria-label="E" style="display:block;width:15px;height:15px"><rect x="16" y="16" width="16" height="88" rx="8" fill="#FFFFFF"></rect><rect x="40" y="16" width="64" height="16" rx="8" fill="#4FB3B3"></rect><rect x="48" y="52" width="44" height="16" rx="8" fill="#4FB3B3"></rect><rect x="40" y="88" width="64" height="16" rx="8" fill="#4FB3B3"></rect></svg></span>voris</span>
*/


-- -----------------------------------------------------------------
-- [F] EHTİYAT VARİANT — «Parent Region» işləmirsə
-- Logo hələ də kartdan kənarda qalırsa, bu JavaScript-i
-- Page Designer > səhifə adı > JavaScript >
-- "Execute when Page Loads" bölməsinə əlavə edin.
-- Logo elementini kartın başına köçürür.
-- -----------------------------------------------------------------
/*
(function () {
  var logo = document.querySelector('.ev-logo');
  var card = document.querySelector('.t-Login-region .t-Region-body')
          || document.querySelector('.t-Login-region');
  if (logo && card && !card.contains(logo)) {
    card.insertBefore(logo, card.firstChild);
  }
})();
*/


-- -----------------------------------------------------------------
-- [G] NAVİQASİYA PANELİNDƏKİ «Logo» YAZISI
-- Ekranın sol yuxarısındaki «Logo» mətni APEX-in standart
-- yer tutucusudur. Giriş səhifəsində gizlətmək üçün [B]-yə əlavə edin:
-- -----------------------------------------------------------------
/*
.t-PageBody--login .t-Header,
.t-PageBody--login .t-Header-logo{display:none}
*/
-- Və ya tətbiqin hər yerində dəyişmək üçün:
-- Edit Application Definition > User Interface > Logo  ([E] bölməsi)


-- -----------------------------------------------------------------
-- QEYD — nizamlama
-- İşarə mətn xəttindən bir qədər yuxarı və ya aşağı görünürsə,
-- .ev-mark-wrap qaydasına kiçik düzəliş əlavə edin:
--   position:relative; top:1px;    (aşağı salır)
--   position:relative; top:-1px;   (yuxarı qaldırır)
-- Şrift metrikası brauzerlər arasında bir-iki piksel fərq edə bilər.
-- -----------------------------------------------------------------
