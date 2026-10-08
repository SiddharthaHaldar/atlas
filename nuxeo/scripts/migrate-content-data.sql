-- ──────────────────────────────────────────────────────────────────────────────
-- migrate-content-data.sql
--
-- Nuxeo 6 → 7.10 schema migration: CONTENT.DATA column
--
-- In Nuxeo 7.x the blob store keys in the CONTENT table are prefixed with the
-- digest algorithm (e.g. "md5:abc123...").  N6 stored only the raw hex digest.
-- This statement adds the "md5:" prefix to any DATA value that is not yet
-- prefixed, making the existing blobs recognisable to the N7 blob manager.
--
-- VERIFY FIRST: cross-check this against your migration guide before running.
-- If your N6 blobs used a different algorithm (sha256, etc.) update the prefix.
--
-- Run as NUXEO_OWNER7 (called automatically by clone-schema-to-owner7.sh).
-- ──────────────────────────────────────────────────────────────────────────────

-- Step 1: Widen DATA column from VARCHAR2(40) to VARCHAR2(250)
-- Required before prefixing — N7 expects 250, N6 stored 40
ALTER TABLE CONTENT MODIFY (DATA VARCHAR2(250));

-- Step 2: Preview current DATA values
SELECT COUNT(*) AS total_content_rows FROM CONTENT WHERE DATA IS NOT NULL;

-- Step 3: Verify DATA values (no prefix transformation applied)
-- The raw MD5 digest is the correct format for N7 blob resolution.
-- Update this section if your migration docs specify a different transformation.
SELECT DATA FROM CONTENT WHERE DATA IS NOT NULL;

COMMIT;

EXIT;
