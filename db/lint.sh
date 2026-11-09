#!/usr/bin/env bash
#
# Static safety checks for the SQL in this repository.
#
# These do NOT tell you the code is correct — nothing here connects to a
# database or compiles anything. They refuse the specific patterns that can
# destroy data or make a deploy unrepeatable, which is the class worth
# automating against.
#
# Usage:  db/lint.sh [base_ref]
#   base_ref  optional. When given, migrations are also checked for edits
#             against that ref (a pull request's base). Omit on a plain push.
#
# Exit 0 = clean, 1 = at least one failure.

set -uo pipefail

fail=0
note() { printf '  %s\n' "$1"; }
bad()  { printf '\nFAIL  %s\n' "$1"; fail=1; }
ok()   { printf 'ok    %s\n' "$1"; }

# GitHub Actions annotations when running in CI, plain text otherwise.
annotate() {
  if [ -n "${GITHUB_ACTIONS:-}" ]; then
    printf '::error file=%s,line=%s::%s\n' "$1" "$2" "$3"
  fi
}

sql_under_db() { find db -name '*.sql' -type f 2>/dev/null | sort; }

# ---------------------------------------------------------------------------
# 1. WHEN OTHERS THEN NULL — swallows every error, including the ones that
#    matter. This is exactly what makes schema/baseline/ dangerous; db/ must
#    never repeat it. Catch the one error you expect and re-raise the rest.
# ---------------------------------------------------------------------------
hits=$(sql_under_db | xargs -r grep -inE 'when[[:space:]]+others[[:space:]]+then[[:space:]]*null' /dev/null 2>/dev/null)
if [ -n "$hits" ]; then
  bad "WHEN OTHERS THEN NULL under db/ — swallows real errors"
  while IFS=: read -r f l rest; do
    note "$f:$l:$(echo "$rest" | sed 's/^[[:space:]]*//')"
    annotate "$f" "$l" "WHEN OTHERS THEN NULL swallows real errors. Catch the expected SQLCODE and re-raise the rest."
  done <<< "$hits"
else
  ok "no WHEN OTHERS THEN NULL under db/"
fi

# ---------------------------------------------------------------------------
# 2. DROP TABLE / TRUNCATE outside schema/baseline/. Baseline scripts build an
#    empty workspace from zero and are allowed to be destructive. Nothing a
#    pipeline or a routine deploy runs may be.
# ---------------------------------------------------------------------------
hits=$(find . -name '*.sql' -type f \
         -not -path './schema/baseline/*' \
         -not -path './.git/*' 2>/dev/null \
       | sort | xargs -r grep -inE "(drop[[:space:]]+table|truncate[[:space:]]+table)" /dev/null 2>/dev/null)
if [ -n "$hits" ]; then
  bad "destructive DDL outside schema/baseline/"
  while IFS=: read -r f l rest; do
    note "$f:$l:$(echo "$rest" | sed 's/^[[:space:]]*//')"
    annotate "$f" "$l" "DROP/TRUNCATE TABLE belongs in schema/baseline/, which CI never runs."
  done <<< "$hits"
else
  ok "no destructive DDL outside schema/baseline/"
fi

# ---------------------------------------------------------------------------
# 3. Missing / terminator. A PL/SQL block or CREATE OR REPLACE without a lone
#    slash on its own line is not submitted — SQLcl reads it and waits, and the
#    object is silently never created.
# ---------------------------------------------------------------------------
missing=""
while IFS= read -r f; do
  [ -z "$f" ] && continue
  if grep -qiE '^[[:space:]]*(begin|declare|create[[:space:]]+or[[:space:]]+replace)' "$f" 2>/dev/null; then
    grep -qE '^[[:space:]]*/[[:space:]]*$' "$f" 2>/dev/null || missing="${missing}${f}"$'\n'
  fi
done <<< "$(sql_under_db)"
if [ -n "$(echo "$missing" | tr -d '[:space:]')" ]; then
  bad "PL/SQL block or CREATE OR REPLACE with no / terminator"
  while IFS= read -r f; do
    [ -z "$f" ] && continue
    note "$f"
    annotate "$f" "1" "This file opens a PL/SQL block or CREATE OR REPLACE but has no line containing only '/'. The statement is never submitted."
  done <<< "$missing"
else
  ok "every PL/SQL block under db/ has a / terminator"
fi

# ---------------------------------------------------------------------------
# 4. db/packages/ must be re-runnable. CI executes every file there on every
#    deploy, so anything not CREATE OR REPLACE fails the second time.
# ---------------------------------------------------------------------------
hits=$(find db/packages -name '*.sql' -o -name '*.pks' -o -name '*.pkb' 2>/dev/null | sort \
       | xargs -r grep -ilE '^[[:space:]]*create[[:space:]]+(table|sequence|index)' /dev/null 2>/dev/null)
if [ -n "$hits" ]; then
  bad "db/packages/ holds something that is not re-runnable"
  while IFS= read -r f; do
    [ -z "$f" ] && continue
    note "$f — CREATE TABLE/SEQUENCE/INDEX belongs in db/migrations/"
    annotate "$f" "1" "db/packages/ runs on every deploy, so it must contain only CREATE OR REPLACE. Move this to db/migrations/."
  done <<< "$hits"
else
  ok "db/packages/ is re-runnable"
fi

# ---------------------------------------------------------------------------
# 5. Applied migrations are immutable. CI cannot know what the database has
#    run, but it can refuse an EDIT to an existing migration: change it and
#    environments silently diverge. Add a new numbered file instead.
#    Only checkable when a base ref is known (a pull request).
# ---------------------------------------------------------------------------
base="${1:-}"
if [ -n "$base" ] && git rev-parse --verify --quiet "$base" >/dev/null 2>&1; then
  edited=$(git diff --name-status "$base"...HEAD -- db/migrations/ 2>/dev/null | awk '$1=="M"{print $2}')
  if [ -n "$edited" ]; then
    bad "an existing migration was modified"
    while IFS= read -r f; do
      [ -z "$f" ] && continue
      note "$f — add a new numbered migration instead"
      annotate "$f" "1" "Migrations are immutable once applied. Add a new numbered file rather than editing this one."
    done <<< "$edited"
  else
    ok "no existing migration was modified"
  fi
else
  ok "migration-immutability check skipped (no base ref)"
fi

echo
if [ "$fail" -ne 0 ]; then
  echo "SQL safety lint FAILED"
  exit 1
fi
echo "SQL safety lint passed"
