-- Grain: one row per Facebook ad account.
select
    cast(account_id as string)                  as account_id,
    trim(account_name)                          as account_name,
    upper(ad_currency_code)                     as currency_code,
    try_cast(account_created_at as timestamp)   as created_at,
    try_cast(account_updated_at as timestamp)   as updated_at
from {{ source('facebook_ads', 'accounts') }}
