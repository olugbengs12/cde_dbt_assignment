-- Grain: one row per Facebook ad.
select
    cast(ad_id as string)                   as ad_id,
    cast(ad_group_id as string)             as ad_group_id,
    cast(campaign_id as string)             as campaign_id,
    cast(account_id as string)              as account_id,
    trim(ad_name)                           as ad_name,
    lower(ad_status)                        as ad_status,
    try_cast(ad_updated_at as timestamp)    as updated_at
from {{ source('facebook_ads', 'ads') }}
