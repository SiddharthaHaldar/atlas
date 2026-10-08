# Nuxeo Migration — 6.0 → 7.10 (LTS 2015)

A self-contained Docker environment to simulate and validate an upgrade from **Nuxeo 6.0** to **Nuxeo 7.10 (LTS 2015)**, both backed by **Oracle 11g XE**.

This is not a production deployment. It is a mock environment used to:

- Validate that the N6 Oracle schema can be cloned and migrated to N7
- Verify that documents, users, and binary files created in N6 are accessible in N7 after migration
- Test the required `CONTENT.DATA` column change (`VARCHAR2(40)` → `VARCHAR2(250)`) documented in the [Nuxeo 6.0 → LTS 2015 upgrade guide](https://doc.nuxeo.com/nxdoc/upgrade-from-60-to-lts-2015/)

## Prerequisites

- Docker
- `ojdbc6.jar` placed in `./ojdbc/` (Oracle licensing prevents bundling)

```bash
curl -L https://repo1.maven.org/maven2/com/oracle/database/jdbc/ojdbc6/11.2.0.4/ojdbc6-11.2.0.4.jar -o ojdbc/ojdbc6.jar
```

## Quick Start

```bash
cp .env.example .env        # fill in credentials
docker compose up -d        # starts Oracle + Mailhog + Nuxeo 6
```

Nuxeo 6 → http://localhost:8080/nuxeo
Mailhog UI → http://localhost:8025

## Migration Steps

```bash
# 1. Populate N6 — upload files, create users
# 2. Clone schema and binaries to N7
./scripts/clone-schema-to-owner7.sh

# 3. Start Nuxeo 7.10
docker compose --profile n7 up -d nuxeo7
```

Nuxeo 7.10 → http://localhost:8081/nuxeo
