
    
    

select
    customerID as unique_field,
    count(*) as n_records

from "revenue_intelligence"."bronze"."telco_churn"
where customerID is not null
group by customerID
having count(*) > 1


