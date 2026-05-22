#!/usr/bin/env bash

set -euo pipefail

PRETEND=false

if [[ "${1:-}" == "-p" ]]; then
  PRETEND=true
  echo "Running in PRETEND mode (no files will be modified)"
fi

# Find relevant files
files=$(rg -l 'activerecord[^"]*electrical\.' app config test || true)

if [[ -z "$files" ]]; then
  echo "No matches found."
  exit 0
fi

echo "Found files:"
echo "$files"
echo

# Perl substitution:
# - Only inside t(...) or I18n.t(...)
# - Only if string contains activerecord
# - Replace electrical. -> electrical/
pattern='s{((?:I18n\.t|t)\((?::)?["'"'"'][^"'"'"']*activerecord[^"'"'"']*)electrical\.}{$1electrical/}g'

if $PRETEND; then
  echo "Previewing changes..."
  for file in $files; do
    echo "---- $file ----"
    perl -pe "$pattern" "$file" | diff -u "$file" - || true
  done
else
  echo "Applying changes..."
  for file in $files; do
    perl -i -pe "$pattern" "$file"
  done
  echo "Done."
fi