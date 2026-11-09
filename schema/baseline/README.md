# Baseline scripts — CI must never run these

Every script in this folder **drops and recreates its tables**:

```sql
BEGIN EXECUTE IMMEDIATE 'DROP TABLE orders CASCADE CONSTRAINTS';
EXCEPTION WHEN OTHERS THEN NULL; END;
/
```

`WHEN OTHERS THEN NULL` swallows the error when the table doesn't exist — which
is correct for their purpose and means they also run silently when it does.

They exist to build a demo workspace **from zero**: a fresh APEX instance, a new
client environment, a rebuilt sandbox. Run them by hand, knowingly, against a
schema you are willing to lose.

They are in `schema/baseline/` rather than `schema/` so that no deploy script
can glob them by accident. A pipeline that ran `schema/*.sql` would destroy the
data and report success.

## Where deployable SQL lives instead

| Folder | Contents | CI behaviour |
| --- | --- | --- |
| `db/packages/` | `CREATE OR REPLACE` only — packages, functions, views | runs every deploy |
| `db/migrations/` | forward-only, numbered, idempotent changes | runs once each |
| `schema/baseline/` | build-from-zero scripts | never |

The split exists because the two halves have opposite safety properties.
`CREATE OR REPLACE PACKAGE` is safe to run a thousand times. `CREATE TABLE` is
safe exactly once.

## Changing an existing table

Do not edit a baseline script and expect the change to reach the database — the
baseline only runs on empty schemas. Add a numbered migration in
`db/migrations/`, and update the baseline too so a from-zero build produces the
same result.
