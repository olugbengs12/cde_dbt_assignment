{#
  Returns NULL instead of failing / returning a misleading 0 when the denominator is 0 or NULL.
  e.g. CPC for a day with zero clicks is "undefined", not 0.
#}
{% macro safe_divide(numerator, denominator) -%}
    case
        when {{ denominator }} is null or {{ denominator }} = 0 then null
        else cast({{ numerator }} as double) / cast({{ denominator }} as double)
    end
{%- endmacro %}
