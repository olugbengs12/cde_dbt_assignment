-- Grain: one row per Snapchat ad per day per country (the source grain; rolled up in intermediate).
select
    cast(ad_detail_id as string)                        as ad_id,
    upper(ad_country)                                   as country_code,
    upper(ad_currency_code)                             as currency_code,
    cast(ad_date as date)                               as date_day,
    try_cast(ad_spend as decimal(18, 6))                as spend,
    coalesce(try_cast(ad_impressions as bigint), 0)     as impressions,
    -- 'null' in the export means no clicks reported -> 0
    coalesce(try_cast(ad_clicks as bigint), 0)          as clicks
from {{ source('snapchat_ads', 'ads_stats') }}
