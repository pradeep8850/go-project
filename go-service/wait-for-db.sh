#!/bin/bash
# wait-for-db.sh

set -e

host="${DB_HOST:-127.0.0.1}"
port="${DB_PORT:-3306}"
timeout=30
elapsed=0

echo "Waiting for MariaDB at $host:$port..."

until nc -z "$host" "$port" 2>/dev/null || [ $elapsed -eq $timeout ]; do
  echo "MariaDB is unavailable - sleeping"
  sleep 1
  elapsed=$((elapsed + 1))
done

if [ $elapsed -eq $timeout ]; then
  echo "Timeout waiting for MariaDB"
  exit 1
fi

echo "MariaDB is up - executing command"
