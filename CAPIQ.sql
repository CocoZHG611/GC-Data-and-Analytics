Select * FROM glglive.[taxonomy].[INDUSTRY]
Select top 10000* FROM glglive.[dbo].[COMPANY_SUBSIDIARY_RELATION_CALC]
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
where --d_council_member_work_history.COMPANY_ID =25194 or d_council_member_work_history.COMPANY_ID =47902
--or d_council_member_work_history.COMPANY_ID =291196 or d_council_member_work_history.COMPANY_ID =254602 or 
--d_council_member_work_history.COMPANY_ID =320562 or 
d_council_member_work_history.COMPANY_ID =54 or d_council_member_work_history.COMPANY_ID =6176935
or d_council_member_work_history.COMPANY_ID =7014013
order by d_council_member_work_history.COMPANY_ID, d_council_member_work_history.COMPANY_NAME


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


select sub.COMPANY_ID, a.COMPANY_NAME as PARENT_COMPANY_NAME,
sub.LAST_UPDATE_DATE, sub.MEMBER_COMPANY_ID, b.COMPANY_NAME AS MEMBER_COMPANY_NAME, sub.ULTIMATE_PARENT_IND
from glglive.[dbo].[COMPANY_SUBSIDIARY_RELATION_CALC] sub left join 
(select distinct COMPANY_ID, COMPANY_NAME from WARS.bi.D_COUNCIL_MEMBER_WORK_HISTORY) a
on sub.COMPANY_ID=a.COMPANY_ID
left join (select distinct COMPANY_ID, COMPANY_NAME from WARS.bi.D_COUNCIL_MEMBER_WORK_HISTORY) b
on sub.MEMBER_COMPANY_ID=b.COMPANY_ID
where sub.ULTIMATE_PARENT_IND=1
order by sub.COMPANY_ID, sub.MEMBER_COMPANY_ID

