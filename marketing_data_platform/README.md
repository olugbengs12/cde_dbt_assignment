# Marketing Data Platform (Databricks + dbt)

A unified, tested and documented model of **Facebook Ads** and **Snapchat Ads** performance, built with dbt on
Databricks (Unity Catalog), monitored with Elementary and deployed through GitHub Actions with a service principal.

---

## 1. Architecture

```
 Provided CSV files
        │  setup/02_load_bronze.sql  (Volume + read_files, all columns STRING)
        ▼
 bronze_production.cdc_staging      RAW: exactly as delivered (9 tables)
        │  dbt
        ▼
 silver_production.staging          stg_facebook__*, stg_snapchat__*      (views)    clean / rename / type
 silver_production (ephemeral)      int_facebook__ads_daily,
                                    int_snapchat__ads_daily               (ephemeral) join hierarchy, align grain
 silver_production.intermediate     int_marketing_ads                     (view)      union of platforms
        ▼
 gold_production.marketing          fct_marketing_ads_daily               (incremental) unified fact
                                    mart_marketing_campaign_daily         (table)     KPIs for BI / AI agents
        ▼
 Analysts (SQL) · BI dashboards · AI agents
```

Lineage (from `dbt docs`):

```
facebook_ads.* ─► stg_facebook__* ─► int_facebook__ads_daily ─┐
                                                               ├─► int_marketing_ads ─► fct_marketing_ads_daily ─► mart_marketing_campaign_daily
snapchat_ads.* ─► stg_snapchat__* ─► int_snapchat__ads_daily ─┘
```

## 2. What I found in the source data (and what I did about it)

| Finding | Decision |
|---|---|
| Facebook is 5 files (stats + ads/ad sets/campaigns/accounts); Snapchat is 4 | One staging model per source table; the hierarchy is joined in intermediate |
| Snapchat stats are **ad × day × country**; Facebook is **ad × day** | Snapchat is summed over country in `int_snapchat__ads_daily` so both share one grain |
| Snapchat stats call the ad `ad_detail_id` | Renamed to `ad_id` in staging |
| 3 Snapchat ad groups appear twice (history versions) | Staging keeps the latest `ad_group_updated_at` |
| Clicks/impressions contain the literal string `'null'` (24k FB rows) | Treated as 0: those rows have tiny delivery (median 24 impressions) and null impressions always have 0 spend |
| Facebook spend is in **USD or EUR** per account; Snapchat is EUR | `currency_code` is on every row and part of the mart grain. No FX rates were provided, so spend is never converted or summed across currencies |
| IDs are 18-digit numbers (FB) and UUIDs (Snapchat) | All IDs kept as STRING so they union cleanly |
| Facebook covers 2025, Snapchat covers 2024 | Platform comparisons are over each platform's full period; documented for users |

## 3. Data model

| Model | Grain | Materialization | Why |
|---|---|---|---|
| `stg_*` (9) | same as source table | **view** | Light renames/casts; always fresh, no storage cost |
| `int_facebook__ads_daily`, `int_snapchat__ads_daily` | platform × ad × day | **ephemeral** | Used once each; no need to store |
| `int_marketing_ads` | platform × ad × day | **view** | Single union point; kept queryable/testable in dev and CI |
| `fct_marketing_ads_daily` | platform × ad × day (PK `marketing_ad_daily_id`) | **incremental** (merge) | Largest, ever-growing table; re-processes only the last `lookback_days` (3) days to absorb platform restatements |
| `mart_marketing_campaign_daily` | platform × campaign × day | **table** | Small, queried often by BI/agents, cheap to rebuild |

- The **fact** holds only additive metrics (spend, impressions, clicks), so it can be summed to any level.
- The **mart** computes CTR, CPC and CPM from *summed totals* (never averages of ratios) using `safe_divide`,
  which returns NULL when the denominator is 0 (a CPC with zero clicks is undefined, not 0).
- Names are denormalised onto the rows so analysts and AI agents can answer questions without joins.

| Metric | Definition |
|---|---|
| CTR | clicks / impressions |
| CPC | spend / clicks |
| CPM | spend / impressions × 1,000 |

## 4. Data quality

| Test | Protects against |
|---|---|
| `unique` + `not_null` on every ID / primary key | duplicated or broken source extracts |
| `unique_combination_of_columns` on each grain (stats, fact, mart) | double counting |
| `relationships` stats → ads (both platforms) | stats for ads we cannot attribute |
| `not_null` campaign_id/name on the fact | a join in the hierarchy silently failing |
| `accepted_values` platform ∈ (facebook, snapchat), currency ∈ (USD, EUR), FB ad_status | new/unexpected values |
| `accepted_range` spend/impressions/clicks ≥ 0, CTR between 0 and 1 | impossible metrics |
| `assert_clicks_not_greater_than_impressions` (singular) | swapped / corrupt columns |
| `assert_spend_reconciles_to_staging` (singular) | fan-out or dropped rows between staging and fact |
| `elementary.volume_anomalies`, `elementary.schema_changes` (warn) | unexpected row-count drops/spikes, upstream schema changes |

## 5. Environments

| | Development / staging | CI | Production |
|---|---|---|---|
| dbt target | `dev` | `ci` | `production` |
| Who runs it | developer, locally | GitHub Actions on every PR | GitHub Actions on merge to `main`, daily, or manual |
| Auth | personal access token | **service principal** (OAuth) | **service principal** (OAuth) |
| Where models land | `development.dbt_<name>` | `ci_development.pr_<PR number>` | `silver_production.{staging,intermediate,elementary}`, `gold_production.marketing` |

`macros/generate_schema_name.sql` puts everything in the target schema in dev/CI (isolation per developer and per PR),
and uses the layer schemas only in production. `profiles.yml` contains no secrets: everything is read from environment
variables / GitHub secrets.

## 6. Security and permissions

- Production and CI authenticate as a Databricks **service principal**, so they do not depend on any person's credentials.
- `setup/01_unity_catalog.sql` gives the service principal **read-only** access to bronze and build rights only on
  `ci_development`, `silver_production` and `gold_production`. The developer gets read access to CI/production outputs.

## 7. CI/CD

```
feature branch ─► pull request ─► CI (dbt deps, debug, build --full-refresh = run + test, docs) ─► merge ─► Production (dbt build, docs, Elementary report)
```

- `.github/workflows/ci.yml` — PR validation in an isolated PR schema. A failing test blocks the merge (set `main` branch protection to require the CI check).
- `.github/workflows/deploy_production.yml` — production build, static docs and Elementary report uploaded as a run artifact.

GitHub settings → Secrets and variables → Actions:

| Name | Type |
|---|---|
| `DBX_CLIENT_ID` | secret (service principal Application ID) |
| `DBX_CLIENT_SECRET` | secret (service principal OAuth secret) |
| `DATABRICKS_HOST` | variable (e.g. `dbc-xxxx.cloud.databricks.com`) |
| `DATABRICKS_HTTP_PATH` | variable (SQL warehouse HTTP path) |

## 8. Setup

1. In Databricks: create the service principal + OAuth secret, give it *Databricks SQL access* and *Can use* on the SQL warehouse.
2. Run `setup/01_unity_catalog.sql` (replace the placeholders).
3. Upload the CSVs to the volume and run `setup/02_load_bronze.sql`.
4. Local development (Windows PowerShell):

```powershell
cd marketing_dbt
python -m venv .venv; .\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
$env:DATABRICKS_HOST="dbc-xxxx.cloud.databricks.com"
$env:DATABRICKS_HTTP_PATH="/sql/1.0/warehouses/xxxx"
$env:DATABRICKS_PAT_TOKEN="dapi..."
$env:DEV_SCHEMA="dbt_<yourname>"
$env:DBT_PROFILES_DIR="."
dbt deps
dbt debug
dbt build
dbt docs generate --static        # -> target/static_index.html
edr report --profiles-dir . --profile-target dev
```

## 9. Answering the business questions

```sql
-- Spend per platform (always per currency)
select platform, currency_code, sum(spend) as spend, sum(impressions) as impressions, sum(clicks) as clicks
from gold_production.marketing.mart_marketing_campaign_daily
group by platform, currency_code;

-- Top campaigns by clicks / impressions
select platform, campaign_name, sum(clicks) as clicks, sum(impressions) as impressions
from gold_production.marketing.mart_marketing_campaign_daily
group by platform, campaign_name
order by clicks desc
limit 10;

-- Performance over time with KPIs (ratios recomputed from totals)
select date_trunc('month', date_day) as month, platform, currency_code,
       sum(spend) as spend,
       sum(clicks) / nullif(sum(impressions), 0)          as ctr,
       sum(spend)  / nullif(sum(clicks), 0)               as cpc,
       sum(spend)  / nullif(sum(impressions), 0) * 1000   as cpm
from gold_production.marketing.mart_marketing_campaign_daily
group by all
order by month, platform;
```

## 10. Possible next steps

- Add an FX-rate seed to report spend in one currency.
- Slim CI (`state:modified+` with `--defer`) once the project grows.
- Source freshness checks once data arrives through a scheduled ingestion instead of one-off files.
