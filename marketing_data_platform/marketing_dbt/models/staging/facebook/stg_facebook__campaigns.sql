-- Grain: one row per Facebook campaign.
select
    cast(campaign_id as string)                 as campaign_id,
    trim(campaign_name)                         as campaign_name,
    try_cast(campaign_updated_at as timestamp)  as updated_at
from {{ source('facebook_ads', 'campaigns') }}
