{{ config(materialized='view') }}
-- Grain: one row per platform per ad per day.
-- The single place where platforms are unioned into one common structure.
-- View (not ephemeral) so it can be queried and tested on its own in dev / CI.
with unioned as (
    select * from {{ ref('int_facebook__ads_daily') }}
    union all
    select * from {{ ref('int_snapchat__ads_daily') }}
)

select
    {{ dbt_utils.generate_surrogate_key(['platform', 'ad_id', 'date_day']) }} as marketing_ad_daily_id,
    *
from unioned
