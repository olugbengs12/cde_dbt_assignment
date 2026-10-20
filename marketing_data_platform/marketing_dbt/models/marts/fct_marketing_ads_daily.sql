{{
    config(
        materialized='incremental',
        unique_key='marketing_ad_daily_id',
        on_schema_change='append_new_columns'
    )
}}
-- Grain: one row per platform per ad per day.
-- Incremental: this is the largest, ever-growing table (one row per ad per day, ~95k rows today).
-- Each run only re-processes the last `lookback_days` days and MERGEs them on the surrogate key,
-- so late restatements from the platforms are picked up without rebuilding history.
select
    marketing_ad_daily_id,
    date_day,
    platform,
    account_id,
    account_name,
    currency_code,
    campaign_id,
    campaign_name,
    ad_group_id,
    ad_group_name,
    ad_id,
    ad_name,
    spend,
    impressions,
    clicks,
    current_timestamp as dbt_loaded_at
from {{ ref('int_marketing_ads') }}

{% if is_incremental() %}
where date_day >= (
    select {{ dbt.dateadd('day', -1 * var('lookback_days'), 'max(date_day)') }}
    from {{ this }}
)
{% endif %}
