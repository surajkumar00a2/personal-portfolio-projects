
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    

select
    invoice_line_key as unique_field,
    count(*) as n_records

from "revenue_intelligence"."gold"."fact_invoice"
where invoice_line_key is not null
group by invoice_line_key
having count(*) > 1



  
  
      
    ) dbt_internal_test