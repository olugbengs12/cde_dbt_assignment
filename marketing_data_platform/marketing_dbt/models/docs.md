{% docs fct_marketing_ads_daily %}
Unified Facebook + Snapchat advertising performance.

**Grain:** one row per platform, per ad, per day. Primary key `marketing_ad_daily_id`.

Contains only *additive* metrics (spend, impressions, clicks), so it can be summed to any level
(campaign, platform, month). Ratios such as CTR/CPC/CPM live in `mart_marketing_campaign_daily`.

Denormalised on purpose (campaign / ad group / ad names sit on the row) so analysts, BI tools and
AI agents can answer questions without joins.

Materialised **incremental** (merge on `marketing_ad_daily_id`, `lookback_days` trailing days re-processed).
{% enddocs %}

{% docs mart_marketing_campaign_daily %}
Campaign performance per day, ready for dashboards and natural-language questions.

**Grain:** one row per platform, per campaign, per day.

Answers e.g. "How much did we spend on Facebook last month?", "Which campaign had the most clicks?",
"Compare Facebook and Snapchat CPC". Always group or filter by `currency_code` when adding up spend.
{% enddocs %}

{% docs currency_code %}
Currency the spend is reported in (ISO code). Facebook accounts report in USD **or** EUR; Snapchat in EUR.
No exchange rates were provided, so spend is **not** converted: never sum spend across currencies.
{% enddocs %}

{% docs spend %}
Amount spent on advertising, in `currency_code`.
{% enddocs %}

{% docs impressions %}
Number of times ads were shown. Missing values from the platform are treated as 0.
{% enddocs %}

{% docs clicks %}
Number of clicks on ads. Missing values from the platform (literal 'null') are treated as 0:
those rows have tiny delivery (median 24 impressions), consistent with "no clicks reported".
{% enddocs %}

{% docs ctr %}
Click-through rate = clicks / impressions. NULL when impressions = 0.
{% enddocs %}

{% docs cpc %}
Cost per click = spend / clicks, in `currency_code`. NULL when clicks = 0 (undefined, not free).
{% enddocs %}

{% docs cpm %}
Cost per 1,000 impressions = spend / impressions x 1,000, in `currency_code`. NULL when impressions = 0.
{% enddocs %}
