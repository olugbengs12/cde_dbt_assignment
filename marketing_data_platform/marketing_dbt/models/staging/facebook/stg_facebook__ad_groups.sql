-- Grain: one row per Facebook ad set (called "ad group" across platforms in this project).
select
    cast(ad_group_id as string)                 as ad_group_id,
    trim(ad_group_name)                         as ad_group_name,
    try_cast(ad_group_updated_at as timestamp)  as updated_at
from {{ source('facebook_ads', 'ad_groups') }}
