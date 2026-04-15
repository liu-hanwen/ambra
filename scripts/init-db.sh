#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DB_PATH="${1:-${ROOT_DIR}/queue.db}"

if ! command -v sqlite3 >/dev/null 2>&1; then
  echo "ERROR: sqlite3 is not installed." >&2
  exit 1
fi

mkdir -p "$(dirname "${DB_PATH}")"

shopt -s nullglob
migrations=("${ROOT_DIR}"/migrations/*.sql)
if [ "${#migrations[@]}" -eq 0 ]; then
  echo "ERROR: no files matched migrations/*.sql." >&2
  exit 1
fi

for migration in "${migrations[@]}"; do
  AMBRA_DB_PATH="${DB_PATH}" "${ROOT_DIR}/scripts/sqlite.sh" < "${migration}"
done

echo "Database initialized: ${DB_PATH}"
