# Atlas

Atlas is a suite of enterprise applications supporting document management, collaboration, and content governance workflows.

## Applications

| Application | Description |
|---|---|
| **nuxeo** | Document management platform (Nuxeo ECM) |

## nuxeo

The `nuxeo` directory contains a Dockerized test environment simulating an upgrade from **Nuxeo 6.0** to **Nuxeo 7.10 (LTS 2015)**, both backed by **Oracle 11g XE**.

This is not a production deployment. It is a self-contained mock environment used to:

- Validate that the N6 Oracle schema can be cloned and migrated to N7
- Verify that documents, users, and binary files created in N6 are accessible in N7 after migration
- Test the required `CONTENT.DATA` column change (`VARCHAR2(40)` → `VARCHAR2(250)`) documented in the [Nuxeo 6.0 → LTS 2015 upgrade guide](https://doc.nuxeo.com/nxdoc/upgrade-from-60-to-lts-2015/)

### Quick Start

```bash
cd nuxeo
cp .env.example .env   # fill in credentials
docker compose up -d   # starts Oracle + Nuxeo 6
```

See `nuxeo/` for full setup and migration instructions.
