#!/usr/bin/env bash
# ──────────────────────────────────────────────────────────────────────────────
# verify-n7-connection.sh
# Quick sanity checks after the full stack is up.
# ──────────────────────────────────────────────────────────────────────────────
set -euo pipefail

CONTAINER="oracle-xe-11g"
SYSTEM_PASSWORD="oracle"
NUXEO_USER="NUXEO_OWNER"
NUXEO_PASSWORD="nxo_own17"
ORACLE_SID="XE"
NUXEO_URL="http://localhost:8080/nuxeo"

echo "==> 1. Oracle container reachable?"
docker exec "${CONTAINER}" sqlplus -S \
  "system/${SYSTEM_PASSWORD}@localhost/${ORACLE_SID}" \
  <<< "SELECT 'Oracle OK' FROM DUAL; EXIT;" \
  | grep "Oracle OK" && echo "    PASS" || echo "    FAIL"

echo "==> 2. NUXEO_OWNER schema present?"
docker exec "${CONTAINER}" sqlplus -S \
  "${NUXEO_USER}/${NUXEO_PASSWORD}@localhost/${ORACLE_SID}" \
  <<< "SELECT COUNT(*) FROM user_tables; EXIT;"

echo "==> 3. CONTENT.DATA migration applied?"
docker exec "${CONTAINER}" sqlplus -S \
  "${NUXEO_USER}/${NUXEO_PASSWORD}@localhost/${ORACLE_SID}" \
  <<< "SELECT COUNT(*) AS unprefixed FROM CONTENT WHERE DATA IS NOT NULL AND DATA NOT LIKE '%:%'; EXIT;"

echo "==> 4. Nuxeo 7.10 HTTP response?"
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "${NUXEO_URL}/login.jsp" || true)
echo "    HTTP ${HTTP_CODE} (expect 200)"

echo "==> Done."
