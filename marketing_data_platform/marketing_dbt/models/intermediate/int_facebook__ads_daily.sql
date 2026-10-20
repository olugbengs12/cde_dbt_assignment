-- Grain: one row per Facebook ad per day, enriched with ad set, campaign and account attributes.
-- Ephemeral: only used to feed int_marketing_ads, no need to store it.
select
    'facebook'              as platform,
    s.date_day,
    s.account_id,
    acc.account_name,
    acc.currency_code,
    a.campaign_id,
    c.campaign_name,
    a.ad_group_id,
    g.ad_group_name,
    s.ad_id,
    a.ad_name,
    s.spend,
    s.impressions,
    s.clicks
from {{ ref('stg_facebook__ad_stats') }} as s
left join {{ ref('stg_facebook__ads') }} as a
    on s.ad_id = a.ad_id
left join {{ ref('stg_facebook__ad_groups') }} as g
    on a.ad_group_id = g.ad_group_id
left join {{ ref('stg_facebook__campaigns') }} as c
    on a.campaign_id = c.campaign_id
left join {{ ref('stg_facebook__accounts') }} as acc
    on s.account_id = acc.account_id
