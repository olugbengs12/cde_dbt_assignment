-- Grain: one row per platform per campaign per day.
-- The consumption model for analysts, BI and AI agents: campaign-level totals plus the
-- business KPIs (CTR, CPC, CPM). Ratios are computed here from summed totals, never by
-- averaging ad-level ratios. Table: small, queried often, rebuilt cheaply from the fact.
select
    date_day,
    platform,
    account_id,
    currency_code,
    campaign_id,
    campaign_name,
    count(distinct ad_id)                                   as active_ads,
    sum(spend)                                              as spend,
    sum(impressions)                                        as impressions,
    sum(clicks)                                             as clicks,
    {{ safe_divide('sum(clicks)', 'sum(impressions)') }}    as ctr,
    {{ safe_divide('sum(spend)', 'sum(clicks)') }}          as cpc,
    {{ safe_divide('sum(spend) * 1000', 'sum(impressions)') }} as cpm
from {{ ref('fct_marketing_ads_daily') }}
group by date_day, platform, account_id, currency_code, campaign_id, campaign_name
