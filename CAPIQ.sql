Select * FROM glglive.[taxonomy].[INDUSTRY]
Select top 100000* FROM glglive.[dbo].[COMPANY_SUBSIDIARY_RELATION_CALC]
Select * FROM CAPIQ.dbo.ciqNativeCompanyNames
--where companyId=9935271
order by companyId


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
--select d.*, c.INDUSTRY from(
select distinct d_council_member_work_history.COMPANY_ID
			  , b.ciqid
			  , d_council_member_work_history.COMPANY_NAME
			  , b.nativeName 
from WARS.bi.D_COUNCIL_MEMBER_WORK_HISTORY AS d_council_member_work_history 
join (select distinct d_council_member_work_history.COMPANY_ID
					, a.companyId as ciqid
				    , d_council_member_work_history.COMPANY_NAME
				    , a.companyName as cn
					, a.nativeName 
	  from WARS.bi.D_COUNCIL_MEMBER_WORK_HISTORY AS d_council_member_work_history 
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
order by d_council_member_work_history.COMPANY_ID

/*select a.*, glglive.[taxonomy].[INDUSTRY].INDUSTRY from
(select COMPANY_ID, INDUSTRY_ID from glglive.taxonomy.COMPANY_INDUSTRY_RELATION) a
join glglive.[taxonomy].[INDUSTRY] on a.INDUSTRY_ID=glglive.[taxonomy].[INDUSTRY].INDUSTRY_ID
where a.COMPANY_ID=122606

select * from glglive.taxonomy.COMPANY_INDUSTRY_RELATION
where COMPANY_ID=11508*/


--Method B:use glglive.[curator].[CapiqMatching] as key to join two tables
Select * FROM glglive.[curator].[CapiqMatching]
--where CompanyId=1117373
order by companyId


drop table if exists #trans
select b.CompanyId, a.companyId as CapIqId, a.nativeName, a.companyName 
into #trans 
from(Select distinct CAPIQ.dbo.ciqNativeCompanyNames.companyId
				   , CAPIQ.dbo.ciqNativeCompanyNames.nativeName
				   , CAPIQ.dbo.ciqCompany.companyName
	 FROM CAPIQ.dbo.ciqNativeCompanyNames 
	 join CAPIQ.dbo.ciqCompany
	 on CAPIQ.dbo.ciqNativeCompanyNames.companyId=CAPIQ.dbo.ciqCompany.companyId
	) a 
join (select distinct a.CompanyId, a.CapIqId 
	  FROM glglive.[curator].[CapiqMatching] a 
	  inner join (select CompanyId, max(MatchDate) MatchDate 
				  FROM glglive.[curator].[CapiqMatching]
				  group by CompanyId
				  ) b 
	  on a.CompanyId=b.CompanyId and a.MatchDate=b.MatchDate
	  ) b
on a.companyId=b.CapIqId
order by b.CompanyId


select* from #trans
order by CapIqId


select distinct d_council_member_work_history.COMPANY_ID,#trans.CapIqId
			  , d_council_member_work_history.COMPANY_NAME
			  , #trans.nativeName from WARS.bi.D_COUNCIL_MEMBER_WORK_HISTORY AS d_council_member_work_history 
join #trans on d_council_member_work_history.COMPANY_ID=#trans.CompanyId
--where d_council_member_work_history.COMPANY_ID=1117373
order by d_council_member_work_history.COMPANY_ID



--check ID in work history table
select * from 
WARS.bi.D_COUNCIL_MEMBER_WORK_HISTORY AS d_council_member_work_history
where --d_council_member_work_history.COMPANY_ID =25194 or d_council_member_work_history.COMPANY_ID =47902
--d_council_member_work_history.COMPANY_ID =291196 or d_council_member_work_history.COMPANY_ID =254602 or
--d_council_member_work_history.COMPANY_ID =320562
--d_council_member_work_history.COMPANY_ID =3168916
--d_council_member_work_history.COMPANY_ID =426321
--d_council_member_work_history.COMPANY_ID =1120132
d_council_member_work_history.COMPANY_NAME like '%alibaba%'
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
