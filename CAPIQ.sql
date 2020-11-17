Select * FROM glglive.[taxonomy].[INDUSTRY]
Select top 100000* FROM glglive.[dbo].[COMPANY_SUBSIDIARY_RELATION_CALC]
Select * FROM CAPIQ.dbo.ciqNativeCompanyNames
order by companyId

select distinct d_council_member_work_history.COMPANY_ID, d_council_member_work_history.COMPANY_NAME
, b.nativeName from
WARS.bi.D_COUNCIL_MEMBER_WORK_HISTORY AS d_council_member_work_history join
(select distinct d_council_member_work_history.COMPANY_ID, d_council_member_work_history.COMPANY_NAME, a.companyName as cn,a.nativeName from 
WARS.bi.D_COUNCIL_MEMBER_WORK_HISTORY AS d_council_member_work_history join 
(Select distinct CAPIQ.dbo.ciqNativeCompanyNames.companyId,
CAPIQ.dbo.ciqNativeCompanyNames. nativeName,
CAPIQ.dbo.ciqCompany.companyName
FROM CAPIQ.dbo.ciqNativeCompanyNames join CAPIQ.dbo.ciqCompany
on CAPIQ.dbo.ciqNativeCompanyNames.companyId=CAPIQ.dbo.ciqCompany.companyId) a 
on d_council_member_work_history.COMPANY_NAME=a.companyName
where d_council_member_work_history.COMPANY_ID is not NULL) b on d_council_member_work_history.COMPANY_ID=b.COMPANY_ID
order by d_council_member_work_history.COMPANY_ID


/*SELECT d_council_member.COUNCIL_MEMBER_ID  AS "CM_ID"
	, d_council_member.NAME  AS "CM_NAME"
	, d_council_member_work_history.COMPANY_NAME  AS "Company_Name"
	, d_council_member_work_history.START_YEAR  AS "Start_year"
FROM WARS.bi.D_COUNCIL_MEMBER  AS d_council_member
LEFT JOIN WARS.bi.D_COUNCIL_MEMBER_WORK_HISTORY AS d_council_member_work_history ON d_council_member_work_history.COUNCIL_MEMBER_ID=d_council_member.COUNCIL_MEMBER_ID
WHERE d_council_member.COUNCIL_MEMBER_ID  = 527022*/


select * from 
WARS.bi.D_COUNCIL_MEMBER_WORK_HISTORY AS d_council_member_work_history
where d_council_member_work_history.COMPANY_ID =25194 or d_council_member_work_history.COMPANY_ID =47902
--d_council_member_work_history.COMPANY_ID =291196 or d_council_member_work_history.COMPANY_ID =254602 or
--d_council_member_work_history.COMPANY_ID =320562
--d_council_member_work_history.COMPANY_ID =3168916
--d_council_member_work_history.COMPANY_NAME like '%ALIBABA%'
order by d_council_member_work_history.COMPANY_ID,d_council_member_work_history.COMPANY_NAME


/*select d_council_member_work_history.*, CAPIQ.nativeName from 
WARS.bi.D_COUNCIL_MEMBER_WORK_HISTORY AS d_council_member_work_history join CAPIQ.dbo.ciqNativeCompanyNames AS CAPIQ
on d_council_member_work_history.COMPANY_ID=CAPIQ.companyId
order by d_council_member_work_history.COMPANY_ID, d_council_member_work_history.COUNCIL_MEMBER_ID*/


select b.INDUSTRY, b.SUB_INDUSTRY, b.SUB_SUB_INDUSTRY from 
(select a.*, CHILD.INDUSTRY AS SUB_SUB_INDUSTRY from 
(select PARENT.*, CHILD.INDUSTRY_ID AS SUB_INDUSTRY_ID, CHILD.INDUSTRY AS SUB_INDUSTRY from 
glglive.[taxonomy].[INDUSTRY] AS PARENT join glglive.[taxonomy].[INDUSTRY] AS CHILD on PARENT.INDUSTRY_ID=CHILD.PARENT_INDUSTRY_ID
where PARENT.PARENT_INDUSTRY_ID is null) a
left join glglive.[taxonomy].[INDUSTRY] AS CHILD on a.SUB_INDUSTRY_ID=CHILD.PARENT_INDUSTRY_ID) b
order by b.INDUSTRY


drop table if exists #temp 
select *,
	case when ULTIMATE_PARENT_IND=1 THEN 1
	ELSE 2 END LEVEL
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
   set LEVEL=LEVEL+1
   where COMPANY_ID IN (SELECT MEMBER_COMPANY_ID FROM #temp where LEVEL=@ind)
   and LEVEL=@ind
   select @level=max(LEVEL) from #temp
   select @count=count(COMPANY_ID) from #temp where LEVEL=@level
END


select * from #temp 
where LEVEL=25
order by LEVEL, COMPANY_ID, MEMBER_COMPANY_ID

select c.COMPANY_ID, max(c.LEVEL) as LEVEL from 
(SELECT a.COMPANY_ID, a.LEVEL
  FROM (select distinct COMPANY_ID, LEVEL from #temp) a
UNION 
SELECT b.MEMBER_COMPANY_ID as COMPANY_ID, b.LEVEL
  FROM (select distinct #temp.MEMBER_COMPANY_ID,
	case when a.MEMBER_COMPANY_ID is not null then #temp.LEVEL
	else #temp.LEVEL+1 end as LEVEL
from #temp JOIN #temp a on #temp.COMPANY_ID=a.MEMBER_COMPANY_ID
where #temp.MEMBER_COMPANY_ID not in (select COMPANY_ID from #temp)) b) c
group by c.COMPANY_ID
order by LEVEL, c.COMPANY_ID

