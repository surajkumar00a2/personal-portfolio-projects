
    
    

with all_values as (

    select
        transaction_type as value_field,
        count(*) as n_records

    from "revenue_intelligence"."gold"."fact_invoice"
    group by transaction_type

)

select *
from all_values
where value_field not in (
    'SALE','REFUND','CREDIT_NOTE'
)


