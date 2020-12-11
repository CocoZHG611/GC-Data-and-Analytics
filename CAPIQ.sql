--explore data
Select * FROM glglive.[taxonomy].[INDUSTRY]
Select top 100* FROM glglive.[dbo].[COMPANY_SUBSIDIARY_RELATION_CALC]
Select * FROM CAPIQ.dbo.ciqNativeCompanyNames
--where companyId=9935271
order by companyId

--select all CM with TC signed at least once and country= China
drop table if exists #d_council_member_work_history_TC_signed 
select * into #d_council_member_work_history_TC_signed 
from WARS.bi.D_COUNCIL_MEMBER_WORK_HISTORY
where council_member_id in  (SELECT distinct COUNCIL_MEMBER_ID
							 FROM WARS.BI.D_COUNCIL_MEMBER
							 WHERE TERMS_CONDITIONS_START_DATE IS NOT NULL and (country like '%China%' or country like '%Taiwan%' or country like '%Hong Kong%')
							 GROUP BY COUNCIL_MEMBER_ID)


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



--Method A:use Company name to join ciqNativeCompanyNames and d_council_member_work_history
/*drop table if exists #MA
--select d.*, c.INDUSTRY from(
select distinct d_council_member_work_history.COMPANY_ID
			  , b.ciqid
			  , d_council_member_work_history.COMPANY_NAME
			  , b.nativeName 
into #MA
from #d_council_member_work_history_TC_signed AS d_council_member_work_history 
join (select distinct d_council_member_work_history.COMPANY_ID
					, a.companyId as ciqid
				    , d_council_member_work_history.COMPANY_NAME
				    , a.companyName as cn
					, a.nativeName 
	  from #d_council_member_work_history_TC_signed AS d_council_member_work_history 
	  join (Select distinct CAPIQ.dbo.ciqNativeCompanyNames.companyId
						  , CAPIQ.dbo.ciqNativeCompanyNames.nativeName
						  , CAPIQ.dbo.ciqCompany.companyName
			 FROM CAPIQ.dbo.ciqNativeCompanyNames 
			 join CAPIQ.dbo.ciqCompany 
			 on CAPIQ.dbo.ciqNativeCompanyNames.companyId=CAPIQ.dbo.ciqCompany.companyId
			) a 
	  on d_council_member_work_history.COMPANY_NAME=a.companyName
	  where d_council_member_work_history.COMPANY_ID is not NULL
	  ) b 
on d_council_member_work_history.COMPANY_ID=b.COMPANY_ID
/*) d
left join (select a.*, glglive.[taxonomy].[INDUSTRY].INDUSTRY from
(select COMPANY_ID, INDUSTRY_ID from glglive.taxonomy.COMPANY_INDUSTRY_RELATION) a
join glglive.[taxonomy].[INDUSTRY] on a.INDUSTRY_ID=glglive.[taxonomy].[INDUSTRY].INDUSTRY_ID) c 
on d.COMPANY_ID=c.COMPANY_ID*/

select * from #MA
order by COMPANY_ID*/

/*select a.*, glglive.[taxonomy].[INDUSTRY].INDUSTRY from
(select COMPANY_ID, INDUSTRY_ID from glglive.taxonomy.COMPANY_INDUSTRY_RELATION) a
join glglive.[taxonomy].[INDUSTRY] on a.INDUSTRY_ID=glglive.[taxonomy].[INDUSTRY].INDUSTRY_ID
where a.COMPANY_ID=122606

select * from glglive.taxonomy.COMPANY_INDUSTRY_RELATION
where COMPANY_ID=11508*/

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
--where ranks<=2


--select distinct COMPANY_ID from #MA
--where COMPANY_ID in (select * from #list)

select * from #list

--Method B:use glglive.dbo.company as key to join two tables
select top 100* from glglive.dbo.COMPANY
select top 100* from glglive.dbo.council_member_job_function_relation

drop table if exists #Match
select #list.COMPANY_ID, a.nativeName,c.companyName,b.CIQID
into #Match
from #list
join glglive.dbo.company b on #list.COMPANY_ID=b.COMPANY_ID
left join CAPIQ.dbo.ciqCompany c on b.CIQID=c.companyId
left join CAPIQ.dbo.ciqNativeCompanyNames a on a.companyId=b.CIQID
order by #list.COMPANY_ID

select * from #Match
--where COMPANY_ID=1117373
order by COMPANY_ID

select distinct COMPANY_ID from #Match
where COMPANY_ID is not null and nativeName is not null and companyName is not null and CIQID is not null


--Perc of Projects done by China CM’s in 2018/2019/2020 whose work history after 2015 that are associated with a CapIQ ID
drop table if exists #list2
select distinct COUNCIL_MEMBER_ID,COMPANY_ID 
into #list2 
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
--where ranks=1
order by COUNCIL_MEMBER_ID


drop table if exists #perc
select b.COUNCIL_MEMBER_ID
	 , sum(b.projects) projects 
into #perc 
from (select a.*
		   , RCM.COUNCIL_MEMBER_ID 
	  from(select D_COUNCIL_MEMBER_KEY
				 ,COUNT(PROJECT_ID) AS projects
		   from WARS.bi.F_TPV
		   where YEAR(TPV_DATE)=2018 --or YEAR(TPV_DATE)=2019 or YEAR(TPV_DATE)=2020 
		   group by  D_COUNCIL_MEMBER_KEY
		  ) a 
	  join WARS.bi.D_COUNCIL_MEMBER RCM on a.D_COUNCIL_MEMBER_KEY=RCM.D_COUNCIL_MEMBER_KEY
	  where RCM.country like '%Hong Kong%' or RCM.country like '%China%' or RCM.country like '%Taiwan%'
	  ) b
group by b.COUNCIL_MEMBER_ID
order by b.COUNCIL_MEMBER_ID 

select sum(projects) from #perc

--select sum(projects) from #perc 
--where COUNCIL_MEMBER_ID in 
--(select distinct #list2.COUNCIL_MEMBER_ID from #MA join #list2 on #MA.COMPANY_ID=#list2.COMPANY_ID)

select sum(projects) from #perc 
where COUNCIL_MEMBER_ID in 
(select distinct #list2.COUNCIL_MEMBER_ID from #Match join #list2 on #Match.COMPANY_ID=#list2.COMPANY_ID 
where #Match.COMPANY_ID is not null and #Match.nativeName is not null and #Match.companyName is not null and #Match.CIQID is not null)


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

