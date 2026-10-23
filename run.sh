#!/usr/bin/env bash
# PHP2Shell Lab — Start/Stop/Test
set -euo pipefail

cd "$(dirname "$0")"

case "${1:-start}" in
  start)
    echo "=== Starting PHP2Shell Lab ==="
    docker compose up -d --build
    echo ""
    echo "Lab is running at: http://localhost:9999"
    echo "Check vulnerability: python3 exploit.py --check -u http://localhost:8080"
    echo "Run exploit:        python3 exploit.py -c 'whoami'"
    ;;

  stop)
    echo "=== Stopping PHP2Shell Lab ==="
    docker compose down
    ;;

  test)
    echo "=== Testing CVE-2026-109618 ==="
    python3 exploit.py --check -u http://localhost:9999
    echo ""
    python3 exploit.py -u http://localhost:9999 -c 'whoami'
    ;;

  logs)
    docker compose logs -f php2shell-lab
    ;;

  *)
    echo "Usage: $0 {start|stop|test|logs}"
    exit 1
esac
