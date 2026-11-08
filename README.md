# Evoris Tech — APEX application repository

Source of truth for the demo and client applications. `CLAUDE.md` holds the
conventions; read it first.

## Layout

```
export/     APEX application exports — one file per page (apex export -split)
schema/     Tables, indexes, seed data, build checklists
static/     custom.css / custom.js → upload to Static Application Files
pages/az/   Live page code (Azerbaijani) for Dynamic Content regions
pages/en/   English originals, kept for reference
brand/      Logo SVGs and the APEX login-page branding script
docs/       Build guides and setup notes
sales/      Target client list
```

## Workflow

**Pulling the app down** — the export is the record of what is actually built.

With SQLcl (ATP/ADW workload only):

```bash
sql nebiyev678/password@connect_string
SQL> apex export -applicationid 102 -split -dir export/
```

One file per page means a page change is a readable diff instead of one
40,000-line blob.

Without direct SQL access (APEX workload): App Builder → App 102 →
Export / Import → Export → Single File, save into `export/`.

**Pushing changes up**

| What | Where it goes |
| --- | --- |
| `static/custom.css`, `static/custom.js` | Shared Components → Static Application Files |
| `schema/*.sql` | SQL Workshop → SQL Scripts, or SQLcl |
| `pages/az/*.sql` | The Source → PL/SQL Function Body of the named region |
| `brand/apex_login_logo.sql` | Page 99999 — sections marked `[A]`–`[G]` go to different fields |

The page files are not importable exports. Each contains the PL/SQL for one
region, with the target page and region named at the top.

## Page map

| File | Page | Ajax process |
| --- | --- | --- |
| `01_tesdiqler.sql` | Təsdiqlər (approvals) | `PO_DECISION` |
| `02_anbar_budce.sql` | Anbar və büdcə | `RECEIVE_STOCK` |
| `03_idare_paneli.sql` | İdarə paneli | — read-only |
| `04_destek_sorgulari.sql` | Dəstək sorğuları | `TICKET_STATUS` |
| `05_musteri_portali.sql` | Müştəri portalı | — read-only |
| `06_ai_emr_setri.sql` | AI əmr sətri | `AI_COMMAND` |
| `07_ai_tehlil.sql` | AI təhlil | `AI_ANALIZ` |
| `08_ai_merkez.sql` | AI mərkəz (06 + 07 merged) | `AI_ASSISTANT` |
| `09_destek_drag_drop.sql` | Replaces 04 — adds drag & drop | `TICKET_STATUS` |
| `10_yeni_sorgu_axini.sql` | 3-step ticket wizard | `CREATE_TICKET` |

## Setting up direct database access

Autonomous Database → Network → Mutual TLS = *Not required*, add your IP to the
access control list. Then SQLcl connects with a plain TLS string, no wallet.

Oracle's SQLcl MCP server gives an AI client direct query and compile access:

```json
{
  "mcpServers": {
    "sqlcl": { "command": "C:\\sqlcl\\bin\\sql.exe", "args": ["-mcp"] }
  }
}
```

Read Oracle's "Configuring restrict levels for SQLcl MCP Server" first, and
connect as a dedicated dev user — never `ADMIN`.
