
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    

select
    contract_surrogate_key as unique_field,
    count(*) as n_records

from "revenue_intelligence"."gold"."dim_contract"
where contract_surrogate_key is not null
group by contract_surrogate_key
having count(*) > 1



  
  
      
    ) dbt_internal_test