#!/usr/bin/env bash
# ──────────────────────────────────────────────────────────────────────────────
# clone-schema-to-owner7.sh
#
# Run this on your dev VM AFTER you have finished populating N6 (uploading
# files, creating users, etc.) and BEFORE starting Nuxeo 7.10.
#
# What it does:
#   1. Stops the nuxeo6 container so there are no active connections
#   2. Exports NUXEO_OWNER schema from Oracle XE using Data Pump (within container)
#   3. Imports the dump as NUXEO_OWNER7 (schema remap)
#   4. Runs the CONTENT.DATA migration required for N7.10
#   5. Copies binaries from ./binaries/n6 into ./binaries/n7
#
# Usage:
#   chmod +x clone-schema-to-owner7.sh
#   ./clone-schema-to-owner7.sh
# ──────────────────────────────────────────────────────────────────────────────
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "${SCRIPT_DIR}")"
ORACLE_CONTAINER="oracle-xe-11g"
NUXEO6_CONTAINER="nuxeo-6"
N6_BINARIES="${PROJECT_DIR}/binaries/n6"
N7_BINARIES="${PROJECT_DIR}/binaries/n7"
SYSTEM_PASSWORD="oracle"
SID="XE"
SRC_SCHEMA="NUXEO_OWNER"
DST_SCHEMA="NUXEO_OWNER7"
DST_PASSWORD="nxo_own17"
DUMP_FILE="nuxeo_owner_clone.dmp"
LOG_EXPORT="nuxeo_owner_export.log"
LOG_IMPORT="nuxeo_owner7_import.log"

# Oracle binaries are not on the default PATH inside the container
ORACLE_ENV="export ORACLE_HOME=/u01/app/oracle/product/11.2.0/xe && export PATH=\$ORACLE_HOME/bin:\$PATH && export ORACLE_SID=${SID}"

# ── 1. Stop N6 to ensure a clean, consistent export ──────────────────────────
echo "==> Stopping nuxeo6 container..."
docker stop "${NUXEO6_CONTAINER}" || true

# ── 2. Ensure DATA_PUMP_DIR directory object exists ──────────────────────────
echo "==> Setting up DATA_PUMP_DIR in Oracle..."
docker exec "${ORACLE_CONTAINER}" sh -c "${ORACLE_ENV} && sqlplus -S system/${SYSTEM_PASSWORD}@localhost/${SID}" <<SQL
CREATE OR REPLACE DIRECTORY DATA_PUMP_DIR AS '/u01/app/oracle/admin/XE/dpdump';
GRANT READ, WRITE ON DIRECTORY DATA_PUMP_DIR TO ${SRC_SCHEMA};
GRANT READ, WRITE ON DIRECTORY DATA_PUMP_DIR TO ${DST_SCHEMA};
EXIT;
SQL

# ── 3. Export NUXEO_OWNER ─────────────────────────────────────────────────────
echo "==> Exporting schema ${SRC_SCHEMA}..."
docker exec "${ORACLE_CONTAINER}" sh -c "${ORACLE_ENV} && expdp ${SRC_SCHEMA}/${DST_PASSWORD}@localhost/${SID} SCHEMAS=${SRC_SCHEMA} DIRECTORY=DATA_PUMP_DIR DUMPFILE=${DUMP_FILE} LOGFILE=${LOG_EXPORT} REUSE_DUMPFILES=YES"

# ── 4. Drop and recreate NUXEO_OWNER7 for a clean import ─────────────────────
echo "==> Resetting ${DST_SCHEMA} schema..."
docker exec "${ORACLE_CONTAINER}" sh -c "${ORACLE_ENV} && sqlplus -S system/${SYSTEM_PASSWORD}@localhost/${SID}" <<SQL
DROP USER ${DST_SCHEMA} CASCADE;
CREATE USER ${DST_SCHEMA} IDENTIFIED BY ${DST_PASSWORD}
  DEFAULT TABLESPACE USERS
  TEMPORARY TABLESPACE TEMP
  QUOTA UNLIMITED ON USERS;
GRANT CONNECT, RESOURCE, CREATE VIEW TO ${DST_SCHEMA};
GRANT CREATE SEQUENCE, CREATE TABLE, CREATE TRIGGER, CREATE TYPE TO ${DST_SCHEMA};
GRANT SELECT ANY DICTIONARY TO ${DST_SCHEMA};
GRANT IMP_FULL_DATABASE TO ${DST_SCHEMA};
GRANT EXECUTE ON SYS.DBMS_CRYPTO TO ${DST_SCHEMA};
EXIT;
SQL

# ── 5. Import as NUXEO_OWNER7 ─────────────────────────────────────────────────
echo "==> Importing dump as ${DST_SCHEMA}..."
docker exec "${ORACLE_CONTAINER}" sh -c "${ORACLE_ENV} && impdp system/${SYSTEM_PASSWORD}@localhost/${SID} SCHEMAS=${SRC_SCHEMA} REMAP_SCHEMA=${SRC_SCHEMA}:${DST_SCHEMA} DIRECTORY=DATA_PUMP_DIR DUMPFILE=${DUMP_FILE} LOGFILE=${LOG_IMPORT} TABLE_EXISTS_ACTION=REPLACE"

# ── 6. Run CONTENT.DATA migration ─────────────────────────────────────────────
echo "==> Running CONTENT.DATA migration on ${DST_SCHEMA}..."
docker exec -i "${ORACLE_CONTAINER}" sh -c "${ORACLE_ENV} && sqlplus -S ${DST_SCHEMA}/${DST_PASSWORD}@localhost/${SID}" \
  < "$(dirname "$0")/migrate-content-data.sql"

# ── 7. Copy N6 binaries into N7 binary store ─────────────────────────────────
echo "==> Copying binaries from N6 → N7..."
cp -r "${N6_BINARIES}/." "${N7_BINARIES}/"
echo "    Copied $(find "${N7_BINARIES}" -type f | wc -l | tr -d ' ') files to ${N7_BINARIES}"

echo ""
echo "==> Done. Schema ${DST_SCHEMA} is ready for Nuxeo 7.10."
echo "    Start N7 with:"
echo "    docker compose --profile n7 up -d nuxeo7"
