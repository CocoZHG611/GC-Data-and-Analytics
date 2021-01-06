--explore data
Select * FROM glglive.[taxonomy].[INDUSTRY]
Select top 100* FROM glglive.[dbo].[COMPANY_SUBSIDIARY_RELATION_CALC]
Select * FROM CAPIQ.dbo.ciqNativeCompanyNames
--where companyId=9935271
order by companyId

/*select * from CAPIQ.dbo.ciqSearchCompanyNames
join CAPIQ.dbo.ciqExchange on CAPIQ.dbo.ciqSearchCompanyNames.exchangeid=CAPIQ.dbo.ciqExchange.exchangeid
where CAPIQ.dbo.ciqSearchCompanyNames.companyName like '%baidu%'

select * from CAPIQ.dbo.ciqExchange
order by exchangeName

select * from CAPIQ.dbo.ciqSearchCompanyNames
where CAPIQ.dbo.ciqSearchCompanyNames.searchCompanyNameTypeId=8*/


--taxonomy
select b.INDUSTRY
	 , b.INDUSTRY_ID
	 , b.SUB_INDUSTRY
	 , b.SUB_INDUSTRY_ID
	 , b.SUB_SUB_INDUSTRY 
	 , b.SUB_SUB_INDUSTRY_ID
from (select a.*
	  , CHILD.INDUSTRY AS SUB_SUB_INDUSTRY
	  , CHILD.INDUSTRY_ID AS SUB_SUB_INDUSTRY_ID
	  from (select PARENT.*
				 , CHILD.INDUSTRY_ID AS SUB_INDUSTRY_ID
				 , CHILD.INDUSTRY AS SUB_INDUSTRY 
			from glglive.[taxonomy].[INDUSTRY] AS PARENT 
			join glglive.[taxonomy].[INDUSTRY] AS CHILD 
			on PARENT.INDUSTRY_ID=CHILD.PARENT_INDUSTRY_ID
			where PARENT.PARENT_INDUSTRY_ID is null
			) a
	   left join glglive.[taxonomy].[INDUSTRY] AS CHILD 
	   on a.SUB_INDUSTRY_ID=CHILD.PARENT_INDUSTRY_ID
	   ) b
order by b.INDUSTRY

/*select a.*, glglive.[taxonomy].[INDUSTRY].INDUSTRY from
(select COMPANY_ID, INDUSTRY_ID from glglive.taxonomy.COMPANY_INDUSTRY_RELATION) a
join glglive.[taxonomy].[INDUSTRY] on a.INDUSTRY_ID=glglive.[taxonomy].[INDUSTRY].INDUSTRY_ID
where a.COMPANY_ID=122606

select * from glglive.taxonomy.COMPANY_INDUSTRY_RELATION
where COMPANY_ID=11508*/

--select all CM with TC signed at least once and country= China
drop table if exists #d_council_member_work_history_TC_signed 
select * into #d_council_member_work_history_TC_signed 
from WARS.bi.D_COUNCIL_MEMBER_WORK_HISTORY
where council_member_id in  (SELECT distinct COUNCIL_MEMBER_ID
							 FROM WARS.BI.D_COUNCIL_MEMBER
							 WHERE TERMS_CONDITIONS_START_DATE IS NOT NULL and (country like '%China%' or country like '%Taiwan%' or country like '%Hong Kong%')
							 GROUP BY COUNCIL_MEMBER_ID)

--Company list in CM work history of CM country in China/Hong Kong/Taiwan and CMs that have at least signs T&C once
drop table if exists #list
select distinct a.COMPANY_ID 
into #list 
from (select RCM.COUNCIL_MEMBER_ID
		   , d_council_member_work_history.COMPANY_ID
		   , d_council_member_work_history.START_YEAR
		   , d_council_member_work_history.START_MONTH
		   /*, rank() over(partition by RCM.COUNCIL_MEMBER_ID 
						 order by d_council_member_work_history.START_YEAR desc
								, d_council_member_work_history.START_MONTH desc
						) ranks*/
	   from WARS.bi.D_COUNCIL_MEMBER RCM 
	   join #d_council_member_work_history_TC_signed AS d_council_member_work_history
	   on RCM.COUNCIL_MEMBER_ID=d_council_member_work_history.COUNCIL_MEMBER_ID
	   where d_council_member_work_history.START_YEAR>=2015
	   and d_council_member_work_history.COMPANY_ID is not null
	   group by RCM.COUNCIL_MEMBER_ID
			  , d_council_member_work_history.COMPANY_ID
			  , d_council_member_work_history.START_YEAR
			  , d_council_member_work_history.START_MONTH
	  ) a
--where ranks<2


select * from #list
order by 1


--use glglive.dbo.company as key to join two tables
select top 10* from glglive.dbo.COMPANY
where CIQID is not null
select top 10* from CAPIQ.dbo.ciqCompany
select top 10* from CAPIQ.dbo.ciqNativeCompanyNames
order by companyId


drop table if exists #Match
select #list.COMPANY_ID
	 , c.nativeName
	 , b.companyName
	 , a.CIQID
into #Match
from #list
join glglive.dbo.company a on #list.COMPANY_ID=a.COMPANY_ID
left join CAPIQ.dbo.ciqCompany b on a.CIQID=b.companyId
left join CAPIQ.dbo.ciqNativeCompanyNames c on c.companyId=a.CIQID
order by #list.COMPANY_ID


select * from #Match
--where CIQID=428613	
--where nativeName is not null
order by COMPANY_ID


select distinct COMPANY_ID
	 , nativeName
	 , companyName
	 , CIQID 
from #Match
where COMPANY_ID is not null and CIQID is not null
order by 1


select distinct COMPANY_ID
	 , nativeName
	 , companyName
	 , CIQID 
from #Match
where COMPANY_ID is null or CIQID is null
order by 1


--Perc of Projects done by China CM’s in 2018/2019/2020 whose work history after 2015 that are associated with a CapIQ ID
drop table if exists #list2
select distinct COUNCIL_MEMBER_ID, COMPANY_ID, START_YEAR, START_MONTH, END_YEAR, END_MONTH
into #list2 
from (select RCM.COUNCIL_MEMBER_ID
		   , d_council_member_work_history.COMPANY_ID
		   , d_council_member_work_history.START_YEAR
		   , d_council_member_work_history.START_MONTH
		   , d_council_member_work_history.END_YEAR
		   , d_council_member_work_history.END_MONTH
		   /*, rank() over(partition by RCM.COUNCIL_MEMBER_ID 
						 order by d_council_member_work_history.START_YEAR desc
								, d_council_member_work_history.START_MONTH desc
						) ranks*/
	   from WARS.bi.D_COUNCIL_MEMBER RCM 
	   join #d_council_member_work_history_TC_signed AS d_council_member_work_history
	   on RCM.COUNCIL_MEMBER_ID=d_council_member_work_history.COUNCIL_MEMBER_ID
	   where d_council_member_work_history.START_YEAR>=2015
	   and d_council_member_work_history.COMPANY_ID is not null
	   group by RCM.COUNCIL_MEMBER_ID
			  , d_council_member_work_history.COMPANY_ID
			  , d_council_member_work_history.START_YEAR
			  , d_council_member_work_history.START_MONTH
			  , d_council_member_work_history.END_YEAR
			  , d_council_member_work_history.END_MONTH
	  ) a
--where ranks=1
order by COUNCIL_MEMBER_ID


select * from #list2 order by 1,2


drop table if exists #perc
SELECT DISTINCT tpv.PROJECT_ID
	 , RCM.COUNCIL_MEMBER_ID
	 , YEAR(tpv.TPV_DATE) as years 
	 , MONTH(tpv.TPV_DATE) as months
	 , d_council_member_work_history.COMPANY_ID
	 , d_council_member_work_history.START_YEAR
	 , d_council_member_work_history.START_MONTH
	 , d_council_member_work_history.END_YEAR
	 , d_council_member_work_history.END_MONTH
	 , #Match.nativeName
	 , #Match.companyName
	 , #Match.CIQID
into #perc
FROM WARS.bi.F_TPV tpv
join WARS.bi.D_COUNCIL_MEMBER RCM on tpv.D_COUNCIL_MEMBER_KEY=RCM.D_COUNCIL_MEMBER_KEY
left join #d_council_member_work_history_TC_signed AS d_council_member_work_history on RCM.COUNCIL_MEMBER_ID=d_council_member_work_history.COUNCIL_MEMBER_ID
left join #Match on #Match.COMPANY_ID=d_council_member_work_history.COMPANY_ID 
WHERE (RCM.country like '%Hong Kong%' or RCM.country like '%China%' or RCM.country like '%Taiwan%')
AND (YEAR(TPV_DATE)=2018 or YEAR(TPV_DATE)=2019 or YEAR(TPV_DATE)=2020)


--select * from #perc
--order by 1,2


drop table if exists #pc
select * into #pc
from #perc 
where ((years=START_YEAR and years<END_YEAR and months>=START_MONTH) 
or (years>START_YEAR and years=END_YEAR and months<=END_MONTH)
or (years>START_YEAR and years<END_YEAR)
or (years=START_YEAR and years=END_YEAR and months>=START_MONTH and months<=END_MONTH)
or (years>=START_YEAR and months>=START_MONTH and END_MONTH is null)
or (years>START_YEAR and END_MONTH is null))
order by PROJECT_ID, COUNCIL_MEMBER_ID


select * from #pc
where COMPANY_ID is not null and CIQID is not null 
order by project_id, COUNCIL_MEMBER_ID


select * from #pc 
where COMPANY_ID is null or CIQID is null
order by PROJECT_ID, COUNCIL_MEMBER_ID


--2020 top company & top CM used by segmenttpv, cm latest employment, user_PL=GCby pod
select COM.primary_NAME as Target_Company
,scn1.companyId as CapIQ_ID
,scn1.companyName as CapIQ_Company_Name
,scn1.Exchange
--,E.POD as CS_Team--breakdown of projects by CS pod
,COUNT(p.F_PROJECT_KEY) as Total_No_of_Projects
,COUNT(case when e.pod like 'FS - Beijing FS' then 1 else null end) as FS_Beijing_FS
,COUNT(case when e.pod like 'FS - Shanghai FS' then 1 else null end) as FS_Shanghai_FS
,COUNT(case when e.pod like 'FS - South China FS' then 1 else null end) as FS_South_China_FS
,COUNT(case when e.pod like 'FS - Greater China Public Equity' then 1 else null end) as FS_Greater_China_Public_Equity
,COUNT(case when e.pod like 'FS - Greater China Private Equity' then 1 else null end) as FS_Greater_China_Private_Equity
,COUNT(case when e.pod like 'FS - Greater China Credit' then 1 else null end) as FS_Greater_China_Credit
,COUNT(case when e.pod like 'PSF' then 1 else null end) as PSF
,COUNT(case when e.pod like 'Corp - Greater China Corporate' then 1 else null end) as Corp_Greater_China_Corporate
,COUNT(case when e.pod like 'Corp - Hong Kong Corporate' then 1 else null end) as Corp_Hong_Kong_Corporate
,COUNT(case when e.pod like 'GC Service Lines' then 1 else null end) as GC_Service_Lines
,COUNT(case when e.pod not like 'FS - Beijing FS' 
			 and e.pod not like 'FS - Shanghai FS' 
			 and e.pod not like 'FS - South China FS' 
			 and e.pod not like 'FS - Greater China Public Equity'
			 and e.pod not like 'FS - Greater China Private Equity' 
			 and e.pod not like 'FS - Greater China Credit' 
			 and e.pod not like 'PSF'
			 and e.pod not like 'Corp - Greater China Corporate' 
			 and e.pod not like 'Corp - Hong Kong Corporate' 
			 and e.pod not like 'GC Service Lines' then 1 else null end) as UNKNOWN
FROM wars.bi.f_project p
JOIN (select distinct d_council_member_work_history.COMPANY_ID, tpv.PROJECT_ID
	  from WARS.bi.D_COUNCIL_MEMBER RCM 
	  join #d_council_member_work_history_TC_signed AS d_council_member_work_history on RCM.COUNCIL_MEMBER_ID=d_council_member_work_history.COUNCIL_MEMBER_ID
	  join WARS.bi.F_TPV tpv on tpv.D_COUNCIL_MEMBER_KEY=RCM.D_COUNCIL_MEMBER_KEY
	  where d_council_member_work_history.START_YEAR>=2015
	  and d_council_member_work_history.COMPANY_ID is not null
	  and YEAR(tpv.TPV_DATE)=2020 
	  ) TC on tc.PROJECT_ID=p.project_id 
JOIN GLGLIVE.DBO.COMPANY COM ON COM.COMPANY_ID = TC.COMPANY_ID
join (select distinct cc.companyId, cc.companyName
		   , case when sum(ISNULL(scn.exchangeId,0))>1 then 1 else 0 end as Exchange
	  from CAPIQ.dbo.ciqSearchCompanyNames scn 
	  join CAPIQ.dbo.ciqCompany cc on scn.companyId=cc.companyId
	  group by cc.companyId, cc.companyName
	  ) scn1 on COM.CIQID=scn1.companyId
JOIN WARS.BI.D_USER U ON p.primary_consultation_user_key=u.d_user_key
JOIN WARS.BI.D_EMP E ON p.primary_rm_d_emp_key=e.d_emp_key
JOIN WARS.BI.D_PRODUCT DP ON P.D_PRODUCT_KEY=DP.D_PRODUCT_KEY
where u.PL_NAME='Greater China'
--u.country in ('China (Mainland)','Hong Kong')--who have users in GC/HKSAR
AND p.create_DATE_KEY BETWEEN '20200101' AND '20201231'
--AND DP.PRODUCT_TYPE LIKE '%Phone Consultation%'
GROUP BY 
Com.primary_NAME
,scn1.companyId
,scn1.companyName
,scn1.Exchange
--,E.POD
ORDER BY Total_NO_OF_PROJECTS DESC


--check ID in work history table
select * from 
#d_council_member_work_history_TC_signed AS d_council_member_work_history
where --d_council_member_work_history.COMPANY_ID =25194 or d_council_member_work_history.COMPANY_ID =47902
--d_council_member_work_history.COMPANY_ID =291196 or d_council_member_work_history.COMPANY_ID =254602 or
--d_council_member_work_history.COMPANY_ID =320562
--d_council_member_work_history.COMPANY_ID =3168916
--d_council_member_work_history.COMPANY_ID =426321
--d_council_member_work_history.COMPANY_ID =1120132
d_council_member_work_history.COMPANY_NAME like '%tencent%' or d_council_member_work_history.COMPANY_NAME like '%腾讯%'
or d_council_member_work_history.COMPANY_NAME like '%Tengxun%'
order by d_council_member_work_history.COMPANY_ID,d_council_member_work_history.COMPANY_NAME


--show COMPANY_SUBSIDIARY_RELATION
drop table if exists #temp 
select *,
	case when ULTIMATE_PARENT_IND=1 THEN 1
	ELSE 2 END LEVEL,
	case when ULTIMATE_PARENT_IND=1 THEN 2
	ELSE 3 END MEMBER_LEVEL
into #temp
from glglive.[dbo].[COMPANY_SUBSIDIARY_RELATION_CALC]
where MEMBER_COMPANY_ID!=COMPANY_ID
--select * from #temp order by ULTIMATE_PARENT_IND desc, COMPANY_ID, MEMBER_COMPANY_ID
DECLARE @Counter INT , @level INT, @ind INT,@count INT
SELECT @Counter = min(COMPANY_ID) , @level = max(LEVEL), @ind=1,@count=count(COMPANY_ID)
FROM #temp
where LEVEL=2
WHILE(@level!=25)
BEGIN  
   select @ind=max(LEVEL) from #temp
   UPDATE #temp
   set LEVEL=LEVEL+1, MEMBER_LEVEL=MEMBER_LEVEL+1
   where COMPANY_ID IN (SELECT MEMBER_COMPANY_ID FROM #temp where LEVEL=@ind) and LEVEL=@ind
   select @level=max(LEVEL) from #temp
   select @count=count(COMPANY_ID) from #temp where LEVEL=@level
END


select * from #temp 
where LEVEL=25
--where COMPANY_ID=2114637
--where COMPANY_ID=2066060 or COMPANY_ID=10756646 or COMPANY_ID=20728580
order by LEVEL, COMPANY_ID, MEMBER_COMPANY_ID


select c.COMPANY_ID
	 , max(c.LEVEL) as LEVEL 
from (SELECT a.COMPANY_ID
		   , a.LEVEL
	  FROM (select distinct COMPANY_ID, LEVEL from #temp) a
	  UNION 
	  SELECT b.MEMBER_COMPANY_ID as COMPANY_ID
		   , b.LEVEL
	  FROM (select distinct #temp.MEMBER_COMPANY_ID
				  ,case when a.MEMBER_COMPANY_ID is not null then #temp.LEVEL
				   else #temp.LEVEL+1 end as LEVEL
		    from #temp 
			JOIN #temp a 
			on #temp.COMPANY_ID=a.MEMBER_COMPANY_ID
			where #temp.MEMBER_COMPANY_ID not in (select COMPANY_ID from #temp)
			) b
	  ) c
group by c.COMPANY_ID
order by LEVEL, c.COMPANY_ID


--find company ID in work history v.s. hierarchy
select distinct COMPANY_ID
			  , COMPANY_NAME 
from #d_council_member_work_history_TC_signed AS d_council_member_work_history
where (d_council_member_work_history.COMPANY_NAME like '%tencent%' 
	or d_council_member_work_history.COMPANY_NAME like '%腾讯%' 
	or d_council_member_work_history.COMPANY_NAME like '%Tengxun%')
and COMPANY_ID not in (select distinct MEMBER_COMPANY_ID 
					   from #temp 
					   where COMPANY_ID=2114637)
and COMPANY_ID!=2114637
order by d_council_member_work_history.COMPANY_ID


select distinct MEMBER_COMPANY_ID 
from #temp 
where COMPANY_ID=2114637
and MEMBER_COMPANY_ID not in(select distinct COMPANY_ID 
							 from #d_council_member_work_history_TC_signed AS d_council_member_work_history
							 where (d_council_member_work_history.COMPANY_NAME like '%tencent%' 
								 or d_council_member_work_history.COMPANY_NAME like '%腾讯%'
								 or d_council_member_work_history.COMPANY_NAME like '%Tengxun%') 
							 and COMPANY_ID is not null)
order by MEMBER_COMPANY_ID


select distinct COMPANY_ID, COMPANY_NAME 
from #d_council_member_work_history_TC_signed AS d_council_member_work_history
where (d_council_member_work_history.COMPANY_NAME like '%tencent%' 
	or d_council_member_work_history.COMPANY_NAME like '%腾讯%'
	or d_council_member_work_history.COMPANY_NAME like '%Tengxun%')
and COMPANY_ID in (select distinct MEMBER_COMPANY_ID from #temp where LEVEL=25)
order by d_council_member_work_history.COMPANY_ID


select * from #temp 
where LEVEL=25 and(MEMBER_COMPANY_ID=288374 or MEMBER_COMPANY_ID=3046393 or MEMBER_COMPANY_ID=3307937 or MEMBER_COMPANY_ID=6485700)


/*select distinct COMPANY_ID
			  , COMPANY_NAME 
from WARS.bi.D_COUNCIL_MEMBER_WORK_HISTORY AS d_council_member_work_history
where (d_council_member_work_history.COMPANY_NAME like '%baidu%' 
	or d_council_member_work_history.COMPANY_NAME like '%百度%')
and COMPANY_ID not in (select distinct MEMBER_COMPANY_ID 
					   from #temp 
					   where COMPANY_ID=2066060)
and COMPANY_ID != 2066060
order by d_council_member_work_history.COMPANY_ID*/