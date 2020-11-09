/*
executionMasks:
jwt-role-glg: 17
glgjwtComment: 'Flag [17] includes = APP|USER'
*/
SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET NOCOUNT ON;
USE WARS;
--parameters:
--@startDate date
--@endDate date

IF OBJECT_ID('tempdb.dbo.#REFERRERS', 'U') IS NOT NULL
DROP TABLE #REFERRERS

IF OBJECT_ID('tempdb.dbo.#GTC', 'U') IS NOT NULL
DROP TABLE #GTC;

IF OBJECT_ID('tempdb.dbo.#Temp', 'U') IS NOT NULL
DROP TABLE #Temp;

IF OBJECT_ID('tempdb.dbo.#Active', 'U') IS NOT NULL
DROP TABLE #Active;

IF OBJECT_ID('tempdb.dbo.#TOTAL', 'U') IS NOT NULL
DROP TABLE #TOTAL;

IF OBJECT_ID('tempdb.dbo.#GROWTH', 'U') IS NOT NULL
DROP TABLE #GROWTH;

IF OBJECT_ID('tempdb.dbo.#Cluster1', 'U') IS NOT NULL
DROP TABLE #Cluster1;

IF OBJECT_ID('tempdb.dbo.#Cluster2', 'U') IS NOT NULL
DROP TABLE #Cluster2;

SELECT year(RCM.START_DATE) AS START_Year
    , Month(RCM.START_DATE) AS START_Month
    , RCM.COUNCIL_MEMBER_ID AS REFERRER_CM_ID
	, RCM.NAME AS REFERRER_CM_NAME
	, RCM.COUNTRY AS REFERRER_COUNTRY
	, CM.COUNCIL_MEMBER_ID AS REFERRAL_CM_ID
	,year(RCM.END_DATE) AS END_Year
	,Month(RCM.END_DATE) AS END_Month
INTO #REFERRERS
FROM WARS.BI.D_COUNCIL_MEMBER RCM
	INNER JOIN GLG_LOGIN.dbo.PERSON_LOGIN PL
	ON PL.PERSON_ID = RCM.PERSON_ID
	INNER JOIN GLG_LOGIN.dbo.PERSON_ROLE_RELATION PRR
	ON PRR.PERSON_ID = PL.PERSON_ID
	INNER JOIN WARS.BI.D_COUNCIL_MEMBER CM
	ON RCM.D_COUNCIL_MEMBER_KEY = CM.REFERRED_BY_D_COUNCIL_MEMBER_KEY
	AND CM.END_DATE_KEY = 99991231
WHERE PRR.PERSON_ROLE_ID = 9
	AND PRR.ACTIVE_IND = 1
	and RCM.COUNTRY='China' or RCM.COUNTRY='Hong Kong'
group by year(RCM.START_DATE)
	 , Month(RCM.START_DATE)
	 , RCM.COUNCIL_MEMBER_ID
	 , RCM.NAME
	 , RCM.COUNTRY
	 , CM.COUNCIL_MEMBER_ID
	 , year(RCM.END_DATE)
	 , Month(RCM.END_DATE);

/*select * from #REFERRERS
where START_Year>=2018
order by START_Year, START_Month,REFERRER_CM_ID*/


SELECT GCM.COUNCIL_MEMBER_ID
	, MIN(DATE.DATE) AS FIRST_GTC_DATE
INTO #GTC
FROM WARS.BI.D_COUNCIL_MEMBER GCM
	JOIN WARS.BI.F_PROJECT_MEETING_ACTIVITY FPMA
	ON FPMA.ACTIVITY_PARTICIPANT_D_COUNCIL_MEMBER_KEY = GCM.D_COUNCIL_MEMBER_KEY
	JOIN WARS.BI.D_PROJECT_ACTIVITY_STATUS FPAS
	ON FPMA.D_PROJECT_ACTIVITY_STATUS_KEY = FPAS.D_PROJECT_ACTIVITY_STATUS_KEY
	JOIN WARS.BI.D_DATE DATE
	ON FPMA.CREATED_DATE_KEY = DATE.DATE_KEY
	JOIN #REFERRERS R
	ON R.REFERRAL_CM_ID = GCM.COUNCIL_MEMBER_ID
WHERE FPAS.PROJECT_ACTIVITY_STATUS_ID = 10
	GROUP BY GCM.COUNCIL_MEMBER_ID;


--select* from #GTC;

WITH TPV AS (
SELECT CM.COUNCIL_MEMBER_ID
	, COUNT(CASE
	WHEN DP.PRODUCT_TYPE = 'PHONE CONSULTATION'
	THEN F_TPV_KEY
	END) AS CONSULT_TPV
	, COUNT(CASE
	WHEN DP.PRODUCT_TYPE IN ('IN PERSON EVENT', 'VIRTUAL EVENT')
	THEN F_TPV_KEY
	END) AS EVENT_TPV
	, COUNT(F_TPV_KEY) AS TOTAL_TPV
	, MIN(TPV_DATE) AS FIRST_TPV_DATE
FROM WARS.BI.F_TPV TPV
	JOIN WARS.BI.D_COUNCIL_MEMBER CM
	ON CM.D_COUNCIL_MEMBER_KEY = TPV.D_COUNCIL_MEMBER_KEY
	JOIN WARS.BI.D_PRODUCT DP
	ON DP.D_PRODUCT_KEY = TPV.D_PRODUCT_KEY
	JOIN #REFERRERS R
	ON R.REFERRAL_CM_ID = CM.COUNCIL_MEMBER_ID
	GROUP BY CM.COUNCIL_MEMBER_ID)
, CREATED_AT AS (
SELECT CREATED.COUNCIL_MEMBER_ID
	, MIN(CREATED.START_DATE) AS CREATE_DATE
	, MIN(CREATED.TERMS_CONDITIONS_START_DATE) FIRST_TC_DATE
FROM WARS.BI.D_COUNCIL_MEMBER CREATED
WHERE CREATED.START_DATE_KEY <> '19000101'
	--AND CREATED.START_DATE BETWEEN @startDate AND @endDate
GROUP BY CREATED.COUNCIL_MEMBER_ID)

SELECT CM.COUNCIL_MEMBER_ID AS REFERRAL_CM_ID
	, CM.NAME AS REFERRAL_CM_NAME
	, CM.COUNCIL_NAME
	, CM.IMPORT_SOURCE
	, CM.INFLOW_METHOD
	, JOB.JOB_TITLE
	, JOB.COMPANY_NAME
	, EMP.EMPLOYEENAME AS RECRUITER
	, CA.CREATE_DATE
	, CA.FIRST_TC_DATE
	, GTC.FIRST_GTC_DATE
	, TPV.FIRST_TPV_DATE
	, TPV.CONSULT_TPV
	, TPV.EVENT_TPV
	, TPV.TOTAL_TPV
	, RCM.REFERRER_CM_ID
	, RCM.REFERRER_CM_NAME
	, RCM.REFERRER_COUNTRY
	, CM.START_DATE
	, CM.END_DATE
	, CM.PRACTICE_AREA
into #Temp
FROM WARS.BI.D_COUNCIL_MEMBER CM
	INNER JOIN #REFERRERS RCM
	ON RCM.REFERRAL_CM_ID = CM.COUNCIL_MEMBER_ID
	INNER JOIN CREATED_AT CA
	ON CA.COUNCIL_MEMBER_ID = CM.COUNCIL_MEMBER_ID
	LEFT JOIN WARS.BI.D_EMP EMP
	ON EMP.D_EMP_KEY = CM.RECRUITED_BY_D_EMP_KEY
	LEFT JOIN WARS.BI.D_COUNCIL_MEMBER_WORK_HISTORY JOB
	ON JOB.COUNCIL_MEMBER_ID = CM.COUNCIL_MEMBER_ID
	AND JOB.CURRENT_IND = 1
	LEFT JOIN TPV
	ON TPV.COUNCIL_MEMBER_ID = CM.COUNCIL_MEMBER_ID
	LEFT JOIN #GTC GTC
	ON GTC.COUNCIL_MEMBER_ID = CM.COUNCIL_MEMBER_ID
WHERE CM.END_DATE_KEY = 99991231
	and RCM.REFERRER_COUNTRY='China' or RCM.REFERRER_COUNTRY='Hong Kong'
ORDER BY CA.CREATE_DATE ASC;

--select * from #Temp order by REFERRER_CM_NAME


select a.CREATE_YEAR
	, a.CREATE_MONTH
	, a.REFERRER_CM_NAME
	, a.REFERRER_CM_ID
	,case when sum(a.active_partners)>=10 then 1
	else 0 end as active_partners 
into #Active from (
select Year(CREATE_DATE) as CREATE_YEAR
	, Month(CREATE_DATE) AS CREATE_MONTH
	, REFERRER_CM_NAME
	, REFERRER_CM_ID
	, REFERRAL_CM_ID
	,count(distinct REFERRAL_CM_ID)as active_partners
from #Temp
group by Year(CREATE_DATE)
	, Month(CREATE_DATE)
	, REFERRER_CM_NAME
	, REFERRER_CM_ID
	, REFERRAL_CM_ID) a
where a.CREATE_YEAR>=2018
group by a.CREATE_YEAR
	, a.CREATE_MONTH
	, a.REFERRER_CM_NAME
	, a.REFERRER_CM_ID

--select *from #Active

select c.* into #TOTAL from
(select b.START_Year
	, b.START_Month
	, b.REFERRER_CM_NAME
	, COUNT(b.ranks) OVER (ORDER BY b.START_Year, b.START_Month rows 100000000 PRECEDING) total_partners from
(select a.* from
(select year(min(START_DATE)) AS START_Year
	, Month(min(START_DATE)) AS START_Month
	, REFERRER_CM_NAME, dense_rank() OVER (ORDER BY REFERRER_CM_ID) ranks
from #Temp
group by REFERRER_CM_NAME
	, REFERRER_CM_ID) a
group by a.START_Year
	, a.START_Month
	, a.REFERRER_CM_NAME
	, a.ranks) b
group by b.START_Year
	, b.START_Month
	, b.REFERRER_CM_NAME
	, b.ranks) c
where c.START_Year>=2018
order by c.start_year, c.START_Month

--select *from #TOTAL

select c.*,
cast(cast(c.active_partners as decimal(18,2))/c.total_partners as decimal(18,2)) as perc_active,
cast(cast(c.total_partners-LAG(c.total_partners) OVER (ORDER BY c.Years ) as decimal(18,2))/ LAG(c.total_partners) OVER (ORDER BY c.Years ) as decimal(18,2)) AS total_growth 
into #GROWTH from (
select #Active.CREATE_YEAR as Years
	,#Active.CREATE_MONTH as Months
	,#Active.active_partners
	,max(#TOTAL.total_partners) as total_partners
from (select CREATE_YEAR, CREATE_MONTH, sum(active_partners) as active_partners
from #Active
group by CREATE_YEAR, CREATE_MONTH)#Active join #TOTAL on
#Active.CREATE_YEAR=#TOTAL.START_Year and #Active.CREATE_MONTH=#TOTAL.START_Month
group by #Active.CREATE_YEAR
	,#Active.CREATE_MONTH
	,#Active.active_partners) c
order by c.Years
	,c.Months

--select *from #GROWTH

select a.REFERRER_CM_NAME
	, a.REFERRER_CM_ID
	, sum(a.projects) as projects 
	,sum(a.GTC) as success
	,cast(cast(sum(a.GTC) as decimal(18,2))/sum(a.projects) as decimal(18,2)) as success_rate
into #Cluster1 from (
select Year(CREATE_DATE) as CREATE_YEAR
	, Month(CREATE_DATE) AS CREATE_MONTH
	, REFERRER_CM_NAME
	, REFERRER_CM_ID
	, count(distinct REFERRAL_CM_ID)as projects
	, case when FIRST_GTC_DATE is not null then 1
	else 0 end as GTC
from #Temp
where Year(CREATE_DATE)>=2020
group by Year(CREATE_DATE)
	, Month(CREATE_DATE)
	, REFERRER_CM_NAME
	, REFERRER_CM_ID
	, FIRST_GTC_DATE) a
group by a.REFERRER_CM_NAME, a.REFERRER_CM_ID


select distinct REFERRER_CM_NAME, REFERRER_CM_ID, projects,success, success_rate, 
case when success_rate>=0.023 and projects>=100 then 'H-H'
when success_rate>=0.023 and projects<100 then 'L-H'
when success_rate<0.023 and projects>=100 then 'H-L'
else 'L-L' end as act_success
from #Cluster1
order by projects desc


select b.REFERRER_CM_NAME
	, b.REFERRER_CM_ID
	, case when sum(b.active)=10 then 1
	else 0 end as active
into #Cluster2
from
(select a.REFERRER_CM_NAME
	, a.REFERRER_CM_ID
	, case when a.projects>=1 then 1
	else 0 end as active 
from 
(select Year(CREATE_DATE) as CREATE_YEAR
	, Month(CREATE_DATE) AS CREATE_MONTH
	, REFERRER_CM_NAME
	, REFERRER_CM_ID
	, count(distinct REFERRAL_CM_ID)as projects
from #Temp
where Year(CREATE_DATE)>=2020
group by REFERRER_CM_NAME
	, REFERRER_CM_ID
	, Year(CREATE_DATE)
	, Month(CREATE_DATE)) a
group by a.REFERRER_CM_NAME
	, a.REFERRER_CM_ID
	, a.projects) b
group by b.REFERRER_CM_NAME, b.REFERRER_CM_ID


select #Cluster1.*, #Cluster2.active, 
case when #Cluster1.success_rate>=0.023 and #Cluster2.active=1 then 'H-H'
when #Cluster1.success_rate>=0.023 and #Cluster2.active=0 then 'L-H'
when #Cluster1.success_rate<0.023 and #Cluster2.active=1 then 'H-L'
else 'L-L' end as act_success
from #Cluster1 join #Cluster2 on
#Cluster1.REFERRER_CM_ID=#Cluster2.REFERRER_CM_ID
order by #Cluster1.projects desc



select a.COUNCIL_NAME, count(distinct a.REFERRER_CM_ID) as amount from (
select distinct REFERRER_CM_ID
	, REFERRER_CM_NAME
	, REFERRAL_CM_ID
	, COUNCIL_NAME from #Temp) a
group by a.COUNCIL_NAME


select a.COUNCIL_NAME, count(distinct a.REFERRAL_CM_ID) as amount from (
select distinct REFERRAL_CM_ID
	, REFERRAL_CM_NAME
	, COUNCIL_NAME from #Temp) a
group by a.COUNCIL_NAME


/*select top 10* from WARS.BI.D_COUNCIL_MEMBER*/
