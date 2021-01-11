select a.*
	 , COUNT(DISTINCT CASE WHEN TPV.RP_STATUS = 'CRP' THEN TPV.F_TPV_KEY   ELSE NULL END) AS CRP
	 , COUNT(DISTINCT CASE WHEN TPV.RP_STATUS = 'RP90' THEN TPV.F_TPV_KEY   ELSE NULL END) AS RP90
	 , COUNT(DISTINCT CASE WHEN TPV.RP180_STATUS = 'RP180' THEN TPV.F_TPV_KEY   ELSE NULL END) AS RP180
	 , COUNT(DISTINCT CASE WHEN datediff(day,a.CM_FIRST_PAID_DATE,TPV.TPV_DATE)<=180 THEN TPV.F_TPV_KEY ELSE NULL END) AS TPV180
	 , COUNT(DISTINCT CASE WHEN datediff(day,a.CM_FIRST_PAID_DATE,TPV.TPV_DATE)<=360 THEN TPV.F_TPV_KEY ELSE NULL END) AS TPV360
	 , COUNT(DISTINCT CASE WHEN datediff(day,a.CM_FIRST_PAID_DATE,TPV.TPV_DATE)<=1095 THEN TPV.F_TPV_KEY ELSE NULL END) AS TPV3Y
	 , COUNT(DISTINCT TPV.F_TPV_KEY) as "ALL_TPV"
from WARS.BI.D_COUNCIL_MEMBER AS CM
left join WARS.BI.F_TPV AS TPV ON CM.D_COUNCIL_MEMBER_KEY = TPV.D_COUNCIL_MEMBER_KEY
left join (select COUNCIL_MEMBER_ID
				, MIN(TERMS_CONDITIONS_START_DATE) AS CM_CONVERSION_DATE
		   FROM WARS.BI.D_COUNCIL_MEMBER
		   GROUP BY COUNCIL_MEMBER_ID
		   ) CD on CM.COUNCIL_MEMBER_ID=CD.COUNCIL_MEMBER_ID
left join WARS.BI.D_USER U ON TPV.d_user_key=u.d_user_key
left join WARS.BI.D_PRODUCT DP ON TPV.D_PRODUCT_KEY=DP.D_PRODUCT_KEY
left join (select CM.COUNCIL_MEMBER_ID
				, Year(CD.CM_CONVERSION_DATE) as CM_CONVERSION_YEAR
				, min(TPV.TPV_DATE) as CM_FIRST_PAID_DATE
			from WARS.BI.D_COUNCIL_MEMBER AS CM
			left join WARS.BI.F_TPV AS TPV ON CM.D_COUNCIL_MEMBER_KEY = TPV.D_COUNCIL_MEMBER_KEY
			left join (select COUNCIL_MEMBER_ID
							, MIN(TERMS_CONDITIONS_START_DATE) AS CM_CONVERSION_DATE
						FROM WARS.BI.D_COUNCIL_MEMBER
						GROUP BY COUNCIL_MEMBER_ID
						) CD on CM.COUNCIL_MEMBER_ID=CD.COUNCIL_MEMBER_ID
			left join WARS.BI.D_USER U ON TPV.d_user_key=u.d_user_key
			left join WARS.BI.D_PRODUCT DP ON TPV.D_PRODUCT_KEY=DP.D_PRODUCT_KEY
			where U.PL_NAME='Greater China'
			and DP.PRODUCT_TYPE LIKE '%Phone Consultation%'
			and (CM.country like '%Hong Kong%' or CM.country like '%China%' or CM.country like '%Taiwan%')
			and Year(CD.CM_CONVERSION_DATE) >=2015
			group by CM.COUNCIL_MEMBER_ID, YEAR(CD.CM_CONVERSION_DATE)
			) a on CM.COUNCIL_MEMBER_ID=a.COUNCIL_MEMBER_ID
where U.PL_NAME='Greater China'
and DP.PRODUCT_TYPE LIKE '%Phone Consultation%'
and (CM.country like '%Hong Kong%' or CM.country like '%China%' or CM.country like '%Taiwan%')
and Year(CD.CM_CONVERSION_DATE) >=2015
group by a.COUNCIL_MEMBER_ID, a.CM_CONVERSION_YEAR, a.CM_FIRST_PAID_DATE
order by 2,1


select CM.COUNCIL_MEMBER_ID
	 , CM.TERMS_CONDITIONS_START_DATE
	 , TPV.TPV_DATE
FROM wars.bi.D_COUNCIL_MEMBER CM 
left join wars.bi.F_TPV AS TPV ON CM.D_COUNCIL_MEMBER_KEY = TPV.D_COUNCIL_MEMBER_KEY
where council_member_id=674211
order by 2



select Year(PJ.CREATE_DATE) as CREATE_YEAR
	 , CM.COUNCIL_MEMBER_ID
	 , count(distinct PJ.PROJECT_ID) as start_projects
from WARS.BI.D_COUNCIL_MEMBER AS CM
left join WARS.BI.F_TPV AS TPV ON CM.D_COUNCIL_MEMBER_KEY = TPV.D_COUNCIL_MEMBER_KEY
left join WARS.BI.F_PROJECT AS PJ ON PJ.F_PROJECT_KEY = TPV.F_PROJECT_KEY
left join WARS.BI.D_USER U ON TPV.d_user_key=u.d_user_key
left join WARS.BI.D_PRODUCT DP ON TPV.D_PRODUCT_KEY=DP.D_PRODUCT_KEY
where U.PL_NAME='Greater China'
and DP.PRODUCT_TYPE LIKE '%Phone Consultation%'
and (CM.country like '%Hong Kong%' or CM.country like '%China%' or CM.country like '%Taiwan%')
and Year(PJ.CREATE_DATE)>=2015
group by Year(PJ.CREATE_DATE), CM.COUNCIL_MEMBER_ID
order by 1,2



select distinct a.COUNCIL_MEMBER_ID
	 , a.CM_CONVERSION_YEAR
	 , case when sum(a.Active2015)>=1 then 1 else 0 end as '2015Active'
	 , case when sum(a.Active2016)>=1 then 1 else 0 end as '2016Active'
	 , case when sum(a.Active2017)>=1 then 1 else 0 end as '2017Active'
	 , case when sum(a.Active2018)>=1 then 1 else 0 end as '2018Active'
	 , case when sum(a.Active2019)>=1 then 1 else 0 end as '2019Active'
	 , case when sum(a.Active2020)>=1 then 1 else 0 end as '2020Active'
from (select CM.COUNCIL_MEMBER_ID
		   , Year(CD.CM_CONVERSION_DATE) as CM_CONVERSION_YEAR
		   , CM.TERMS_CONDITIONS_START_DATE
		   , CM.TERMS_CONDITIONS_END_DATE
		   , case when Year(CM.TERMS_CONDITIONS_START_DATE)<=2015 and Year(CM.TERMS_CONDITIONS_END_DATE)>=2015 then 1 else 0 end as 'Active2015'
		   , case when Year(CM.TERMS_CONDITIONS_START_DATE)<=2016 and Year(CM.TERMS_CONDITIONS_END_DATE)>=2016 then 1 else 0 end as 'Active2016'
		   , case when Year(CM.TERMS_CONDITIONS_START_DATE)<=2017 and Year(CM.TERMS_CONDITIONS_END_DATE)>=2017 then 1 else 0 end as 'Active2017'
		   , case when Year(CM.TERMS_CONDITIONS_START_DATE)<=2018 and Year(CM.TERMS_CONDITIONS_END_DATE)>=2018 then 1 else 0 end as 'Active2018'
		   , case when Year(CM.TERMS_CONDITIONS_START_DATE)<=2019 and Year(CM.TERMS_CONDITIONS_END_DATE)>=2019 then 1 else 0 end as 'Active2019'
		   , case when Year(CM.TERMS_CONDITIONS_START_DATE)<=2020 and Year(CM.TERMS_CONDITIONS_END_DATE)>=2020 then 1 else 0 end as 'Active2020'
	   from WARS.BI.D_COUNCIL_MEMBER AS CM
	   left join WARS.BI.F_TPV AS TPV ON CM.D_COUNCIL_MEMBER_KEY = TPV.D_COUNCIL_MEMBER_KEY
	   left join (select COUNCIL_MEMBER_ID
					   , MIN(TERMS_CONDITIONS_START_DATE) AS CM_CONVERSION_DATE
				  FROM WARS.BI.D_COUNCIL_MEMBER
				  GROUP BY COUNCIL_MEMBER_ID
				  ) CD on CM.COUNCIL_MEMBER_ID=CD.COUNCIL_MEMBER_ID
	   left join WARS.BI.D_USER U ON TPV.d_user_key=u.d_user_key
	   left join WARS.BI.D_PRODUCT DP ON TPV.D_PRODUCT_KEY=DP.D_PRODUCT_KEY
	   where U.PL_NAME='Greater China'
	   and DP.PRODUCT_TYPE LIKE '%Phone Consultation%'
	   and (CM.country like '%Hong Kong%' or CM.country like '%China%' or CM.country like '%Taiwan%')
	   and Year(CD.CM_CONVERSION_DATE) is not null
	   group by CM.COUNCIL_MEMBER_ID
			  , YEAR(CD.CM_CONVERSION_DATE)
			  , CM.TERMS_CONDITIONS_START_DATE
			  , CM.TERMS_CONDITIONS_END_DATE
	   ) a
group by COUNCIL_MEMBER_ID, CM_CONVERSION_YEAR
order by 1,2