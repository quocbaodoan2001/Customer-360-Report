CREATE DATABASE DRM_Project;

USE drm_project;
create table rfm_calculation as
with RFM_Data as(  
SELECT 
    cr.id, 
    DATEDIFF('2022-09-01', MAX(STR_TO_DATE(ct.purchase_date, '%m/%d/%Y'))) AS recency,
    ROUND(1.00 * COUNT(ct.purchase_date) / (DATEDIFF('2022-09-01', STR_TO_DATE(cr.created_date, '%m/%d/%Y'))/365), 2) AS frequency,
    ROUND(1.00 * SUM(ct.GMV) / (DATEDIFF('2022-09-01', STR_TO_DATE(cr.created_date, '%m/%d/%Y'))/365), 0) AS monetory,
    round( DATEDIFF('2022-09-01', STR_TO_DATE(cr.created_date, '%m/%d/%Y'))/365,0)  AS age_contract
FROM 
    drm_project.customer_transaction ct
LEFT JOIN 
    drm_project.customer_registered cr 
ON 
    ct.customerid = cr.id 
GROUP BY 
    cr.id, cr.created_date)
 select *, 
 		row_number () over ( order by recency) as rn_recency,
 		row_number () over ( order by frequency) as rn_frequency,
 		row_number () over ( order by monetory) as rn_monetory
 from RFM_Data;

-------------------------------

USE drm_project;
create table rfm as
with RFM_Segment as (SELECT *, CASE 
	WHEN recency >= min(recency) 
	and recency <= (select recency from drm_project.rfm_calculation WHERE rn_recency = (select round(count(CustomerID)/2 * 0.25, 0) from drm_project.rfm_calculation)) then 1
	WHEN rn_recency > (select recency from drm_project.rfm_calculation WHERE rn_recency = (select round(count(CustomerID)/2 * 0.25, 0) from drm_project.rfm_calculation)) 
	and recency <= (select recency from drm_project.rfm_calculation WHERE rn_recency = (select round(count(CustomerID)/2 * 0.5, 0) from drm_project.rfm_calculation)) then 2
	WHEN recency > (select recency from drm_project.rfm_calculation WHERE rn_recency = (select round(count(CustomerID)/2 * 0.5, 0) from drm_project.rfm_calculation)) 
	and recency <= (select recency from drm_project.rfm_calculation WHERE rn_recency = (select round(count(CustomerID)/2 * 0.75, 0) from drm_project.rfm_calculation)) then 3
	ELSE 4 END as R,
	CASE 
	WHEN frequency >= min(frequency) 
	and frequency <= (select frequency from drm_project.rfm_calculation WHERE rn_frequency = (select round(count(CustomerID)/2 * 0.25, 0) from drm_project.rfm_calculation)) then 1
	WHEN frequency > (select frequency from drm_project.rfm_calculation WHERE rn_frequency = (select round(count(CustomerID)/2 * 0.25, 0) from drm_project.rfm_calculation)) 
	and frequency <= (select frequency from drm_project.rfm_calculation WHERE rn_frequency = (select round(count(CustomerID)/2 * 0.5, 0) from drm_project.rfm_calculation)) then 2
	WHEN frequency > (select frequency from drm_project.rfm_calculation WHERE rn_frequency = (select round(count(CustomerID)/2 * 0.5, 0) from drm_project.rfm_calculation)) 
	and frequency <= (select frequency from drm_project.rfm_calculation WHERE rn_frequency = (select round(count(CustomerID)/2 * 0.75, 0) from drm_project.rfm_calculation)) then 3
	ELSE 4 END as F,
	CASE 
	WHEN monetory >= min(monetory) 
	and monetory <= (select monetory from drm_project.rfm_calculation WHERE rn_monetory = (select round(count(CustomerID)/2 * 0.25, 0) from drm_project.rfm_calculation)) then 1
	WHEN monetory > (select monetory from drm_project.rfm_calculation WHERE rn_monetory = (select round(count(CustomerID)/2 * 0.25, 0) from drm_project.rfm_calculation)) 
	and monetory <= (select monetory from drm_project.rfm_calculation WHERE rn_monetory = (select round(count(CustomerID)/2 * 0.5, 0) from drm_project.rfm_calculation)) then 2
	WHEN monetory > (select monetory from drm_project.rfm_calculation WHERE rn_monetory = (select round(count(CustomerID)/2 * 0.5, 0) from drm_project.rfm_calculation)) 
	and monetory <= (select monetory from drm_project.rfm_calculation WHERE rn_monetory = (select round(count(CustomerID)/2 * 0.75, 0) from drm_project.rfm_calculation)) then 3
	ELSE 4 END as M
 from drm_project.rfm_calculation 
group by CustomerID, rn_recency,rn_frequency,rn_monetory, recency,frequency,monetory)
select  *, concat(R,F,M) as RFM_Score, 
        CASE 
        WHEN R IN (3, 4) AND F IN (3, 4) AND M IN (3, 4) THEN 'Star' 
        WHEN R IN (2, 3) AND F IN (3, 4) AND M IN (3, 4) THEN 'Cash Cow'  
        WHEN R IN (3,4) AND F IN (1, 2) AND M IN (2, 3) THEN 'Big Question' 
        WHEN R IN (1,2) AND F IN (1, 2) AND M IN (1, 2) THEN 'Dog'   
        ELSE 'Other' end as BCG_Maxtrix
from RFM_Segment;

-------------------------





