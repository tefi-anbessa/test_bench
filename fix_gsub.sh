#!/usr/bin/env bash

set -euo pipefail

PRETEND=false

if [[ "${1:-}" == "-p" ]]; then
  PRETEND=true
  echo "Running in PRETEND mode (no files will be modified)"
  echo
fi

pattern='i18n_key\.gsub\([[:space:]]*["'\'']\/["'\''][[:space:]]*,[[:space:]]*["'\'']\.[\"'\''][[:space:]]*\)'

echo "Scanning for matches..."
rg -n "$pattern" app config test

echo
echo "Processing..."
echo

rg -l "$pattern" app config test lib | while read -r file; do
  echo "----"
  echo "File: $file"

  if $PRETEND; then
    tmp=$(mktemp)

    perl -pe '
      s{i18n_key\.gsub\(\s*["'\'']\/["'\'']\s*,\s*["'\'']\.\s*["'\'']\s*\)}{i18n_key}g
    ' "$file" > "$tmp"

    diff -u "$file" "$tmp" || true
    rm "$tmp"
  else
    perl -i -pe '
      s{i18n_key\.gsub\(\s*["'\'']\/["'\'']\s*,\s*["'\'']\.\s*["'\'']\s*\)}{i18n_key}g
    ' "$file"
  fi
done

echo
if $PRETEND; then
  echo "✔ Pretend run complete (no changes made)"
else
  echo "✔ Changes applied"
fi