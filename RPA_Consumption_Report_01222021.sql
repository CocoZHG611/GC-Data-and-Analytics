DROP TABLE IF EXISTS #REFERRERS
SELECT RCM.COUNCIL_MEMBER_ID AS REFERRER_CM_ID
	, RCM.NAME AS REFERRER_CM_NAME
	, RCM.COUNTRY AS REFERRER_COUNTRY
	, CM.COUNCIL_MEMBER_ID AS REFERRAL_CM_ID
into #REFERRERS
FROM WARS.BI.D_COUNCIL_MEMBER RCM
   --INNER JOIN GLG_LOGIN.dbo.PERSON_LOGIN PL
	--ON PL.PERSON_ID = RCM.PERSON_ID
	--INNER JOIN GLG_LOGIN.dbo.PERSON_ROLE_RELATION PRR
	--ON PRR.PERSON_ID = PL.PERSON_ID
	INNER JOIN WARS.BI.D_COUNCIL_MEMBER CM
	ON RCM.D_COUNCIL_MEMBER_KEY = CM.REFERRED_BY_D_COUNCIL_MEMBER_KEY
	AND CM.END_DATE_KEY = 99991231
WHERE RCM.IS_RECRUITING_PARTNER = 'true'

select * from #REFERRERS


DROP TABLE IF EXISTS #GTC
SELECT GCM.COUNCIL_MEMBER_ID
, MIN(DATE.DATE) AS FIRST_GTC_DATE
into #GTC
FROM WARS.BI.D_COUNCIL_MEMBER GCM
JOIN WARS.BI.F_PROJECT_MEETING_ACTIVITY FPMA ON FPMA.ACTIVITY_PARTICIPANT_D_COUNCIL_MEMBER_KEY = GCM.D_COUNCIL_MEMBER_KEY
JOIN WARS.BI.D_PROJECT_ACTIVITY_STATUS FPAS ON FPMA.D_PROJECT_ACTIVITY_STATUS_KEY = FPAS.D_PROJECT_ACTIVITY_STATUS_KEY
JOIN WARS.BI.D_DATE DATE ON FPMA.CREATED_DATE_KEY = DATE.DATE_KEY
JOIN #REFERRERS R ON R.REFERRAL_CM_ID = GCM.COUNCIL_MEMBER_ID
WHERE FPAS.PROJECT_ACTIVITY_STATUS_ID = 10
GROUP BY GCM.COUNCIL_MEMBER_ID

select * from #GTC


DROP TABLE IF EXISTS #TPV
SELECT CM.COUNCIL_MEMBER_ID
	 , COUNT(CASE WHEN DP.PRODUCT_TYPE = 'PHONE CONSULTATION' THEN F_TPV_KEY END) AS CONSULT_TPV
	 , COUNT(CASE WHEN DP.PRODUCT_TYPE IN ('IN PERSON EVENT', 'VIRTUAL EVENT') THEN F_TPV_KEY END) AS EVENT_TPV
	 , COUNT(F_TPV_KEY) AS TOTAL_TPV
	 , MIN(TPV_DATE) AS FIRST_TPV_DATE
into #TPV
FROM WARS.BI.F_TPV TPV
JOIN WARS.BI.D_COUNCIL_MEMBER CM ON CM.D_COUNCIL_MEMBER_KEY = TPV.D_COUNCIL_MEMBER_KEY
JOIN WARS.BI.D_PRODUCT DP ON DP.D_PRODUCT_KEY = TPV.D_PRODUCT_KEY
JOIN #REFERRERS R ON R.REFERRAL_CM_ID = CM.COUNCIL_MEMBER_ID
GROUP BY CM.COUNCIL_MEMBER_ID

select * from #TPV


DROP TABLE IF EXISTS #CREATED_AT
SELECT CREATED.COUNCIL_MEMBER_ID
	 , MIN(CREATED.START_DATE) AS CREATE_DATE
	 , MIN(CREATED.TERMS_CONDITIONS_START_DATE) FIRST_TC_DATE
into #CREATED_AT
FROM WARS.BI.D_COUNCIL_MEMBER CREATED
WHERE CREATED.START_DATE_KEY <> '19000101'
	--AND CREATED.START_DATE BETWEEN @startDate AND @endDate
GROUP BY CREATED.COUNCIL_MEMBER_ID

select * from #CREATED_AT


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
	 , #GTC.FIRST_GTC_DATE
	 , #TPV.FIRST_TPV_DATE
	 , #TPV.CONSULT_TPV
	 , #TPV.EVENT_TPV
	 , #TPV.TOTAL_TPV
	 , RCM.REFERRER_CM_ID
	 , RCM.REFERRER_CM_NAME
	 , RCM.REFERRER_COUNTRY
FROM WARS.BI.D_COUNCIL_MEMBER CM
INNER JOIN #REFERRERS RCM ON RCM.REFERRAL_CM_ID = CM.COUNCIL_MEMBER_ID
INNER JOIN #CREATED_AT CA ON CA.COUNCIL_MEMBER_ID = CM.COUNCIL_MEMBER_ID
LEFT JOIN WARS.BI.D_EMP EMP ON EMP.D_EMP_KEY = CM.RECRUITED_BY_D_EMP_KEY
LEFT JOIN WARS.BI.D_COUNCIL_MEMBER_WORK_HISTORY JOB ON JOB.COUNCIL_MEMBER_ID = CM.COUNCIL_MEMBER_ID AND JOB.CURRENT_IND = 1
LEFT JOIN #TPV ON #TPV.COUNCIL_MEMBER_ID = CM.COUNCIL_MEMBER_ID
LEFT JOIN #GTC ON #GTC.COUNCIL_MEMBER_ID = CM.COUNCIL_MEMBER_ID
WHERE CM.END_DATE_KEY = 99991231
ORDER BY CA.CREATE_DATE ASC;


SELECT CM.COUNCIL_MEMBER_ID AS REFERRAL_CM_ID
	 , CM.NAME AS REFERRAL_CM_NAME
	 , RCM.REFERRER_CM_ID
	 , RCM.REFERRER_CM_NAME
	 , RCM.REFERRER_COUNTRY
	 , convert(varchar, CA.CREATE_DATE, 101) as CREATE_DATE
	 , convert(varchar, CA.FIRST_TC_DATE, 101) as FIRST_TC_DATE
	 , convert(varchar, #GTC.FIRST_GTC_DATE, 101) as FIRST_GTC_DATE
	 , convert(varchar, #TPV.FIRST_TPV_DATE, 101) as FIRST_TPV_DATE
	 , case when #TPV.FIRST_TPV_DATE is not null then 1 else 0 end as CRP
FROM WARS.BI.D_COUNCIL_MEMBER CM
INNER JOIN #REFERRERS RCM ON RCM.REFERRAL_CM_ID = CM.COUNCIL_MEMBER_ID
INNER JOIN #CREATED_AT CA ON CA.COUNCIL_MEMBER_ID = CM.COUNCIL_MEMBER_ID
LEFT JOIN WARS.BI.D_EMP EMP ON EMP.D_EMP_KEY = CM.RECRUITED_BY_D_EMP_KEY
LEFT JOIN WARS.BI.D_COUNCIL_MEMBER_WORK_HISTORY JOB ON JOB.COUNCIL_MEMBER_ID = CM.COUNCIL_MEMBER_ID AND JOB.CURRENT_IND = 1
LEFT JOIN #TPV ON #TPV.COUNCIL_MEMBER_ID = CM.COUNCIL_MEMBER_ID
LEFT JOIN #GTC ON #GTC.COUNCIL_MEMBER_ID = CM.COUNCIL_MEMBER_ID
WHERE CM.END_DATE_KEY = 99991231
ORDER BY CA.CREATE_DATE ASC;
