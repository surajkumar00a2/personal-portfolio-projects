
    
    

select
    product_surrogate_key as unique_field,
    count(*) as n_records

from "revenue_intelligence"."gold"."dim_product"
where product_surrogate_key is not null
group by product_surrogate_key
having count(*) > 1


