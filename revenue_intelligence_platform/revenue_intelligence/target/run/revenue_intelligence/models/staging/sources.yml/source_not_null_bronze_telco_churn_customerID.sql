
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select customerID
from "revenue_intelligence"."bronze"."telco_churn"
where customerID is null



  
  
      
    ) dbt_internal_test