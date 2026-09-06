#!/bin/bash
# init_2_wait_for_db.sh - runs before Payara starts (via SCRIPT_DIR/init.d)
# Waits for the PostgreSQL database referenced by PGHOST/PGPORT to accept TCP connections.
set -e

HOST="${PGHOST:-localhost}"
PORT="${PGPORT:-5432}"

echo "[init] Waiting for PostgreSQL at ${HOST}:${PORT} ..."
for i in $(seq 1 60); do
  if (exec 3<>/dev/tcp/"${HOST}"/"${PORT}") 2>/dev/null; then
    exec 3>&- 3<&-
    echo "[init] PostgreSQL is reachable."
    exit 0
  fi
  sleep 2
done

echo "[init] ERROR: PostgreSQL did not become reachable in time."
exit 1
