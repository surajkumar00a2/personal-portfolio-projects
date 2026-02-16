
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    

select
    revenue_key as unique_field,
    count(*) as n_records

from "revenue_intelligence"."gold"."fact_revenue"
where revenue_key is not null
group by revenue_key
having count(*) > 1



  
  
      
    ) dbt_internal_test