{#
  production: use the layer schema from dbt_project.yml (staging / intermediate / marketing / elementary).
  dev and ci: everything lands in the target's own schema (e.g. dbt_chinedu, pr_12), so each developer
  and each pull request is isolated and easy to drop. Elementary gets "<schema>_elementary".
#}
{% macro generate_schema_name(custom_schema_name, node) -%}
    {%- if target.name == 'production' and custom_schema_name is not none -%}
        {{ custom_schema_name | trim }}
    {%- elif custom_schema_name == 'elementary' -%}
        {{ target.schema }}_elementary
    {%- else -%}
        {{ target.schema }}
    {%- endif -%}
{%- endmacro %}
