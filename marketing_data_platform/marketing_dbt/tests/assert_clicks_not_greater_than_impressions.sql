-- A click cannot happen without an impression. Rows returned = bad data (e.g. swapped columns
-- in a new export). Protects every CTR in the mart from going above 100%.
select marketing_ad_daily_id, platform, ad_id, date_day, impressions, clicks
from {{ ref('fct_marketing_ads_daily') }}
where clicks > impressions
