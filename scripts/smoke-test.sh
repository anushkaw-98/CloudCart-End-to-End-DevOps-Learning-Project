#!/usr/bin/env sh
set -eu
URL="${1:-http://localhost:8080}"
curl --fail --silent --show-error "$URL/health"
echo
curl --fail --silent --show-error "$URL/"
echo
