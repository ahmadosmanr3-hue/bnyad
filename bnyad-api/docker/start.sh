#!/bin/sh
PORT="${PORT:-8080}"

echo "=== BNYAD API starting on port ${PORT} ==="

if [ -z "$APP_KEY" ]; then
  echo "ERROR: APP_KEY is not set. Add it in Render -> Environment."
  exit 1
fi

if [ -n "$DB_HOST" ]; then
  echo "=== Running migrations + seed (first deploy may take 1-2 min) ==="
  php artisan migrate --force --seed || echo "WARNING: migrate/seed failed — check DB_* env vars"
else
  echo "WARNING: DB_HOST not set — skipping migrate. Add MySQL env vars in Render."
fi

echo "=== Server ready ==="
exec php artisan serve --host=0.0.0.0 --port="${PORT}"
