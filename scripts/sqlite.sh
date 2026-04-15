#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DB_PATH="${AMBRA_DB_PATH:-${ROOT_DIR}/queue.db}"

if ! command -v sqlite3 >/dev/null 2>&1; then
  echo "ERROR: sqlite3 is not installed." >&2
  exit 1
fi

if [ "$#" -eq 0 ]; then
  exec sqlite3 -cmd 'PRAGMA foreign_keys=ON' "${DB_PATH}"
fi

exec sqlite3 -cmd 'PRAGMA foreign_keys=ON' "${DB_PATH}" "$@"
