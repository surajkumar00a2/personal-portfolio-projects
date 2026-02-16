
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select invoice_line_key
from "revenue_intelligence"."gold"."fact_invoice"
where invoice_line_key is null



  
  
      
    ) dbt_internal_test