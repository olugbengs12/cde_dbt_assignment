-- =====================================================================
-- 02_load_bronze.sql : load the provided CSV files into the bronze layer
-- 1. Run the CREATE VOLUME below.
-- 2. Catalog Explorer > bronze_production > cdc_staging > Volumes > raw_files > "Upload to this volume":
--    upload the facebook/ and snapchat/ folders (keep the folder names).
-- 3. Run the rest of this script.
-- Bronze keeps the data exactly as delivered: every column is loaded as STRING
-- (inferColumnTypes => false). Typing and cleaning happen in dbt staging models.
-- =====================================================================

CREATE VOLUME IF NOT EXISTS bronze_production.cdc_staging.raw_files;

-- ---------- Facebook ----------
CREATE OR REPLACE TABLE bronze_production.cdc_staging.ads_stats AS
SELECT * FROM read_files('/Volumes/bronze_production/cdc_staging/raw_files/facebook/ads_stats.csv',
  format => 'csv', header => true, inferColumnTypes => false);

CREATE OR REPLACE TABLE bronze_production.cdc_staging.new_ads_de_randomized AS
SELECT * FROM read_files('/Volumes/bronze_production/cdc_staging/raw_files/facebook/new_ads_de_randomized.csv',
  format => 'csv', header => true, inferColumnTypes => false);

CREATE OR REPLACE TABLE bronze_production.cdc_staging.new_adgroup_de_randomized AS
SELECT * FROM read_files('/Volumes/bronze_production/cdc_staging/raw_files/facebook/new_adgroup_de_randomized.csv',
  format => 'csv', header => true, inferColumnTypes => false);

CREATE OR REPLACE TABLE bronze_production.cdc_staging.new_campaign_de_randomized AS
SELECT * FROM read_files('/Volumes/bronze_production/cdc_staging/raw_files/facebook/new_campaign_de_randomized.csv',
  format => 'csv', header => true, inferColumnTypes => false);

CREATE OR REPLACE TABLE bronze_production.cdc_staging.new_acccount_de_randomized AS
SELECT * FROM read_files('/Volumes/bronze_production/cdc_staging/raw_files/facebook/new_acccount_de_randomized.csv',
  format => 'csv', header => true, inferColumnTypes => false);

-- ---------- Snapchat ----------
CREATE OR REPLACE TABLE bronze_production.cdc_staging.snapchat_ads_stats AS
SELECT * FROM read_files('/Volumes/bronze_production/cdc_staging/raw_files/snapchat/snapchat_ads_stats.csv',
  format => 'csv', header => true, inferColumnTypes => false);

CREATE OR REPLACE TABLE bronze_production.cdc_staging.snapchat_ads_ad_history_new_ad_names AS
SELECT * FROM read_files('/Volumes/bronze_production/cdc_staging/raw_files/snapchat/snapchat_ads_ad_history_new_ad_names.csv',
  format => 'csv', header => true, inferColumnTypes => false);

CREATE OR REPLACE TABLE bronze_production.cdc_staging.snapchat_ads_adgroup_history_new_ad_group_names AS
SELECT * FROM read_files('/Volumes/bronze_production/cdc_staging/raw_files/snapchat/snapchat_ads_adgroup_history_new_ad_group_names.csv',
  format => 'csv', header => true, inferColumnTypes => false);

CREATE OR REPLACE TABLE bronze_production.cdc_staging.snapchat_ads_campaign_history_new_campaign_names AS
SELECT * FROM read_files('/Volumes/bronze_production/cdc_staging/raw_files/snapchat/snapchat_ads_campaign_history_new_campaign_names.csv',
  format => 'csv', header => true, inferColumnTypes => false);

-- ---------- Row-count check (expected) ----------
SELECT 'ads_stats' t, count(*) n FROM bronze_production.cdc_staging.ads_stats                                    -- 92,300
UNION ALL SELECT 'fb ads',       count(*) FROM bronze_production.cdc_staging.new_ads_de_randomized              -- 98,926
UNION ALL SELECT 'fb adgroups',  count(*) FROM bronze_production.cdc_staging.new_adgroup_de_randomized          -- 13,433
UNION ALL SELECT 'fb campaigns', count(*) FROM bronze_production.cdc_staging.new_campaign_de_randomized         -- 4,162
UNION ALL SELECT 'fb accounts',  count(*) FROM bronze_production.cdc_staging.new_acccount_de_randomized         -- 16
UNION ALL SELECT 'snap stats',   count(*) FROM bronze_production.cdc_staging.snapchat_ads_stats                 -- 2,809
UNION ALL SELECT 'snap ads',     count(*) FROM bronze_production.cdc_staging.snapchat_ads_ad_history_new_ad_names            -- 2,513
UNION ALL SELECT 'snap adgroups',count(*) FROM bronze_production.cdc_staging.snapchat_ads_adgroup_history_new_ad_group_names -- 267
UNION ALL SELECT 'snap campaigns',count(*) FROM bronze_production.cdc_staging.snapchat_ads_campaign_history_new_campaign_names; -- 109
