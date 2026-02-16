
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select product_surrogate_key
from "revenue_intelligence"."gold"."dim_product"
where product_surrogate_key is null



  
  
      
    ) dbt_internal_test