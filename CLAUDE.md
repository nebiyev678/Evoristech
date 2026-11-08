# Evoris Tech — Oracle APEX conventions

Read this before writing any code in this repo.

## Environment

| | |
| --- | --- |
| APEX | 26.1.4 |
| Hosting | Oracle Cloud (OCI) Autonomous Database |
| Workspace | `NEBIYEV678` |
| Parsing schema | `NEBIYEV678` |
| App 102 | Inventory & Budget Tracker |
| Login page | 99999 |
| UI language | Azerbaijani |
| Currency | AZN (manat, `₼`), space thousands separator: `124 500 ₼` |

**Separate from this:** the work codebase is schema `GAIA` on **APEX 20.2**
(`APEX_200200`) and Oracle 19c. Different instance, different rules — anything
version-dependent (`APEX_AI`, native `JSON` datatype, identity columns) must be
checked against 20.2/19c there, not assumed from 26.1.

## Brand

```
teal        #0C6E6E   primary, buttons, accents
dark        #16302F   text, dark backgrounds
light teal  #4FB3B3   accents ON dark backgrounds only
ivory       #F4F3EF   page background
muted       #6B6A64   secondary text
border      #E3E1DB   borders, dividers
```

Fonts: **Manrope** 700/800 (display, headings, logo) · **IBM Plex Sans**
400/500/600 (body, tables, forms).

The logo mark substitutes for the letter E: `[mark]voris`. Short form only —
no "Tech" in the lockup. See `brand/`.

## Hard rules

1. **Static files use `#APP_FILES#`, never `#APP_IMAGES#`.** Static Application
   Files are referenced as `#APP_FILES#custom.css`. `#APP_IMAGES#` is legacy and
   silently fails.
2. **Escape every user-entered value** in a Dynamic Content region with
   `apex_escape.html()`. Hand-built HTML has no automatic escaping — a missed
   call is a stored XSS hole.
3. **`apex_application.g_x01`..`g_x10` are untrusted.** They are always
   `VARCHAR2`, always from the browser. Whitelist-validate server-side in every
   Ajax Callback before using them:
   ```sql
   if l_status in ('NEW','IN_PROGRESS','WAITING','RESOLVED') then
   ```
   A hidden button is still callable from the console — authorization goes on the
   process, not only on the button.
4. **The AI model never generates SQL that is executed.** It classifies intent
   into a fixed action set and returns JSON. All arithmetic happens in SQL.
   See `pages/az/06_ai_emr_setri.sql` for the pattern.
5. **Page links use `apex_page.get_url(p_page => N)`**, never a hardcoded
   `f?p=`||:APP_ID||':3:'||:APP_SESSION, and never a `.html` filename left over
   from the design mockups.
6. **The Groq model name lives in a settings table**, not a literal. Groq
   decommissioned `llama-3.3-70b-versatile` on 2026-08-16; current models are
   `openai/gpt-oss-120b` and `openai/gpt-oss-20b`. The next retirement should be
   an `UPDATE`, not a code change across five pages.
7. **Never fabricate an APEX export file.** Hand-written `wwv_flow_imp.id(...)`
   calls can collide with and overwrite existing workspace objects. Build via the
   wizards, then App Builder → Export. That genuine export is the install file.

## Known gotchas, already paid for

- **CSS Classes** in Page Designer is a free-text field, not a dropdown. Type the
  class name.
- A `kpi-card` class cannot style an APEX **page item**. Use Hidden items plus a
  Static Content region with `&P3_PENDING_COUNT.` substitution.
- `max-width` alone does not centre a block. Needs
  `margin:0 auto; width:100%; box-sizing:border-box`.
- A login-page region renders **outside** the card unless
  **Layout → Parent Region = Login** is set.
- Outbound HTTP from OCI Autonomous needs a `DBMS_NETWORK_ACL_ADMIN` entry. A
  bare `ORA-29273` tells you nothing until you call
  `utl_http.set_detailed_excp_support(true)` and read
  `utl_http.get_detailed_sqlerrm`.
- `Content-Length` must be **bytes**, not characters. `DBMS_LOB.GETLENGTH` returns
  characters and truncates UTF-8 JSON mid-byte. Either omit the header and let
  `APEX_WEB_SERVICE` compute it, or convert CLOB→BLOB with
  `DBMS_LOB.CONVERTTOBLOB` and `UTL_HTTP.WRITE_RAW`.
- `JSON_OBJECT_T.append()` stores a **reference**, not a copy. Construct the
  object inside the loop or every element is the last one.
- `ORA-00054` is "resource busy", not "system closing". INACTIVE sessions still
  hold locks when they have an open transaction — join `v$transaction`.

## Technical debt

The list pages (Approvals, Inventory, Tickets) are **Dynamic Content regions** —
PL/SQL returning a CLOB of HTML. They have no pagination, sorting, filtering or
export, and Theme Roller cannot style them.

Converting them to **Interactive Reports** with the badge markup moved into an
HTML Expression is the planned fix:

```
<span class="ev-badge ev-badge--#STATUS_CLASS#">#STATUS_LABEL#</span>
```

The AI pages, the kanban and the wizard stay as Dynamic Content — they are
genuinely custom layouts, not tables.

## Not yet built

- Roles via APEX Access Control (`ADMIN`, `APPROVER`, `VIEWER`) with
  authorization schemes on the Ajax processes
- Audit columns (`CREATED_BY`, `CREATED_ON`, `UPDATED_BY`, `UPDATED_ON`) plus
  triggers using `nvl(v('APP_USER'), user)`
- An application-wide error-handling function mapping constraint names to
  Azerbaijani sentences
- `APEX_MAIL` notifications on approve/reject and ticket assignment
- Comment threads and file attachments — the two features clients ask for first
- SSO via OAuth2 / OpenID Connect against Microsoft 365
