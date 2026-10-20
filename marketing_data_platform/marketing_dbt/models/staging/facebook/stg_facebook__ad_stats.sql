-- Grain: one row per Facebook ad per day.
select
    cast(ad_id as string)                                   as ad_id,
    cast(account_id as string)                              as account_id,
    cast(ad_date as date)                                   as date_day,
    try_cast(ad_spend as decimal(18, 6))                    as spend,
    -- 'null' in the export means nothing was reported (these rows have 0 spend / tiny delivery) -> 0
    coalesce(try_cast(ad_impressions as bigint), 0)         as impressions,
    coalesce(try_cast(ad_clicks as bigint), 0)              as clicks
from {{ source('facebook_ads', 'ads_stats') }}
