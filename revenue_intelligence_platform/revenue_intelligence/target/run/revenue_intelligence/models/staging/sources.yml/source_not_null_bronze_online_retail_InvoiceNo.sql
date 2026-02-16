
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select InvoiceNo
from "revenue_intelligence"."bronze"."online_retail"
where InvoiceNo is null



  
  
      
    ) dbt_internal_test