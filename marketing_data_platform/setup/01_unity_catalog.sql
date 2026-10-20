-- =====================================================================
-- 01_unity_catalog.sql : catalogs, schemas and grants
-- Run once in the Databricks SQL editor as yourself (workspace admin / catalog owner).
-- Replace <SP_APPLICATION_ID> with YOUR service principal's Application ID
-- and <YOUR_EMAIL> with YOUR Databricks login email.
-- =====================================================================

-- ---------- Catalogs (one per layer / environment) ----------
CREATE CATALOG IF NOT EXISTS bronze_production;   -- raw files, as delivered
CREATE SCHEMA  IF NOT EXISTS bronze_production.cdc_staging;
CREATE CATALOG IF NOT EXISTS silver_production;   -- prod staging + intermediate + elementary
CREATE CATALOG IF NOT EXISTS gold_production;     -- prod consumption models (fct / mart)
CREATE CATALOG IF NOT EXISTS ci_development;      -- one schema per pull request (pr_<number>)
CREATE CATALOG IF NOT EXISTS development;         -- developers' personal schemas (dbt_<name>)

-- ---------- Service principal: READ raw data only ----------
GRANT USE CATALOG ON CATALOG bronze_production           TO `<SP_APPLICATION_ID>`;
GRANT USE SCHEMA  ON SCHEMA  bronze_production.cdc_staging TO `<SP_APPLICATION_ID>`;
GRANT SELECT      ON SCHEMA  bronze_production.cdc_staging TO `<SP_APPLICATION_ID>`;
-- Least privilege: the service principal never writes to bronze, so no CREATE on it.

-- ---------- Service principal: BUILD in CI and production ----------
GRANT USE CATALOG, USE SCHEMA, CREATE SCHEMA, CREATE TABLE, SELECT, MODIFY
  ON CATALOG ci_development    TO `<SP_APPLICATION_ID>`;
GRANT USE CATALOG, USE SCHEMA, CREATE SCHEMA, CREATE TABLE, SELECT, MODIFY
  ON CATALOG silver_production TO `<SP_APPLICATION_ID>`;
GRANT USE CATALOG, USE SCHEMA, CREATE SCHEMA, CREATE TABLE, SELECT, MODIFY
  ON CATALOG gold_production   TO `<SP_APPLICATION_ID>`;

-- ---------- You: inspect what CI and production built (read only) ----------
GRANT USE CATALOG, USE SCHEMA, SELECT ON CATALOG ci_development    TO `<YOUR_EMAIL>`;
GRANT USE CATALOG, USE SCHEMA, SELECT ON CATALOG silver_production TO `<YOUR_EMAIL>`;
GRANT USE CATALOG, USE SCHEMA, SELECT ON CATALOG gold_production   TO `<YOUR_EMAIL>`;

-- Not needed here because you create the catalogs above yourself. Only grant it if the
-- service principal must create catalogs on its own:
-- GRANT CREATE CATALOG ON METASTORE TO `<SP_APPLICATION_ID>`;

-- Check:
-- SHOW GRANTS `<SP_APPLICATION_ID>` ON CATALOG gold_production;
