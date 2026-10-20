-- Grain: one row per Snapchat ad group (latest version only).
-- The source holds history: 3 ad groups appear twice. Keep the most recently updated row.
with ranked as (
    select
        cast(ad_group_id as string)                 as ad_group_id,
        cast(campaign_id as string)                 as campaign_id,
        trim(ad_group_name)                         as ad_group_name,
        try_cast(ad_group_updated_at as timestamp)  as updated_at,
        row_number() over (
            partition by ad_group_id
            order by try_cast(ad_group_updated_at as timestamp) desc
        )                                           as version_rank
    from {{ source('snapchat_ads', 'ad_groups') }}
)

select ad_group_id, campaign_id, ad_group_name, updated_at
from ranked
where version_rank = 1
