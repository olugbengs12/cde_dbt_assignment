-- Grain: one row per Snapchat ad per day.
-- Snapchat reports per country; Facebook does not. Country is rolled up here so both platforms
-- share the same grain (ad x day). Ephemeral: only feeds int_marketing_ads.
with stats as (
    select
        ad_id,
        date_day,
        currency_code,
        sum(spend)          as spend,
        sum(impressions)    as impressions,
        sum(clicks)         as clicks
    from {{ ref('stg_snapchat__ad_stats') }}
    group by ad_id, date_day, currency_code
)

select
    'snapchat'                  as platform,
    s.date_day,
    c.account_id,
    cast(null as string)        as account_name,   -- no Snapchat account file was provided
    s.currency_code,
    g.campaign_id,
    c.campaign_name,
    a.ad_group_id,
    g.ad_group_name,
    s.ad_id,
    a.ad_name,
    s.spend,
    s.impressions,
    s.clicks
from stats as s
left join {{ ref('stg_snapchat__ads') }} as a
    on s.ad_id = a.ad_id
left join {{ ref('stg_snapchat__ad_groups') }} as g
    on a.ad_group_id = g.ad_group_id
left join {{ ref('stg_snapchat__campaigns') }} as c
    on g.campaign_id = c.campaign_id
