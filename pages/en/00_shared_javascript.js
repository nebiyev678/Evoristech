/* =============================================================
   SHARED JAVASCRIPT — paste into EACH page that has buttons
   (Approvals, Inventory, Helpdesk):
   Page Designer > page name (root node) > JavaScript >
   "Function and Global Variable Declaration"
   ============================================================= */

/* Calls an Ajax Callback process on the page, then reloads
   so the region shows the updated data. */
function dtAction(processName, id, value, confirmMsg) {
  if (confirmMsg && !window.confirm(confirmMsg)) return;
  apex.server.process(
    processName,
    { x01: id, x02: value },
    { dataType: 'text' }
  ).done(function () {
    location.reload();
  }).fail(function (jqXHR, textStatus, errorThrown) {
    apex.message.alert('Action failed: ' + (errorThrown || textStatus));
  });
}

/* Inventory page only: asks for a quantity, then receives stock. */
function dtReceive(itemId) {
  var qty = window.prompt('Quantity received:');
  if (qty === null || qty === '') return;
  if (isNaN(qty) || Number(qty) <= 0) {
    apex.message.alert('Please enter a positive number.');
    return;
  }
  dtAction('RECEIVE_STOCK', itemId, qty);
}
