drop table if exists #a
SELECT emp.POD  AS "SFDC_Latest_PRM_Pod"
	 , dc.client_id
	 , d_date.DATE AS "d_date"
	 , emp.EMPLOYEENAME  AS "d_emp_research_owner.employeename"
	 , tpv_product.product_type
	 , COUNT(DISTINCT f_tpv.F_TPV_KEY ) AS TPV
	 , CASE WHEN tpv_product.Product_Type = 'Phone Consultation' then 1*count(DISTINCT f_tpv.F_TPV_KEY)
			WHEN tpv_product.Product_Type in ('BTC', 'Survey') then 4*count(DISTINCT f_tpv.F_TPV_KEY)
			WHEN tpv_product.Product_Type = 'In Person Event' then 1.5*count(DISTINCT f_tpv.F_TPV_KEY) 
			WHEN tpv_product.Product_Type = 'Visit' then 2*count(DISTINCT f_tpv.F_TPV_KEY)
			WHEN tpv_product.Product_Type = 'Virtual Event' then 0.33*count(DISTINCT f_tpv.F_TPV_KEY) else 0 end as		 wTPV
into #a
FROM WARS.bi.F_TPV AS f_tpv 
left JOIN WARS.bi.D_DATE  AS d_date ON d_date.DATE_KEY = f_tpv.TPV_DATE_KEY
left JOIN (select c.PL_NAME
				, c.CONTACT_ID
				, c.D_USER_KEY
				, d.USER_RESEARCH_OWNER_D_EMP_KEY
				, d.START_DATE 
		   from (select PL_NAME
					  , CONTACT_ID
					  , D_USER_KEY 
				 from WARS.bi.d_user
				 )c
		   join (select WARS.bi.d_user.CONTACT_ID
					  , WARS.bi.d_user.USER_RESEARCH_OWNER_D_EMP_KEY
					  , WARS.bi.d_user.START_DATE 
				 from WARS.bi.d_user
			     join (select CONTACT_ID
							, max(START_DATE) as START_DATE 
					   from WARS.bi.d_user 
					   group by contact_id
					   ) b on WARS.bi.d_user.CONTACT_ID=b.CONTACT_ID and WARS.bi.d_user.START_DATE=b.START_DATE
				) d on c.CONTACT_ID=d.CONTACT_ID
		   ) a ON a.D_USER_KEY = f_tpv.D_USER_KEY
LEFT JOIN WARS.bi.D_PRODUCT  AS tpv_product ON f_tpv.D_PRODUCT_KEY = tpv_product.D_PRODUCT_KEY
LEFT JOIN WARS.bi.d_emp AS emp ON emp.D_EMP_KEY = a.USER_RESEARCH_OWNER_D_EMP_KEY
left join WARS.BI.D_CLIENT dc on dc.D_CLIENT_KEY = f_tpv.D_CLIENT_KEY
WHERE Year(d_date.DATE)=2020 and (a.PL_NAME = 'Greater China') and (tpv_product.PRODUCT_NAME not in ('Transcript','Webcast Replay','Consultation Transcript' ))
GROUP BY emp.POD 
	   , dc.client_id 
	   , d_date.DATE
	   , emp.EMPLOYEENAME 
	   , tpv_product.product_type
ORDER BY 7 DESC

select SFDC_Latest_PRM_Pod
	 , product_type
	 , sum(case when Month(d_date) =1 then Convert(Numeric(38, 2),TPV) else 0 end) as 'Jan_TPV'
	 , sum(case when Month(d_date) =2 then Convert(Numeric(38, 2),TPV) else 0 end) as 'Feb_TPV'
	 , sum(case when Month(d_date) =3 then Convert(Numeric(38, 2),TPV) else 0 end) as 'Mar_TPV'
	 , sum(case when Month(d_date) =4 then Convert(Numeric(38, 2),TPV) else 0 end) as 'Apr_TPV'
	 , sum(case when Month(d_date) =5 then Convert(Numeric(38, 2),TPV) else 0 end) as 'May_TPV'
	 , sum(case when Month(d_date) =6 then Convert(Numeric(38, 2),TPV) else 0 end) as 'Jun_TPV'
	 , sum(case when Month(d_date) =7 then Convert(Numeric(38, 2),TPV) else 0 end) as 'Jul_TPV'
	 , sum(case when Month(d_date) =8 then Convert(Numeric(38, 2),TPV) else 0 end) as 'Aug_TPV'
	 , sum(case when Month(d_date) =9 then Convert(Numeric(38, 2),TPV) else 0 end) as 'Sep_TPV'
	 , sum(case when Month(d_date) =10 then Convert(Numeric(38, 2),TPV) else 0 end) as 'Oct_TPV'
	 , sum(case when Month(d_date) =11 then Convert(Numeric(38, 2),TPV) else 0 end) as 'Nov_TPV'
	 , round(sum(case when Month(d_date)!=12 then Convert(Numeric(38, 2),TPV)/11 else 0 end),0) as 'Dec_TPV'
	 , sum(case when Month(d_date) =1 then wTPV else 0 end) as 'Jan_wTPV'
	 , sum(case when Month(d_date) =2 then wTPV else 0 end) as 'Feb_wTPV'
	 , sum(case when Month(d_date) =3 then wTPV else 0 end) as 'Mar_wTPV'
	 , sum(case when Month(d_date) =4 then wTPV else 0 end) as 'Apr_wTPV'
	 , sum(case when Month(d_date) =5 then wTPV else 0 end) as 'May_wTPV'
	 , sum(case when Month(d_date) =6 then wTPV else 0 end) as 'Jun_wTPV'
	 , sum(case when Month(d_date) =7 then wTPV else 0 end) as 'Jul_wTPV'
	 , sum(case when Month(d_date) =8 then wTPV else 0 end) as 'Aug_wTPV'
	 , sum(case when Month(d_date) =9 then wTPV else 0 end) as 'Sep_wTPV'
	 , sum(case when Month(d_date) =10 then wTPV else 0 end) as 'Oct_wTPV'
	 , sum(case when Month(d_date) =11 then wTPV else 0 end) as 'Nov_wTPV'
	 , sum(case when Month(d_date) !=12 then wTPV/11 else 0 end) as 'Dec_wTPV'
from #a
group by SFDC_Latest_PRM_Pod,product_type
order by SFDC_Latest_PRM_Pod,product_type


SELECT *FROM #a
order by client_id

select sum(TPV) from #a

select sum(wTPV) from #a


select d_date.DATE
	 , f_tpv.F_TPV_KEY
	 , a.PL_NAME
FROM WARS.bi.F_TPV AS f_tpv 
left JOIN WARS.bi.D_DATE AS d_date ON d_date.DATE_KEY = f_tpv.TPV_DATE_KEY
left JOIN (select c.PL_NAME
				, c.CONTACT_ID
				, c.D_USER_KEY
				, d.USER_RESEARCH_OWNER_D_EMP_KEY
				, d.START_DATE 
			from(select PL_NAME,CONTACT_ID
					  , D_USER_KEY
					  , USER_RESEARCH_OWNER_D_EMP_KEY 
				 from WARS.bi.d_user
				 group by PL_NAME, CONTACT_ID,D_USER_KEY, USER_RESEARCH_OWNER_D_EMP_KEY
				 )c
			join (select WARS.bi.d_user.CONTACT_ID
					   , WARS.bi.d_user.USER_RESEARCH_OWNER_D_EMP_KEY
					   , WARS.bi.d_user.START_DATE 
				  from WARS.bi.d_user
				  join (select CONTACT_ID
							 , max(START_DATE) as START_DATE 
						from WARS.bi.d_user 
						group by contact_id
						) b on WARS.bi.d_user.CONTACT_ID=b.CONTACT_ID and WARS.bi.d_user.START_DATE=b.START_DATE
				 ) d on c.CONTACT_ID=d.CONTACT_ID
		   )a ON a.D_USER_KEY = f_tpv.D_USER_KEY
LEFT JOIN WARS.bi.D_PRODUCT  AS tpv_product ON f_tpv.D_PRODUCT_KEY = tpv_product.D_PRODUCT_KEY
LEFT JOIN WARS.bi.d_emp AS d_user_research_owner ON d_user_research_owner.D_EMP_KEY = a.USER_RESEARCH_OWNER_D_EMP_KEY
left join WARS.BI.D_CLIENT dc on dc.D_CLIENT_KEY = f_tpv.D_CLIENT_KEY
WHERE Year(d_date.DATE)=2020 and a.PL_NAME = 'Greater China' 
and dc.client_id=8
order by d_date.DATE

select * from WARS.bi.d_user
where NAME='Cindy Yan'