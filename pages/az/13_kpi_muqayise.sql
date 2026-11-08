-- =================================================================
-- KPI KARTLARINA MÜQAYİSƏ GÖSTƏRİCİLƏRİ
-- App 104 · Səhifə 2 (Dashboard) · «Dashboard» regionu
--
-- 03_idare_paneli.sql faylındakı declare bloku və «Göstərici
-- kartları» hissəsini bu versiya ilə əvəz edin.
--
-- VACİB QƏRAR
-- Gəlir və İcra faizi — dövr müqayisəsi mümkündür (30 gün / əvvəlki 30 gün).
-- Açıq sifarişlər və Vaxtı keçmiş — bunlar CARİ VƏZİYYƏTdir, tarixçə
-- cədvəli yoxdur. «Keçən həftəyə görə» göstərmək üçün məlumat yoxdur,
-- ona görə uydurmaq əvəzinə faydalı kontekst verilir:
--   Açıq sifarişlər  → bu həftə neçəsi yenidir
--   Vaxtı keçmiş     → risk altındakı məbləğ
-- Hesablaya bilmədiyiniz trendi müştəriyə göstərməyin.
-- =================================================================


-- -----------------------------------------------------------------
-- [A] DECLARE BLOKU — mövcud declare hissəsini bununla əvəz edin
-- -----------------------------------------------------------------
/*
declare
  l_h        clob;
  l_max      number;

  -- cari 30 gün
  l_rev_cur   number;  l_rate_cur number;
  -- əvvəlki 30 gün (30-60 gün arası)
  l_rev_prv   number;  l_rate_prv number;
  -- cari vəziyyət
  l_open      number;  l_open_new number;
  l_pastdue   number;  l_pd_amount number;

  procedure p(s varchar2) is begin l_h := l_h || s; end;

  -- Dəyişmə faizini hazır HTML kimi qaytarır
  function delta(p_cur number, p_prv number) return varchar2 is
    l_pct number;
  begin
    if p_prv is null or p_prv = 0 then
      return '<div class="dt-kpi-sub dt-flat">müqayisə üçün məlumat yoxdur</div>';
    end if;
    l_pct := round(100 * (p_cur - p_prv) / p_prv, 1);
    return '<div class="dt-kpi-sub '||
           case when l_pct > 0 then 'dt-up' when l_pct < 0 then 'dt-down'
                else 'dt-flat' end||'">'||
           case when l_pct > 0 then '&#9650; ' when l_pct < 0 then '&#9660; '
                else '&#8226; ' end||
           trim(to_char(abs(l_pct),'FM99990D0'))||'% keçən aya görə</div>';
  end delta;
begin
  select
    -- cari 30 gün
    nvl(sum(case when status <> 'CANCELLED'
                  and order_date >= trunc(sysdate) - 30 then amount end), 0),
    round(100 * sum(case when status = 'FULFILLED'
                          and order_date >= trunc(sysdate) - 30 then 1 else 0 end)
          / nullif(sum(case when status <> 'CANCELLED'
                             and order_date >= trunc(sysdate) - 30 then 1 else 0 end), 0), 1),
    -- əvvəlki 30 gün
    nvl(sum(case when status <> 'CANCELLED'
                  and order_date >= trunc(sysdate) - 60
                  and order_date <  trunc(sysdate) - 30 then amount end), 0),
    round(100 * sum(case when status = 'FULFILLED'
                          and order_date >= trunc(sysdate) - 60
                          and order_date <  trunc(sysdate) - 30 then 1 else 0 end)
          / nullif(sum(case when status <> 'CANCELLED'
                             and order_date >= trunc(sysdate) - 60
                             and order_date <  trunc(sysdate) - 30 then 1 else 0 end), 0), 1),
    -- cari vəziyyət
    sum(case when status = 'OPEN' then 1 else 0 end),
    sum(case when status = 'OPEN'
              and order_date >= trunc(sysdate) - 7 then 1 else 0 end),
    sum(case when status = 'PAST_DUE' then 1 else 0 end),
    nvl(sum(case when status = 'PAST_DUE' then amount end), 0)
  into l_rev_cur, l_rate_cur, l_rev_prv, l_rate_prv,
       l_open, l_open_new, l_pastdue, l_pd_amount
  from orders;

  select nullif(max(total_revenue),0) into l_max from v_region_summary;

  p('<div class="dt">');
*/


-- -----------------------------------------------------------------
-- [B] GÖSTƏRİCİ KARTLARI — «-- Göstərici kartları» hissəsini əvəz edin
-- -----------------------------------------------------------------
/*
  p('<div class="dt-kpis">');

  -- 1. Gəlir (30 gün) — həqiqi dövr müqayisəsi
  p('<div class="dt-kpi">');
  p('  <div class="dt-kpi-label">Gəlir · 30 gün</div>');
  p('  <div class="dt-kpi-value">'||to_char(l_rev_cur,'FM999G999G990')||' &#8380;</div>');
  p(delta(l_rev_cur, l_rev_prv));
  p('</div>');

  -- 2. Açıq sifarişlər — cari vəziyyət + bu həftə yenilər
  p('<div class="dt-kpi">');
  p('  <div class="dt-kpi-label">Açıq sifarişlər</div>');
  p('  <div class="dt-kpi-value">'||l_open||'</div>');
  p('  <div class="dt-kpi-sub dt-flat">'||
      case when l_open_new > 0
           then 'bu həftə '||l_open_new||' yeni'
           else 'bu həftə yeni yoxdur' end||'</div>');
  p('</div>');

  -- 3. Vaxtı keçmiş — risk altındakı məbləğ
  p('<div class="dt-kpi">');
  p('  <div class="dt-kpi-label">Vaxtı keçmiş</div>');
  p('  <div class="dt-kpi-value '||case when l_pastdue > 0 then 'dt-red' end||'">'||l_pastdue||'</div>');
  p('  <div class="dt-kpi-sub '||case when l_pastdue > 0 then 'dt-down' else 'dt-flat' end||'">'||
      case when l_pastdue > 0
           then '&#9888; '||to_char(l_pd_amount,'FM999G999G990')||' &#8380; risk altında'
           else 'gecikmə yoxdur' end||'</div>');
  p('</div>');

  -- 4. İcra faizi (30 gün) — həqiqi dövr müqayisəsi
  p('<div class="dt-kpi">');
  p('  <div class="dt-kpi-label">İcra faizi · 30 gün</div>');
  p('  <div class="dt-kpi-value dt-green">'||nvl(to_char(l_rate_cur),'0')||'%</div>');
  p(delta(l_rate_cur, l_rate_prv));
  p('</div>');

  p('</div>');
*/


-- -----------------------------------------------------------------
-- [C] CSS — Səhifə 2 > CSS > Inline (mövcud blokun sonuna)
-- -----------------------------------------------------------------
/*
.dt-kpi-sub{
  margin-top:6px;
  font-size:12px;
  font-weight:600;
  letter-spacing:.1px;
  display:flex;
  align-items:center;
  gap:4px;
  white-space:nowrap;
}
.dt-up   { color:#1A7F5A }   /* artım — yaxşı */
.dt-down { color:#B3261E }   /* azalma — pis */
.dt-flat { color:#9C9A91 }   /* neytral kontekst */

@media (max-width:640px){
  .dt-kpi-sub{font-size:11px}
}
*/


-- -----------------------------------------------------------------
-- [D] İSTƏYƏ BAĞLI — Gəlir kartında kiçik qrafik (sparkline)
--
-- [A]-dakı declare-ə əlavə edin:
--     l_spark   varchar2(4000);
--     l_smax    number;
-- və [B]-də 1-ci kartda dəyərdən sonra p(l_spark) çağırın.
-- -----------------------------------------------------------------
/*
  -- son 6 ayın aylıq gəliri — sadə SVG xətt qrafiki
  select max(m_rev) into l_smax from (
    select sum(amount) m_rev from orders
     where status <> 'CANCELLED'
       and order_date >= add_months(trunc(sysdate,'MM'), -5)
     group by trunc(order_date,'MM'));

  l_spark := '';
  if l_smax is not null and l_smax > 0 then
    declare
      l_i   pls_integer := 0;
      l_pts varchar2(2000) := '';
    begin
      for m in (
        select trunc(order_date,'MM') mth, sum(amount) rev
          from orders
         where status <> 'CANCELLED'
           and order_date >= add_months(trunc(sysdate,'MM'), -5)
         group by trunc(order_date,'MM')
         order by 1
      ) loop
        l_pts := l_pts || case when l_i > 0 then ' ' end ||
                 to_char(l_i * 20) || ',' ||
                 to_char(round(28 - 24 * m.rev / l_smax));
        l_i := l_i + 1;
      end loop;

      if l_i > 1 then
        l_spark :=
          '<svg class="dt-spark" viewBox="0 0 '||to_char((l_i-1)*20)||' 30" '||
          'preserveAspectRatio="none" aria-hidden="true">'||
          '<polyline points="'||l_pts||'" fill="none" stroke="#0C6E6E" '||
          'stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>'||
          '</svg>';
      end if;
    end;
  end if;
*/

-- [D] üçün CSS:
/*
.dt-spark{
  display:block;
  width:100%;
  height:30px;
  margin-top:8px;
  overflow:visible;
}
*/


-- -----------------------------------------------------------------
-- YOXLAMA
-- 1. Səhifəni açın — hər kartın altında ikinci sətir görünməlidir
-- 2. Az məlumatla «müqayisə üçün məlumat yoxdur» yazılır — bu düzgündür,
--    uydurma faiz göstərmir
-- 3. 130 sifarişlik seed-dən sonra həqiqi faizlər görünəcək
--
-- QEYD: 6 sifarişlə bu kartlar hələ zəif görünəcək. Müqayisə
-- göstəriciləri yalnız kifayət qədər məlumat olduqda mənalıdır —
-- seed məlumatı bu işin digər yarısıdır.
-- -----------------------------------------------------------------
