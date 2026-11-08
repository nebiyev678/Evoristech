/* =============================================================
   ÜMUMİ JAVASCRIPT — düyməsi olan hər səhifəyə yapışdırın
   (Təsdiqlər, Anbar, Dəstək sorğuları):
   Page Designer > səhifə adı (kök node) > JavaScript >
   "Function and Global Variable Declaration"
   ============================================================= */

/* Səhifədəki Ajax Callback prosesini çağırır, sonra səhifəni
   yeniləyir ki, region yenilənmiş məlumatı göstərsin. */
function dtAction(processName, id, value, confirmMsg) {
  if (confirmMsg && !window.confirm(confirmMsg)) return;
  apex.server.process(
    processName,
    { x01: id, x02: value },
    { dataType: 'text' }
  ).done(function () {
    location.reload();
  }).fail(function (jqXHR, textStatus, errorThrown) {
    apex.message.alert('Əməliyyat alınmadı: ' + (errorThrown || textStatus));
  });
}

/* Yalnız Anbar səhifəsi üçün: miqdar soruşur və stoku artırır. */
function dtReceive(itemId) {
  var qty = window.prompt('Qəbul edilən miqdar:');
  if (qty === null || qty === '') return;
  if (isNaN(qty) || Number(qty) <= 0) {
    apex.message.alert('Zəhmət olmasa müsbət rəqəm daxil edin.');
    return;
  }
  dtAction('RECEIVE_STOCK', itemId, qty);
}
