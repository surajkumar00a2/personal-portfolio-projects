
    
    

select
    revenue_key as unique_field,
    count(*) as n_records

from "revenue_intelligence"."gold"."fact_revenue"
where revenue_key is not null
group by revenue_key
having count(*) > 1


