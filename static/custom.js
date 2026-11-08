/* ============================================================
   Evoris Tech — shared application JavaScript
   App 104 (Executive Dashboard) · APEX 26.1.5

   INSTALL
     1. Shared Components > Static Application Files > Upload
        this file as  custom.js
     2. Edit Application Definition > User Interface >
        JavaScript > File URLs:
            #APP_FILES#custom.js
        (#APP_FILES#, never #APP_IMAGES# — that prefix is legacy
         and fails silently)

   LOAD ORDER — important
     File URLs load in <head>. A page's "Function and Global
     Variable Declaration" runs AFTER that, so a function defined
     on a page OVERRIDES the one here. Adding this file therefore
     changes nothing until the duplicated copies are removed from
     the pages. See REMOVE-FROM-PAGES at the bottom.

   WHAT LIVES HERE
     Only code used by more than one page, or reusable across
     client apps. Page-specific flows stay on their page:
       page 2  dtAi / dtAnaliz / dtAiSet   (AI regions)
       page 4  wz*                          (ticket wizard)
   ============================================================ */

/* ------------------------------------------------------------
   esc — HTML-escape a string before putting it in innerHTML.
   Client-side mirror of apex_escape.html(). Anything a user
   typed goes through this, every time, no exceptions.
   ------------------------------------------------------------ */
function esc(s) {
  if (s === null || s === undefined) return '';
  return String(s)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#39;');
}

/* ------------------------------------------------------------
   dtAjax — one place for calling an Ajax Callback process.
   Returns the apex.server.process promise so callers chain
   .done() / .fail() themselves.
   ------------------------------------------------------------ */
function dtAjax(processName, data) {
  return apex.server.process(processName, data || {}, { dataType: 'text' });
}

/* ------------------------------------------------------------
   dtAction — call a process, then reload so the region redraws.
   Used by the ticket status buttons and the approval buttons.
   ------------------------------------------------------------ */
function dtAction(processName, id, value, confirmMsg) {
  if (confirmMsg && !window.confirm(confirmMsg)) return;
  dtAjax(processName, { x01: id, x02: value })
    .done(function () {
      location.reload();
    })
    .fail(function (jqXHR, textStatus, errorThrown) {
      apex.message.alert('Əməliyyat alınmadı: ' + (errorThrown || textStatus));
    });
}

/* ------------------------------------------------------------
   KANBAN — drag and drop between status columns.

   Expected markup:
     .kb-col[data-status="NEW"]      the column
       [data-count="NEW"]            the count badge
       .kb-body                      the drop target body
         .kb-card[data-id="123"]     a draggable card
           .kb-btn                   its action button

   Optimistic: the card moves and the counts change immediately,
   then roll back if the server rejects it.
   ------------------------------------------------------------ */
var kbDragged = null;
var kbFromCol = null;

function kbStart(ev) {
  kbDragged = ev.currentTarget;
  kbFromCol = kbDragged.closest('.kb-col');
  kbDragged.classList.add('dragging');
  ev.dataTransfer.effectAllowed = 'move';
  ev.dataTransfer.setData('text/plain', kbDragged.dataset.id);
}

function kbEnd() {
  if (kbDragged) kbDragged.classList.remove('dragging');
}

function kbOver(ev) {
  if (!kbDragged) return;
  ev.preventDefault();               // without this, drop never fires
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
  if (newStatus === oldStatus) {      // same column — nothing to do
    kbDragged = null;
    kbFromCol = null;
    return;
  }

  var id   = kbDragged.dataset.id;
  var card = kbDragged;
  var from = kbFromCol;

  col.querySelector('.kb-body').appendChild(card);
  kbRecolor(card, newStatus);
  kbCount(oldStatus, -1);
  kbCount(newStatus, 1);
  card.classList.add('saving');

  dtAjax('TICKET_STATUS', { x01: id, x02: newStatus })
    .done(function () {
      card.classList.remove('saving');
      kbButton(card, newStatus);
    })
    .fail(function (jqXHR, textStatus, errorThrown) {
      card.classList.remove('saving');
      if (from) {
        from.querySelector('.kb-body').appendChild(card);
        kbRecolor(card, oldStatus);
        kbCount(newStatus, -1);
        kbCount(oldStatus, 1);
        kbButton(card, oldStatus);
      }
      apex.message.alert('Status dəyişdirilə bilmədi: ' +
                         (errorThrown || textStatus));
    });

  kbDragged = null;
  kbFromCol = null;
}

function kbCount(status, delta) {
  if (!status) return;
  var el = document.querySelector('[data-count="' + status + '"]');
  if (el) el.textContent = Math.max(0, parseInt(el.textContent, 10) + delta);
}

function kbRecolor(card, status) {
  card.classList.toggle('done', status === 'RESOLVED');
}

/* Relabel a card's action button for its new column.
   The old version only had a WAITING entry, so a card dropped
   into NEW, IN_PROGRESS or RESOLVED kept a stale button label. */
function kbButton(card, status) {
  var map = {
    'NEW':         ['Başla',    'IN_PROGRESS'],
    'IN_PROGRESS': ['Bitir',    'RESOLVED'],
    'WAITING':     ['Davam et', 'IN_PROGRESS'],
    'RESOLVED':    [null,       null]
  };
  var btn = card.querySelector('.kb-btn');
  if (!btn) return;
  var cfg = map[status];
  if (!cfg || !cfg[0]) {
    btn.hidden = true;
    return;
  }
  btn.hidden = false;
  btn.textContent = cfg[0];
  btn.setAttribute('onclick',
    "dtAction('TICKET_STATUS'," + card.dataset.id + ",'" + cfg[1] + "')");
}

/* ============================================================
   REMOVE-FROM-PAGES — do this one page at a time, testing after
   each. Until a page's copy is deleted it silently overrides the
   version above, so nothing breaks while you work through it.

   Page 3 (Helpdesk Page) > JavaScript >
     "Function and Global Variable Declaration" — delete:
       dtAction, dtReceive, kbDragged, kbFromCol, kbStart, kbEnd,
       kbOver, kbLeave, kbDrop, kbCount, kbRecolor, kbButton
     That is the whole block. dtReceive calls RECEIVE_STOCK, a
     process that exists in app 102 and NOT in app 104 — it is
     dead code here; it has not been carried over.

   Page 4 (Ticket Flow) — delete only:
       function esc(s) { ... }
     Keep every wz* function; they are page-specific.

   Page 2 (Dashboard) — nothing to delete, and worth a tidy:
     the commented-out old dtAi block at the top can go.
   ============================================================ */
