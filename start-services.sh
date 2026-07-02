#!/usr/bin/env bash
set -uo pipefail

cleanup() {
  for pid in "${backend_pid:-}" "${ai_pid:-}"; do
    if [[ -n "${pid:-}" ]] && kill -0 "$pid" 2>/dev/null; then
      kill "$pid" 2>/dev/null || true
    fi
  done
}

trap cleanup INT TERM

cd /app/ai-service
python3 -m uvicorn app.main:app --host 0.0.0.0 --port 8000 &
ai_pid=$!

cd /app/backend
dotnet ZPantry_Backend.dll &
backend_pid=$!

set +e
wait -n "$ai_pid" "$backend_pid"
exit_code=$?
set -e

cleanup
wait "$ai_pid" "$backend_pid" 2>/dev/null || true

exit "$exit_code"
