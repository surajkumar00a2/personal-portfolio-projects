
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select invoice_no
from "revenue_intelligence"."silver"."stg_online_retail"
where invoice_no is null



  
  
      
    ) dbt_internal_test