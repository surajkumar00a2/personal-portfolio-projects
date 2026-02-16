
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select revenue_key
from "revenue_intelligence"."gold"."fact_revenue"
where revenue_key is null



  
  
      
    ) dbt_internal_test