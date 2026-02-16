
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select churn_probability
from "revenue_intelligence"."silver"."stg_telco_churn"
where churn_probability is null



  
  
      
    ) dbt_internal_test