
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select mrr
from "revenue_intelligence"."gold"."fact_revenue"
where mrr is null



  
  
      
    ) dbt_internal_test