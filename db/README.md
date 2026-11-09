# db/ — what the deploy pipeline runs

Everything here is safe for CI to execute against the live Autonomous Database.
Anything that is not safe belongs in `schema/baseline/`, which CI never touches.

## `packages/`

`CREATE OR REPLACE` only — packages, standalone functions, views, triggers.
Idempotent by construction, so every deploy runs every file. Order matters where
there are dependencies; `db/deploy.sql` calls them explicitly rather than
globbing, so a new file is not deployed until it is listed there.

Package specs (`.pks`) before bodies (`.pkb`).

## `migrations/`

Forward-only, numbered, run once each: `001_…`, `002_…`. A migration that has
already been applied is skipped, recorded in the `evoris_migrations` table that
`000_tracking.sql` creates.

Rules:

- **Never edit a migration that has been applied anywhere.** Write a new one.
- Catch the one error you expect and re-raise everything else. `WHEN OTHERS
  THEN NULL` is what makes the baseline scripts dangerous; do not repeat it here.
  For "object already exists" that means `if sqlcode != -955 then raise; end if;`.
- No `DROP TABLE`. A column that must go is dropped in its own migration, named
  so that the intent is obvious in `git log`.

## `deploy.sql`

The entry point CI calls. Starts with `whenever sqlerror exit failure` — without
it SQLcl reports success after a failed statement and the pipeline goes green on
a broken deploy. Ends by listing any object left `INVALID`, which is a cheap
smoke test.

## Order

Database objects deploy **before** the APEX application, because the app's
regions call them. Reverse it and the first page load after a deploy throws.
