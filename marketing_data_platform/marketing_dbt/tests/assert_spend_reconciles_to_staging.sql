-- Total spend in the fact must equal the total spend in staging, per platform.
-- Catches fan-out (duplicate rows from a bad join) or dropped rows in the intermediate layer.
with staging as (
    select 'facebook' as platform, sum(spend) as spend from {{ ref('stg_facebook__ad_stats') }}
    union all
    select 'snapchat' as platform, sum(spend) as spend from {{ ref('stg_snapchat__ad_stats') }}
),

fact as (
    select platform, sum(spend) as spend
    from {{ ref('fct_marketing_ads_daily') }}
    group by platform
)

select s.platform, s.spend as staging_spend, f.spend as fact_spend
from staging as s
left join fact as f on s.platform = f.platform
where f.spend is null or abs(s.spend - f.spend) > 0.01
