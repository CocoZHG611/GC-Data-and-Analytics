--Select revenue and subscription--
DROP TABLE IF EXISTS #SUB;
select dc.client_id
	 , dc.client_name
	 , fsub.subscription_name
	 , fsub.contract_type as CT
	 , fsub.subscription_amount_usd as sub_amount
	 , fssd.DATE as SubStartDate
	 , fsed.DATE as SubEndDate 
INTO #SUB
from WARS.BI.F_GL fgl 
left join WARS.BI.F_SUBSCRIPTION fsub on fgl.F_SUBSCRIPTION_KEY=fsub.F_SUBSCRIPTION_KEY
left join WARS.BI.D_DATE fssd on fssd.DATE_KEY = fsub.Start_Date_Key
left join WARS.BI.D_DATE fsed on fsed.DATE_KEY = fsub.Expiry_Date_Key
left join WARS.BI.D_CLIENT dc on dc.D_CLIENT_KEY = fgl.D_CLIENT_KEY
where fsub.F_SUBSCRIPTION_KEY is not null and year(fsed.DATE)>2019 and year(fssd.DATE)<2021 and dc.client_id=fsub.client_id
group by dc.client_id
	   , dc.client_name
	   , fsub.subscription_name
	   , fsub.contract_type
	   , fsub.subscription_amount_usd
	   , fssd.DATE
	   , fsed.DATE


drop table if exists #SMR;
select #SUB.*
	 , r.d_date_date
	 , r.PL_NAME
into #SMR
from #SUB
join (SELECT CONVERT(VARCHAR(10),d_date.DATE ,120) AS 'd_date_date'
		   , d_client.client_name
		   , d_client.client_id
		   , d_client.PL_NAME
		   , f_project.PROJECT_ID
		   , f_project.TITLE
	  FROM WARS.bi.F_GL AS f_gl
	  LEFT JOIN WARS.bi.d_client AS d_client ON f_gl.D_CLIENT_KEY = d_client.D_CLIENT_KEY
	  LEFT JOIN WARS.bi.D_GL_ACCOUNT  AS d_gl_account ON f_gl.D_GL_ACCOUNT_KEY = d_gl_account.D_GL_ACCOUNT_KEY
	  LEFT JOIN WARS.bi.D_DATE  AS d_date ON f_gl.TRX_DATE_KEY = d_date.DATE_KEY
	  LEFT JOIN WARS.bi.F_PROJECT AS f_project ON f_gl.F_PROJECT_KEY = F_PROJECT.F_PROJECT_KEY
	  WHERE Year (d_date.DATE) = 2020 AND (d_gl_account.GL_ACCOUNT_TYPE = 'Revenue')
	  GROUP BY d_client.client_name
			 , d_client.client_id
			 , CONVERT(VARCHAR(10), d_date.DATE ,120)
			 , d_client.PL_NAME
			 , f_project.PROJECT_ID
			 , f_project.TITLE
	  ) r 
on #SUB.client_id=r.client_id
order by #SUB.client_id, #SUB.CT

--select * from #SMR order by client_id

--select all possible ACV--
drop table if exists #ACV;
select client_id
	 , client_name
	 , PL_NAME
	 , subscription_name
	 , CT
	 , sub_amount
	 , SubStartDate
	 , SubEndDate
	 , cast(sub_amount/Convert(Numeric(38, 0),DATEDIFF(day, SubStartDate, SubEndDate))*365 as numeric(36,2)) AS ACV
into #ACV
from #SMR
group by client_id
	   , client_name
	   , PL_NAME
	   , subscription_name
	   , CT
	   , sub_amount
	   , SubStartDate
	   , SubEndDate

--select *from #ACV

--Detailed Account information
drop table if exists #DAI
select dc.client_id as 'Client_ID'
	 , dc.client_name as 'Account_Name'
	 , dc.COUNTRY as 'Account_Country'
	 , SFA.Account_Owner_Text__c as 'Account_Owner'
	 , #ACV.subscription_name as 'Latest Active Subscription'
	 , #ACV.SubStartDate as 'Contract_Start_Date'
	 , #ACV.SubEndDate as 'Contract_End_Date'
	 , #ACV.sub_amount as 'Contract_Value'
	 , #ACV.ACV as 'Annual_Contract_Value'
	 --, a.Opportunity_Owner
	 --, a.Opportunity_Name
	 , CUR.CUR_SFDC_SALES  AS "Majority_Sales_Owner"
	 , CUR.CUR_SFDC_RM  AS "Majority_PRM_Owner"
into #DAI
from  WARS.bi.F_TPV  AS f_tpv
left join WARS.BI.D_CLIENT dc on dc.D_CLIENT_KEY = f_tpv.D_CLIENT_KEY
left join SFDC.dbo.Account SFA on dc.CLIENT_ID = SFA.VegaID__c
left join (select #ACV.* 
		   from (select client_id
					  , max(SubStartDate) as SubStartDate 
				 from #ACV 
				 group by client_id
				 ) d1 
			join #ACV on d1.client_id=#ACV.client_id and d1.SubStartDate=#ACV.SubStartDate
			where #ACV.PL_NAME is not null
		   ) #ACV on dc.CLIENT_ID =#ACV.client_id
--left join (select SFO.AccountId
--				, SFO.Name as 'Opportunity_Name'
--				, SFO.Opportunity_Owner_Name__c as 'Opportunity_Owner'
--				, SFO.start_date__c as Start_dates 
--			from (select SFO.AccountId
--					   , max(SFO.start_date__c) as Start_dates
--				  from sfdc.dbo.Opportunity SFO
--				  where SFO.StageName = 'Closed Won' and Year(SFO.start_date__c)=2020
--				  group by SFO.AccountId
--				  ) a1 
--			join sfdc.dbo.Opportunity SFO on a1.AccountId=SFO.AccountId and a1.Start_dates=SFO.start_date__c
--		   ) a on SFA.ID=a.AccountId
left JOIN WARS.bi.D_DATE  AS d_date ON d_date.DATE_KEY = f_tpv.TPV_DATE_KEY
left join WARS.BI.D_USER du on du.D_USER_KEY = f_tpv.D_USER_KEY
left join (SELECT RANK() OVER (PARTITION BY DUX.contact_ID ORDER BY DUX.start_date desc) as [Rank]
				, DUX.contact_ID
				, C_BD.EMPLOYEENAME as CUR_SFDC_SALES
				, C_RM.EMPLOYEENAME as CUR_SFDC_RM
				, C_RM.POD as CUR_SFDC_RM_POD
		   FROM WARS.BI.D_USER DUX
		   left join WARS.BI.D_EMP C_BD on DUX.USER_SALES_OWNER_D_EMP_KEY = C_BD.D_EMP_KEY
		   left join WARS.BI.D_EMP C_RM on DUX.USER_RESEARCH_OWNER_D_EMP_KEY = C_RM.D_EMP_KEY
		   ) CUR on CUR.contact_id= du.contact_id and CUR.RANK = 1
LEFT JOIN WARS.bi.D_PRODUCT  AS tpv_product ON f_tpv.D_PRODUCT_KEY = tpv_product.D_PRODUCT_KEY
WHERE Year(d_date.DATE)=2020 and du.PL_NAME='Greater China' and tpv_product.PRODUCT_NAME not in ('Transcript','Webcast Replay','Consultation Transcript' )
and dc.client_id is not null and dc.COUNTRY!='UNKNOWN' and SFA.Account_Owner_Text__c is not null and dc.PL_NAME is not null
GROUP BY dc.client_id 
	   , dc.client_name 
	   , dc.COUNTRY 
	   , SFA.Account_Owner_Text__c 
	   , #ACV.subscription_name 
	   , #ACV.SubStartDate 
	   , #ACV.SubEndDate 
	   , #ACV.sub_amount
	   , #ACV.ACV
	   , CUR.CUR_SFDC_SALES
	   , CUR.CUR_SFDC_RM
order by dc.client_id

select * from #DAI order by Client_ID

--select distinct RP_STATUS from WARS.BI.F_TPV where RP_STATUS IS NOT NULL

--select CLIENT_ID,CLIENT_NAME, COUNTRY from WARS.BI.D_CLIENT where client_id=16539
--from WARS.BI.D_CLIENT dc join WARS.BI.D_EMP H_BD on dc.CLIENT_PRIMARY_SALES_D_EMP_KEY = H_BD.D_EMP_KEY

--select top 100* from WARS.BI.D_COUNCIL_MEMBER where country like '%China%' or country like '%Hong Kong%' or country like '%Taiwan%'

DROP TABLE IF EXISTS #USAGE;
SELECT dd.DATE as TPV_DATE
	 , tpv.project_id
	 , dp.product_name
	 , dp.product_type
	 , tpv.tpv_date_key
	 , DCM.COUNTRY
	 , f_proj.CM_RATE_FOR_PROJECT
	 , tpv.RP_STATUS
	 , COUNT(DISTINCT tpv.F_TPV_KEY) AS TPV
	 , CASE WHEN DP.Product_Type = 'Phone Consultation' then 1*COUNT(DISTINCT tpv.F_TPV_KEY)
			WHEN DP.Product_Type in ('BTC', 'Survey') then 4*COUNT(DISTINCT tpv.F_TPV_KEY)
			WHEN DP.Product_Type = 'In Person Event' then 1.5*COUNT(DISTINCT tpv.F_TPV_KEY)
			WHEN DP.Product_Type = 'Visit' then 2*COUNT(DISTINCT tpv.F_TPV_KEY)
			WHEN DP.PRODUCT_NAME in ('Transcript','Webcast Replay') then 0
			WHEN DP.Product_Type = 'Virtual Event' then 0.33*COUNT(DISTINCT tpv.F_TPV_KEY) else 0 end as	 wTPV
	 , dc.client_id
	 , dc.client_name
	 , du.PL_Name as PN
	 , dc.PL_NAME
	 , CUR.CUR_SFDC_SALES
	 , CUR.CUR_SFDC_RM
	 , fssd.DATE as SubStartDate
	 , fsed.DATE as SubEndDate
INTO #USAGE
FROM WARS.BI.F_TPV tpv
left join WARS.BI.D_DATE dd on dd.DATE_KEY = tpv.TPV_DATE_KEY
left join WARS.BI.F_SUBSCRIPTION fsub on fsub.F_SUBSCRIPTION_KEY = tpv.F_SUBSCRIPTION_KEY
left join WARS.BI.D_COUNCIL_MEMBER DCM on DCM.D_COUNCIL_MEMBER_KEY = tpv.D_COUNCIL_MEMBER_KEY
left join WARS.BI.D_DATE fssd on fssd.DATE_KEY = fsub.Start_Date_Key
left join WARS.BI.D_DATE fsed on fsed.DATE_KEY = fsub.Expiry_Date_Key
left join WARS.BI.D_PRODUCT dp on dp.D_PRODUCT_KEY = tpv.D_PRODUCT_KEY
left join WARS.BI.D_CLIENT dc on dc.D_CLIENT_KEY = tpv.D_CLIENT_KEY
left join WARS.BI.D_USER du on du.D_USER_KEY = tpv.D_USER_KEY
left join WARS.BI.F_PROJECT fp on fp.F_PROJECT_KEY = tpv.F_PROJECT_KEY
left join WARS.BI.F_PROJECT_FOLDER fpf on fpf.F_PROJECT_FOLDER_KEY = fp.F_PROJECT_FOLDER_KEY
left join WARS.BI.F_PROJECT_MEETING f_proj on f_proj.F_PROJECT_MEETING_KEY = tpv.F_PROJECT_MEETING_KEY
left join WARS.BI.D_EMP H_BD on du.USER_SALES_OWNER_D_EMP_KEY = H_BD.D_EMP_KEY
left join WARS.BI.D_EMP H_RM on du.USER_RESEARCH_OWNER_D_EMP_KEY = H_RM.D_EMP_KEY
left join WARS.BI.D_EMP X_RM on fp.PRIMARY_RM_D_EMP_KEY = X_RM.D_EMP_KEY
left join WARS.BI.D_EMP X_DLG on fp.DELEGATE_RM_D_EMP_KEY = X_DLG.D_EMP_KEY
left join (SELECT RANK() OVER (PARTITION BY DUX.contact_ID ORDER BY DUX.start_date desc) as [Rank]
				, DUX.contact_ID
				, C_BD.EMPLOYEENAME as CUR_SFDC_SALES
				, C_RM.EMPLOYEENAME as CUR_SFDC_RM
				, C_RM.POD as CUR_SFDC_RM_POD
		   FROM WARS.BI.D_USER DUX
		   left join WARS.BI.D_EMP C_BD on DUX.USER_SALES_OWNER_D_EMP_KEY = C_BD.D_EMP_KEY
		   left join WARS.BI.D_EMP C_RM on DUX.USER_RESEARCH_OWNER_D_EMP_KEY = C_RM.D_EMP_KEY
		   ) CUR on CUR.contact_id= du.contact_id and CUR.RANK = 1
WHERE year(dd.DATE)=2020  and (dp.PRODUCT_NAME not in ('Transcript','Webcast Replay','Consultation Transcript' ))
GROUP BY dd.DATE 
	   , tpv.project_id
	   , dp.product_name
	   , dp.product_type
	   , tpv.tpv_date_key
	   , DCM.COUNTRY
	   , f_proj.CM_RATE_FOR_PROJECT
	   , tpv.RP_STATUS
	   , dc.client_id
	   , dc.client_name
	   , du.PL_Name
	   , dc.PL_NAME
	   , CUR.CUR_SFDC_SALES
	   , CUR.CUR_SFDC_RM
	   , fssd.DATE
	   , fsed.DATE 

--select * from #USAGE where PN='Greater China' order by client_id, PL_NAME,TPV_DATE

DROP TABLE IF EXISTS #MU;
select Month(TPV_DATE) AS TPV_Month
	 , client_id
	 , client_name
	 , PL_NAME,product_type
	 , RP_STATUS,COUNTRY as CM_COUNTRY
	 , CM_RATE_FOR_PROJECT as CM_RATE
	 , sum(TPV) as TPV
	 , sum(wTPV) as wTPV
into #MU
from #USAGE
where YEAR(TPV_DATE)=2020 and PN='Greater China'
group by client_id
	   , client_name
	   , PL_NAME,Year(TPV_DATE)
	   , Month(TPV_DATE)
	   , product_type
	   , RP_STATUS,COUNTRY
	   , CM_RATE_FOR_PROJECT

--select * from #MU 
--order by client_id,TPV_MONTH

drop table if exists #MR;
SELECT MONTH(d_date.DATE) AS 'REV_MONTH'
	 , d_client.client_name
	 , d_client.client_id
	 , d_client.PL_NAME
	 , d_gl_account.MAIN_ACCT_DESCRIPTION_FROM_ANAPLAN  AS 'main_acct_description_from_anaplan'
	 , COALESCE(SUM(f_gl.AMOUNT_USD ), 0) AS 'amount'
INTO #MR
FROM WARS.bi.F_GL  AS f_gl
LEFT JOIN WARS.bi.d_client AS d_client ON f_gl.D_CLIENT_KEY = d_client.D_CLIENT_KEY
LEFT JOIN WARS.bi.D_GL_ACCOUNT  AS d_gl_account ON f_gl.D_GL_ACCOUNT_KEY = d_gl_account.D_GL_ACCOUNT_KEY
LEFT JOIN WARS.bi.D_DATE  AS d_date ON f_gl.TRX_DATE_KEY = d_date.DATE_KEY
WHERE Year (d_date.DATE) = 2020 AND d_gl_account.GL_ACCOUNT_TYPE = 'Revenue' and d_gl_account.MAIN_ACCT_DESCRIPTION_FROM_ANAPLAN='Greater China'
GROUP BY d_client.client_name
	   , d_client.client_id
	   , d_client.PL_NAME
	   , MONTH(d_date.DATE)
	   , d_gl_account.MAIN_ACCT_DESCRIPTION_FROM_ANAPLAN

--select * from #MR where client_id =8 order by client_id


--All data with basic account information
drop table if exists #DATA
select info.ACCOUNT_NAME
	 , info.Account_Country
	 , info.Account_Owner
	 , datas.* 
into #DATA
from (select distinct dc.client_id as 'Client_ID'
					, dc.client_name as 'Account_Name'
					, dc.COUNTRY as 'Account_Country'
					, SFA.Account_Owner_Text__c as 'Account_Owner'
					, dc.PL_NAME
	  from WARS.BI.D_CLIENT dc 
	  left join SFDC.dbo.Account SFA on dc.CLIENT_ID = SFA.VegaID__c
	  where dc.client_id is not null and dc.COUNTRY!='UNKNOWN' and SFA.Account_Owner_Text__c is not null and dc.PL_NAME is not null
) info 
join(select a.client_id,a.client_name, a.PL_NAME 
		  , a.Jan_REV,a.Feb_REV, a.Mar_REV,a.Apr_REV,a.May_REV,a.Jun_REV,a.Jul_REV,a.Aug_REV,a.Sep_REV,a.Oct_REV,a.Nov_REV,a.Dec_REV,a.YTD_REV
		  , b.Jan_TPV,b.Feb_TPV, b.Mar_TPV,b.Apr_TPV,b.May_TPV,b.Jun_TPV,b.Jul_TPV,b.Aug_TPV,b.Sep_TPV,b.Oct_TPV,b.Nov_TPV,b.Dec_TPV,b.YTD_TPV
		  , b.Jan_wTPV,b.Feb_wTPV, b.Mar_wTPV,b.Apr_wTPV,b.May_wTPV,b.Jun_wTPV,b.Jul_wTPV,b.Aug_wTPV,b.Sep_wTPV,b.Oct_wTPV,b.Nov_wTPV,b.Dec_wTPV,b.YTD_wTPV
		  , c.Jan_Consult_wTPV,c.Feb_Consult_wTPV, c.Mar_Consult_wTPV,c.Apr_Consult_wTPV,c.May_Consult_wTPV,c.Jun_Consult_wTPV
		  , c.Jul_Consult_wTPV,c.Aug_Consult_wTPV,c.Sep_Consult_wTPV,c.Oct_Consult_wTPV,c.Nov_Consult_wTPV,c.Dec_Consult_wTPV,c.YTD_Consult_wTPV
		  , d.Jan_Consult_GC_wTPV,d.Feb_Consult_GC_wTPV, d.Mar_Consult_GC_wTPV,d.Apr_Consult_GC_wTPV,d.May_Consult_GC_wTPV,d.Jun_Consult_GC_wTPV
		  , d.Jul_Consult_GC_wTPV,d.Aug_Consult_GC_wTPV,d.Sep_Consult_GC_wTPV,d.Oct_Consult_GC_wTPV,d.Nov_Consult_GC_wTPV,d.Dec_Consult_GC_wTPV,d.YTD_Consult_GC_wTPV
		  , e.Jan_Consult_CRP,e.Feb_Consult_CRP, e.Mar_Consult_CRP,e.Apr_Consult_CRP,e.May_Consult_CRP,e.Jun_Consult_CRP
		  , e.Jul_Consult_CRP,e.Aug_Consult_CRP,e.Sep_Consult_CRP,e.Oct_Consult_CRP,e.Nov_Consult_CRP,e.Dec_Consult_CRP,e.YTD_Consult_CRP
		  , f.Jan_AVG_CM_RATE,f.Feb_AVG_CM_RATE,f.Mar_AVG_CM_RATE,f.Apr_AVG_CM_RATE,f.May_AVG_CM_RATE,f.Jun_AVG_CM_RATE
		  , f.Jul_AVG_CM_RATE,f.Aug_AVG_CM_RATE,f.Sep_AVG_CM_RATE,f.Oct_AVG_CM_RATE,f.Nov_AVG_CM_RATE,f.Dec_AVG_CM_RATE,f.YTD_AVG_CM_RATE
		  , g.Jan_PRE_CONSULT,g.Feb_PRE_CONSULT,g.Mar_PRE_CONSULT,g.Apr_PRE_CONSULT,g.May_PRE_CONSULT,g.Jun_PRE_CONSULT
		  , g.Jul_PRE_CONSULT,g.Aug_PRE_CONSULT,g.Sep_PRE_CONSULT,g.Oct_PRE_CONSULT,g.Nov_PRE_CONSULT,g.Dec_PRE_CONSULT,g.YTD_PRE_CONSULT
	  from (select client_id
				 , client_name
				 , PL_NAME
				 , sum(case when REV_Month =1 then amount else 0 end) as 'Jan_REV'
				 , sum(case when REV_Month =2 then amount else 0 end) as 'Feb_REV'
				 , sum(case when REV_Month =3 then amount else 0 end) as 'Mar_REV'
				 , sum(case when REV_Month =4 then amount else 0 end) as 'Apr_REV'
				 , sum(case when REV_Month =5 then amount else 0 end) as 'May_REV'
				 , sum(case when REV_Month =6 then amount else 0 end) as 'Jun_REV'
				 , sum(case when REV_Month =7 then amount else 0 end) as 'Jul_REV'
				 , sum(case when REV_Month =8 then amount else 0 end) as 'Aug_REV'
				 , sum(case when REV_Month =9 then amount else 0 end) as 'Sep_REV'
				 , sum(case when REV_Month =10 then amount else 0 end) as 'Oct_REV'
				 , sum(case when REV_Month =11 then amount else 0 end) as 'Nov_REV'
				 , sum(case when REV_Month =12 then amount else 0 end) as 'Dec_REV'
				 , sum(amount) as 'YTD_REV' 
			from #MR 
			group by client_id,client_name, PL_NAME
			) a
	    left join (select client_id
						, PL_NAME
						, sum(case when TPV_Month =1 then TPV else 0 end) as 'Jan_TPV'
						, sum(case when TPV_Month =2 then TPV else 0 end) as 'Feb_TPV'
						, sum(case when TPV_Month =3 then TPV else 0 end) as 'Mar_TPV'
						, sum(case when TPV_Month =4 then TPV else 0 end) as 'Apr_TPV'
						, sum(case when TPV_Month =5 then TPV else 0 end) as 'May_TPV'
						, sum(case when TPV_Month =6 then TPV else 0 end) as 'Jun_TPV'
						, sum(case when TPV_Month =7 then TPV else 0 end) as 'Jul_TPV'
						, sum(case when TPV_Month =8 then TPV else 0 end) as 'Aug_TPV'
						, sum(case when TPV_Month =9 then TPV else 0 end) as 'Sep_TPV'
						, sum(case when TPV_Month =10 then TPV else 0 end) as 'Oct_TPV'
						, sum(case when TPV_Month =11 then TPV else 0 end) as 'Nov_TPV'
						, sum(case when TPV_Month =12 then TPV else 0 end) as 'Dec_TPV'
						, sum(TPV) as 'YTD_TPV'
						, sum(case when TPV_Month =1 then wTPV else 0 end) as 'Jan_wTPV'
						, sum(case when TPV_Month =2 then wTPV else 0 end) as 'Feb_wTPV'
						, sum(case when TPV_Month =3 then wTPV else 0 end) as 'Mar_wTPV'
						, sum(case when TPV_Month =4 then wTPV else 0 end) as 'Apr_wTPV'
						, sum(case when TPV_Month =5 then wTPV else 0 end) as 'May_wTPV'
						, sum(case when TPV_Month =6 then wTPV else 0 end) as 'Jun_wTPV'
						, sum(case when TPV_Month =7 then wTPV else 0 end) as 'Jul_wTPV'
						, sum(case when TPV_Month =8 then wTPV else 0 end) as 'Aug_wTPV'
						, sum(case when TPV_Month =9 then wTPV else 0 end) as 'Sep_wTPV'
						, sum(case when TPV_Month =10 then wTPV else 0 end) as 'Oct_wTPV' 
						, sum(case when TPV_Month =11 then wTPV else 0 end) as 'Nov_wTPV'
						, sum(case when TPV_Month =12 then wTPV else 0 end) as 'Dec_wTPV'
						, sum(wTPV) as 'YTD_wTPV'
				  from #MU 
				  group by client_id, PL_NAME
				  ) b on a.client_id=b.client_id and a.PL_NAME=b.PL_NAME
	    left join (select client_id
					    , PL_NAME
					    , sum(case when TPV_Month =1 then wTPV else 0 end) as 'Jan_Consult_wTPV'
					    , sum(case when TPV_Month =2 then wTPV else 0 end) as 'Feb_Consult_wTPV'
					    , sum(case when TPV_Month =3 then wTPV else 0 end) as 'Mar_Consult_wTPV'
					    , sum(case when TPV_Month =4 then wTPV else 0 end) as 'Apr_Consult_wTPV'
					    , sum(case when TPV_Month =5 then wTPV else 0 end) as 'May_Consult_wTPV'
					    , sum(case when TPV_Month =6 then wTPV else 0 end) as 'Jun_Consult_wTPV'
					    , sum(case when TPV_Month =7 then wTPV else 0 end) as 'Jul_Consult_wTPV'
					    , sum(case when TPV_Month =8 then wTPV else 0 end) as 'Aug_Consult_wTPV'
					    , sum(case when TPV_Month =9 then wTPV else 0 end) as 'Sep_Consult_wTPV'
					    , sum(case when TPV_Month =10 then wTPV else 0 end) as 'Oct_Consult_wTPV'
					    , sum(case when TPV_Month =11 then wTPV else 0 end) as 'Nov_Consult_wTPV'
					    , sum(case when TPV_Month =12 then wTPV else 0 end) as 'Dec_Consult_wTPV'
					    , sum(wTPV) as 'YTD_Consult_wTPV'
				   from #MU 
				   where product_type='Phone Consultation'
				   group by client_id,PL_NAME
				   ) c on a.client_id=c.client_id and a.PL_NAME=c.PL_NAME
		left join (select client_id
						, PL_NAME
						, sum(case when TPV_Month =1 then wTPV else 0 end) as 'Jan_Consult_GC_wTPV'
						, sum(case when TPV_Month =2 then wTPV else 0 end) as 'Feb_Consult_GC_wTPV'
						, sum(case when TPV_Month =3 then wTPV else 0 end) as 'Mar_Consult_GC_wTPV'
						, sum(case when TPV_Month =4 then wTPV else 0 end) as 'Apr_Consult_GC_wTPV'
						, sum(case when TPV_Month =5 then wTPV else 0 end) as 'May_Consult_GC_wTPV'
						, sum(case when TPV_Month =6 then wTPV else 0 end) as 'Jun_Consult_GC_wTPV'
						, sum(case when TPV_Month =7 then wTPV else 0 end) as 'Jul_Consult_GC_wTPV'
						, sum(case when TPV_Month =8 then wTPV else 0 end) as 'Aug_Consult_GC_wTPV'
						, sum(case when TPV_Month =9 then wTPV else 0 end) as 'Sep_Consult_GC_wTPV'
						, sum(case when TPV_Month =10 then wTPV else 0 end) as 'Oct_Consult_GC_wTPV'
						, sum(case when TPV_Month =11 then wTPV else 0 end) as 'Nov_Consult_GC_wTPV'
						, sum(case when TPV_Month =12 then wTPV else 0 end) as 'Dec_Consult_GC_wTPV'
						, sum(wTPV) as 'YTD_Consult_GC_wTPV'
				   from #MU 
				   where product_type='Phone Consultation' and(CM_country like '%China%' or CM_country like '%Hong Kong%' or CM_country like '%Taiwan%')
				   group by client_id, PL_NAME
				   ) d on a.client_id=d.client_id and a.PL_NAME=d.PL_NAME
		 left join (select client_id
						 , PL_NAME
						 , sum(case when TPV_Month =1 then TPV else 0 end) as 'Jan_Consult_CRP'
						 , sum(case when TPV_Month =2 then TPV else 0 end) as 'Feb_Consult_CRP'
						 , sum(case when TPV_Month =3 then TPV else 0 end) as 'Mar_Consult_CRP'
						 , sum(case when TPV_Month =4 then TPV else 0 end) as 'Apr_Consult_CRP'
						 , sum(case when TPV_Month =5 then TPV else 0 end) as 'May_Consult_CRP'
						 , sum(case when TPV_Month =6 then TPV else 0 end) as 'Jun_Consult_CRP'
						 , sum(case when TPV_Month =7 then TPV else 0 end) as 'Jul_Consult_CRP'
						 , sum(case when TPV_Month =8 then TPV else 0 end) as 'Aug_Consult_CRP'
						 , sum(case when TPV_Month =9 then TPV else 0 end) as 'Sep_Consult_CRP'
						 , sum(case when TPV_Month =10 then TPV else 0 end) as 'Oct_Consult_CRP'
						 , sum(case when TPV_Month =11 then TPV else 0 end) as 'Nov_Consult_CRP'
						 , sum(case when TPV_Month =12 then TPV else 0 end) as 'Dec_Consult_CRP'
						 , sum(TPV) as 'YTD_Consult_CRP'
					from #MU
					where product_type='Phone Consultation' and RP_STATUS='CRP'
					group by client_id, PL_NAME
					) e on a.client_id=e.client_id and a.PL_NAME=e.PL_NAME
		 left join (select client_id
						 , PL_NAME
						 , Convert(Numeric(38, 2),ISNULL(sum(case when TPV_Month =1 then CM_RATE else 0 end)/NULLIF(sum(case when TPV_Month =1 then wTPV else 0 end),0),sum(case when TPV_Month =1 then CM_RATE else 0 end))) as 'Jan_AVG_CM_RATE'
						 , Convert(Numeric(38, 2),ISNULL(sum(case when TPV_Month =2 then CM_RATE else 0 end)/NULLIF(sum(case when TPV_Month =2 then wTPV else 0 end),0),sum(case when TPV_Month =2 then CM_RATE else 0 end))) as 'Feb_AVG_CM_RATE'
						 , Convert(Numeric(38, 2),ISNULL(sum(case when TPV_Month =3 then CM_RATE else 0 end)/NULLIF(sum(case when TPV_Month =3 then wTPV else 0 end),0),sum(case when TPV_Month =3 then CM_RATE else 0 end))) as 'Mar_AVG_CM_RATE'
						 , Convert(Numeric(38, 2),ISNULL(sum(case when TPV_Month =4 then CM_RATE else 0 end)/NULLIF(sum(case when TPV_Month =4 then wTPV else 0 end),0),sum(case when TPV_Month =4 then CM_RATE else 0 end))) as 'Apr_AVG_CM_RATE'
						 , Convert(Numeric(38, 2),ISNULL(sum(case when TPV_Month =5 then CM_RATE else 0 end)/NULLIF(sum(case when TPV_Month =5 then wTPV else 0 end),0),sum(case when TPV_Month =5 then CM_RATE else 0 end))) as 'May_AVG_CM_RATE'
						 , Convert(Numeric(38, 2),ISNULL(sum(case when TPV_Month =6 then CM_RATE else 0 end)/NULLIF(sum(case when TPV_Month =6 then wTPV else 0 end),0),sum(case when TPV_Month =6 then CM_RATE else 0 end))) as 'Jun_AVG_CM_RATE'
						 , Convert(Numeric(38, 2),ISNULL(sum(case when TPV_Month =7 then CM_RATE else 0 end)/NULLIF(sum(case when TPV_Month =7 then wTPV else 0 end),0),sum(case when TPV_Month =7 then CM_RATE else 0 end))) as 'Jul_AVG_CM_RATE'
						 , Convert(Numeric(38, 2),ISNULL(sum(case when TPV_Month =8 then CM_RATE else 0 end)/NULLIF(sum(case when TPV_Month =8 then wTPV else 0 end),0),sum(case when TPV_Month =8 then CM_RATE else 0 end))) as 'Aug_AVG_CM_RATE'
						 , Convert(Numeric(38, 2),ISNULL(sum(case when TPV_Month =9 then CM_RATE else 0 end)/NULLIF(sum(case when TPV_Month =9 then wTPV else 0 end),0),sum(case when TPV_Month =9 then CM_RATE else 0 end))) as 'Sep_AVG_CM_RATE'
						 , Convert(Numeric(38, 2),ISNULL(sum(case when TPV_Month =10 then CM_RATE else 0 end)/NULLIF(sum(case when TPV_Month =10 then wTPV else 0 end),0),sum(case when TPV_Month =10 then CM_RATE else 0 end))) as 'Oct_AVG_CM_RATE'
						 , Convert(Numeric(38, 2),ISNULL(sum(case when TPV_Month =11 then CM_RATE else 0 end)/NULLIF(sum(case when TPV_Month =11 then wTPV else 0 end),0),sum(case when TPV_Month =11 then CM_RATE else 0 end))) as 'Nov_AVG_CM_RATE'
						 , Convert(Numeric(38, 2),ISNULL(sum(case when TPV_Month =12 then CM_RATE else 0 end)/NULLIF(sum(case when TPV_Month =12 then wTPV else 0 end),0),sum(case when TPV_Month =12 then CM_RATE else 0 end))) as 'Dec_AVG_CM_RATE'
						 , Convert(Numeric(38, 2),ISNULL(sum(CM_RATE)/NULLIF(sum(wTPV),0),sum(CM_RATE))) as 'YTD_AVG_CM_RATE'
					from #MU 
					where product_type='Phone Consultation'
					group by client_id,PL_NAME
					) f on a.client_id=f.client_id and a.PL_NAME=f.PL_NAME
		 left join (select client_id
						 , PL_NAME
						 , sum(case when TPV_Month =1 and (((CM_COUNTRY like '%China%' or CM_COUNTRY like '%Hong Kong%' or CM_COUNTRY like '%Taiwan%')and CM_RATE>300)or (CM_COUNTRY not like '%China%' and CM_COUNTRY not like '%Hong Kong%' and CM_COUNTRY not like '%Taiwan%'and CM_RATE>500)) then 1 else 0 end) as 'Jan_PRE_CONSULT'
						 , sum(case when TPV_Month =2 and (((CM_COUNTRY like '%China%' or CM_COUNTRY like '%Hong Kong%' or CM_COUNTRY like '%Taiwan%')and CM_RATE>300)or (CM_COUNTRY not like '%China%' and CM_COUNTRY not like '%Hong Kong%' and CM_COUNTRY not like '%Taiwan%'and CM_RATE>500)) then 1 else 0 end) as 'Feb_PRE_CONSULT'
						 , sum(case when TPV_Month =3 and (((CM_COUNTRY like '%China%' or CM_COUNTRY like '%Hong Kong%' or CM_COUNTRY like '%Taiwan%')and CM_RATE>300)or (CM_COUNTRY not like '%China%' and CM_COUNTRY not like '%Hong Kong%' and CM_COUNTRY not like '%Taiwan%'and CM_RATE>500)) then 1 else 0 end) as 'Mar_PRE_CONSULT'
						 , sum(case when TPV_Month =4 and (((CM_COUNTRY like '%China%' or CM_COUNTRY like '%Hong Kong%' or CM_COUNTRY like '%Taiwan%')and CM_RATE>300)or (CM_COUNTRY not like '%China%' and CM_COUNTRY not like '%Hong Kong%' and CM_COUNTRY not like '%Taiwan%'and CM_RATE>500)) then 1 else 0 end) as 'Apr_PRE_CONSULT'
						 , sum(case when TPV_Month =5 and (((CM_COUNTRY like '%China%' or CM_COUNTRY like '%Hong Kong%' or CM_COUNTRY like '%Taiwan%')and CM_RATE>300)or (CM_COUNTRY not like '%China%' and CM_COUNTRY not like '%Hong Kong%' and CM_COUNTRY not like '%Taiwan%'and CM_RATE>500)) then 1 else 0 end) as 'May_PRE_CONSULT'
						 , sum(case when TPV_Month =6 and (((CM_COUNTRY like '%China%' or CM_COUNTRY like '%Hong Kong%' or CM_COUNTRY like '%Taiwan%')and CM_RATE>300)or (CM_COUNTRY not like '%China%' and CM_COUNTRY not like '%Hong Kong%' and CM_COUNTRY not like '%Taiwan%'and CM_RATE>500)) then 1 else 0 end) as 'Jun_PRE_CONSULT'
						 , sum(case when TPV_Month =7 and (((CM_COUNTRY like '%China%' or CM_COUNTRY like '%Hong Kong%' or CM_COUNTRY like '%Taiwan%')and CM_RATE>300)or (CM_COUNTRY not like '%China%' and CM_COUNTRY not like '%Hong Kong%' and CM_COUNTRY not like '%Taiwan%'and CM_RATE>500)) then 1 else 0 end) as 'Jul_PRE_CONSULT'
						 , sum(case when TPV_Month =8 and (((CM_COUNTRY like '%China%' or CM_COUNTRY like '%Hong Kong%' or CM_COUNTRY like '%Taiwan%')and CM_RATE>300)or (CM_COUNTRY not like '%China%' and CM_COUNTRY not like '%Hong Kong%' and CM_COUNTRY not like '%Taiwan%'and CM_RATE>500)) then 1 else 0 end) as 'Aug_PRE_CONSULT'
						 , sum(case when TPV_Month =9 and (((CM_COUNTRY like '%China%' or CM_COUNTRY like '%Hong Kong%' or CM_COUNTRY like '%Taiwan%')and CM_RATE>300)or (CM_COUNTRY not like '%China%' and CM_COUNTRY not like '%Hong Kong%' and CM_COUNTRY not like '%Taiwan%'and CM_RATE>500)) then 1 else 0 end) as 'Sep_PRE_CONSULT'
						 , sum(case when TPV_Month =10 and (((CM_COUNTRY like '%China%' or CM_COUNTRY like '%Hong Kong%' or CM_COUNTRY like '%Taiwan%')and CM_RATE>300)or (CM_COUNTRY not like '%China%' and CM_COUNTRY not like '%Hong Kong%' and CM_COUNTRY not like '%Taiwan%'and CM_RATE>500)) then 1 else 0 end) as 'Oct_PRE_CONSULT'
						 , sum(case when TPV_Month =11 and (((CM_COUNTRY like '%China%' or CM_COUNTRY like '%Hong Kong%' or CM_COUNTRY like '%Taiwan%')and CM_RATE>300)or (CM_COUNTRY not like '%China%' and CM_COUNTRY not like '%Hong Kong%' and CM_COUNTRY not like '%Taiwan%'and CM_RATE>500)) then 1 else 0 end) as 'Nov_PRE_CONSULT'
						 , sum(case when TPV_Month =12 and (((CM_COUNTRY like '%China%' or CM_COUNTRY like '%Hong Kong%' or CM_COUNTRY like '%Taiwan%')and CM_RATE>300)or (CM_COUNTRY not like '%China%' and CM_COUNTRY not like '%Hong Kong%' and CM_COUNTRY not like '%Taiwan%'and CM_RATE>500)) then 1 else 0 end) as 'Dec_PRE_CONSULT'
						 , sum(case when ((CM_COUNTRY like '%China%' or CM_COUNTRY like '%Hong Kong%' or CM_COUNTRY like '%Taiwan%')and CM_RATE>300)or (CM_COUNTRY not like '%China%' and CM_COUNTRY not like '%Hong Kong%' and CM_COUNTRY not like '%Taiwan%'and CM_RATE>500) then 1 else 0 end) as 'YTD_PRE_CONSULT'
					from #MU 
					group by client_id, PL_NAME
					) g on a.client_id=g.client_id and a.PL_NAME=g.PL_NAME
		 group by a.client_id,a.client_name, a.PL_NAME
				 ,a.Jan_REV,a.Feb_REV, a.Mar_REV,a.Apr_REV,a.May_REV,a.Jun_REV,a.Jul_REV,a.Aug_REV,a.Sep_REV,a.Oct_REV,a.Nov_REV,a.Dec_REV,a.YTD_REV
				 ,b.Jan_TPV,b.Feb_TPV, b.Mar_TPV,b.Apr_TPV,b.May_TPV,b.Jun_TPV,b.Jul_TPV,b.Aug_TPV,b.Sep_TPV,b.Oct_TPV,b.Nov_TPV,b.Dec_TPV,b.YTD_TPV
				 ,b.Jan_wTPV,b.Feb_wTPV, b.Mar_wTPV,b.Apr_wTPV,b.May_wTPV,b.Jun_wTPV,b.Jul_wTPV,b.Aug_wTPV,b.Sep_wTPV,b.Oct_wTPV,b.Nov_wTPV,b.Dec_wTPV,b.YTD_wTPV
				 ,c.Jan_Consult_wTPV,c.Feb_Consult_wTPV, c.Mar_Consult_wTPV,c.Apr_Consult_wTPV,c.May_Consult_wTPV,c.Jun_Consult_wTPV
				 ,c.Jul_Consult_wTPV,c.Aug_Consult_wTPV,c.Sep_Consult_wTPV,c.Oct_Consult_wTPV,c.Nov_Consult_wTPV,c.Dec_Consult_wTPV,c.YTD_Consult_wTPV
				 ,d.Jan_Consult_GC_wTPV,d.Feb_Consult_GC_wTPV, d.Mar_Consult_GC_wTPV,d.Apr_Consult_GC_wTPV,d.May_Consult_GC_wTPV,d.Jun_Consult_GC_wTPV
				 ,d.Jul_Consult_GC_wTPV,d.Aug_Consult_GC_wTPV,d.Sep_Consult_GC_wTPV,d.Oct_Consult_GC_wTPV,d.Nov_Consult_GC_wTPV,d.Dec_Consult_GC_wTPV,d.YTD_Consult_GC_wTPV
				 ,e.Jan_Consult_CRP,e.Feb_Consult_CRP, e.Mar_Consult_CRP,e.Apr_Consult_CRP,e.May_Consult_CRP,e.Jun_Consult_CRP
				 ,e.Jul_Consult_CRP,e.Aug_Consult_CRP,e.Sep_Consult_CRP,e.Oct_Consult_CRP,e.Nov_Consult_CRP,e.Dec_Consult_CRP,e.YTD_Consult_CRP
				 ,f.Jan_AVG_CM_RATE,f.Feb_AVG_CM_RATE,f.Mar_AVG_CM_RATE,f.Apr_AVG_CM_RATE,f.May_AVG_CM_RATE,f.Jun_AVG_CM_RATE
				 ,f.Jul_AVG_CM_RATE,f.Aug_AVG_CM_RATE,f.Sep_AVG_CM_RATE,f.Oct_AVG_CM_RATE,f.Nov_AVG_CM_RATE,f.Dec_AVG_CM_RATE,f.YTD_AVG_CM_RATE
				 ,g.Jan_PRE_CONSULT,g.Feb_PRE_CONSULT,g.Mar_PRE_CONSULT,g.Apr_PRE_CONSULT,g.May_PRE_CONSULT,g.Jun_PRE_CONSULT
				 ,g.Jul_PRE_CONSULT,g.Aug_PRE_CONSULT,g.Sep_PRE_CONSULT,g.Oct_PRE_CONSULT,g.Nov_PRE_CONSULT,g.Dec_PRE_CONSULT,g.YTD_PRE_CONSULT
) datas on info.Client_ID=datas.client_id and info.PL_NAME=datas.PL_NAME
order by info.client_id

select * from #DATA order by client_id

select *  from #DAI join #DATA on #DAI.Client_ID=#DATA.client_id 
order by #DAI.Client_ID

select top 10* from GLGLIVE.dbo.council_member_job_function_relation
