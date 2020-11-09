SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET NOCOUNT ON;
USE WARS;

IF OBJECT_ID('tempdb.dbo.#Temp', 'U') IS NOT NULL
DROP TABLE #Temp;

/*select * from consult.consultation_target_countries ctc
 where ctc.consultation_id IN (2895635,2895635,2949039,2968722,2969873);*/


WITH d_emp AS (select
            cc.hire_date as HIRE_DATE_KEY,
            e.*,
            e_latest.EmployeeName as Current_Employee_Name,
            e_latest.BU as Current_BU,
            e_latest.TEAM as Current_TEAM,
            e_latest.SEGMENT as Current_SEGMENT,
            e_latest.POD as Current_Pod,
            e_latest.FUSION_BUSINESS_UNIT as Current_FUSION_BUSINESS_UNIT,
            prev_record.D_EMP_KEY as prev_d_emp_key
          from WARS.bi.D_EMP e
          outer apply (
                select min(start_date_key) as hire_date
                from WARS.bi.D_EMP ee
                where e.user_id = ee.user_id
                and ee.EMPLOYMENT_STATUS = 'Employed as GLG employee'
          ) cc
          outer apply (
                select TOP 1 eee.D_EMP_KEY
                from WARS.bi.D_EMP eee
                where e.user_id = eee.user_id
                and eee.END_DATE_KEY < e.END_DATE_KEY
                order by eee.END_DATE_KEY DESC
          ) prev_record
          inner join WARS.bi.D_EMP e_latest on
            e.user_id = e_latest.user_id
            and e_latest.END_DATE_KEY = 99991231  )
  ,  d_client AS (select
                c.*,
                cl.PL_NAME as CURRENT_PL_NAME
              from WARS.bi.D_CLIENT c
              inner join WARS.bi.D_CLIENT cl on
                cl.CLIENT_ID = c.CLIENT_ID
                and cl.END_DATE_KEY = 99991231  )
	, d_user AS (select
                u.*,
                u_latest.PL_NAME as Current_PL_NAME,
                u_latest.PL_STRATEGY as CURRENT_PL_STRATEGY,
                u_latest.PL_SEGMENT as CURRENT_PL_SEGMENT,
                u_latest.PL_LOCATION as CURRENT_PL_LOCATION,
                u_latest.PL_REGION as CURRENT_PL_REGION
              from WARS.bi.D_USER u
              inner join WARS.bi.D_USER u_latest on
                u.CONTACT_ID = u_latest.CONTACT_ID
                and u_latest.END_DATE_KEY = 99991231  )



SELECT
	d_date_proj.DATE AS CREATE_DATE,
	f_project.PROJECT_ID  AS proj_id,
	f_project.TITLE  AS proj_title,
	d_emp_pcsp.EMPLOYEENAME  AS employee_name,
	d_emp_pcsp.PERSON_ID AS employee_ID,
	d_emp_pcsp.POD  AS pod,
	d_emp_pcsp.BU  AS bu,
	d_tpv_client.CLIENT_ID  AS client_id,
	d_tpv_client.CLIENT_NAME  AS client_name,
	cedp.PUBLISH_CHANNEL AS Publish_Channel,
	SA.STATUS_DATE AS ATTACHED_DATE,
	SG.STATUS_DATE AS GTC_DATE,
	TPV.FIRST_TPV_DATE,
	ISNULL(DATEDIFF(DAY, d_date_proj.DATE, SA.STATUS_DATE),0) as ATTACH_speed,
	ISNULL(DATEDIFF(DAY, d_date_proj.DATE, SG.STATUS_DATE),0) as GTC_speed,
	ISNULL(DATEDIFF(DAY, d_date_proj.DATE, TPV.FIRST_TPV_DATE),0) as tpv_speed,
	COUNT(DISTINCT f_tpv.F_TPV_KEY ) AS tpv_count,
	COUNT(DISTINCT CASE WHEN (f_tpv.RP_STATUS = 'CRP') THEN f_tpv.F_TPV_KEY   ELSE NULL END) AS tpv_crp_1
into #Temp
FROM WARS.bi.F_PROJECT  AS f_project
	LEFT JOIN WARS.bi.F_TPV  AS f_tpv ON f_project.F_PROJECT_KEY = f_tpv.F_PROJECT_KEY
	LEFT JOIN WARS.bi.D_DATE  AS d_date ON d_date.DATE_KEY = f_tpv.TPV_DATE_KEY
	LEFT JOIN WARS.bi.D_DATE  AS d_date_proj ON d_date_proj.DATE_KEY = f_project.CREATE_DATE_KEY
	LEFT JOIN d_client AS d_tpv_client ON d_tpv_client.D_CLIENT_KEY = f_tpv.D_CLIENT_KEY
	LEFT JOIN WARS.bi.D_PRODUCT  AS project_product ON f_project.D_PRODUCT_KEY = project_product.D_PRODUCT_KEY
	LEFT JOIN d_emp AS d_emp_pcsp ON f_project.PRIMARY_RM_D_EMP_KEY = d_emp_pcsp.D_EMP_KEY
	LEFT JOIN GLGLIVE.consult.CONSULTATION_Expertise_Description_Publish cedp ON cedp.consultation_ID = f_project.project_id
	LEFT JOIN d_user ON d_user.D_USER_KEY = f_project.PRIMARY_CONSULTATION_USER_KEY
	LEFT JOIN (select distinct f_project.PROJECT_ID
							 , f_project.F_PROJECT_KEY
							 , MAX(f_project.CREATE_DATE) as CREATE_DATE
							 , MIN(f_tpv.TPV_DATE) AS FIRST_TPV_DATE 
				from WARS.bi.F_PROJECT  AS f_project 
				LEFT JOIN WARS.bi.F_TPV  AS f_tpv ON f_project.F_PROJECT_KEY = f_tpv.F_PROJECT_KEY
				group by f_project.PROJECT_ID, f_project.F_PROJECT_KEY
			  ) TPV on f_project.F_PROJECT_KEY = TPV.F_PROJECT_KEY
	LEFT JOIN (select f_project.F_PROJECT_KEY
					, MIN(pma.CREATED_DATE) AS STATUS_DATE
			    from WARS.bi.F_PROJECT  AS f_project
				LEFT JOIN WARS.bi.F_PROJECT_MEETING_ACTIVITY AS PMA on f_project.PROJECT_ID=PMA.PROJECT_ID
				LEFT JOIN WARS.bi.D_PROJECT_ACTIVITY_STATUS AS PROJ_ACTS on PMA.D_PROJECT_ACTIVITY_STATUS_KEY=PROJ_ACTS.D_PROJECT_ACTIVITY_STATUS_KEY
				where PROJECT_ACTIVITY_STATUS='Attached' or PROJECT_ACTIVITY_STATUS='Added to List' 
				group by f_project.F_PROJECT_KEY) SA ON SA.F_PROJECT_KEY=f_project.F_PROJECT_KEY
	LEFT JOIN (select f_project.F_PROJECT_KEY
					, MIN(pma.CREATED_DATE) AS STATUS_DATE
				from WARS.bi.F_PROJECT  AS f_project
				LEFT JOIN WARS.bi.F_PROJECT_MEETING_ACTIVITY AS PMA on f_project.PROJECT_ID=PMA.PROJECT_ID
				LEFT JOIN WARS.bi.D_PROJECT_ACTIVITY_STATUS AS PROJ_ACTS on PMA.D_PROJECT_ACTIVITY_STATUS_KEY=PROJ_ACTS.D_PROJECT_ACTIVITY_STATUS_KEY
				where PROJECT_ACTIVITY_STATUS='Published' or PROJECT_ACTIVITY_STATUS='Given to Client' or PROJECT_ACTIVITY_STATUS='Proposed'
				group by f_project.F_PROJECT_KEY) SG ON SG.F_PROJECT_KEY=f_project.F_PROJECT_KEY
	WHERE (project_product.PRODUCT_Name = 'Phone Consultation') 
	AND (d_user.PL_NAME = 'Greater China')
	AND YEAR(d_date_proj.DATE ) >= 2019
GROUP BY 
	d_date_proj.DATE,
	d_tpv_client.CLIENT_SFDC_ID ,
	f_project.PROJECT_ID ,
	f_project.TITLE ,
	d_emp_pcsp.PERSON_ID ,
	d_emp_pcsp.EMPLOYEENAME ,
	d_emp_pcsp.POD ,d_emp_pcsp.BU ,
	d_tpv_client.CLIENT_ID ,
	d_tpv_client.CLIENT_NAME,
	cedp.PUBLISH_CHANNEL,
	TPV.FIRST_TPV_DATE,
	SA.STATUS_DATE,
	SG.STATUS_DATE


/*select * from WARS.bi.F_PROJECT  AS f_project LEFT JOIN WARS.bi.F_TPV  AS f_tpv 
ON f_project.F_PROJECT_KEY = f_tpv.F_PROJECT_KEY
where f_project.PROJECT_ID=2969873
order by f_project.PROJECT_ID*/

select * from #Temp 
where Publish_Channel='recruiting partner'
order by employee_ID,proj_id, CREATE_DATE

select a.*
	, cast(cast(a.success_proj as decimal(18,2))/a.total_proj as decimal(18,2)) as success_rate 
	, cast(cast(a.total_tpv as decimal(18,2))/a.total_proj as decimal(18,2)) as yield 
	, cast(cast(a.total_ATTACH_speed as decimal(18,2))/a.ATTACH_speed_proj as decimal(18,2)) as ATTACH_speed
	, cast(cast(a.total_GTC_speed as decimal(18,2))/a.GTC_speed_proj as decimal(18,2)) as GTC_speed
	, cast(cast(a.total_tpv_speed as decimal(18,2))/a.tpv_speed_proj as decimal(18,2)) as TPV_speed 
from( 
select Year(CREATE_DATE) as CREATE_YEAR
	, MONTH(CREATE_DATE) as CREATE_MONTH
	, Publish_Channel
	, count(proj_id) as total_proj
	, COUNT(CASE WHEN tpv_count<>0 THEN tpv_count END) as success_proj
	, COUNT(CASE WHEN ATTACH_speed<>0 THEN ATTACH_speed END) as ATTACH_speed_proj
	, COUNT(CASE WHEN GTC_speed<>0 THEN GTC_speed END) as GTC_speed_proj
	, COUNT(CASE WHEN tpv_speed<>0 THEN tpv_speed END) as tpv_speed_proj
	, sum(tpv_count) as total_tpv
	, sum(ATTACH_speed) as total_ATTACH_speed
	, sum(GTC_speed) as total_GTC_speed
	, sum(tpv_speed) as total_tpv_speed
from #Temp
group by Year(CREATE_DATE)
	, MONTH(CREATE_DATE)
	, Publish_Channel) a
order by a.Publish_Channel, a.CREATE_Year
	, a.CREATE_MONTH


--select distinct PROJECT_ACTIVITY_STATUS from WARS.bi.D_PROJECT_ACTIVITY_STATUS
--order by PROJECT_ACTIVITY_STATUS

select a.*
	, cast(cast(a.success_proj as decimal(18,2))/a.total_proj as decimal(18,2)) as success_rate 
	, cast(cast(a.total_tpv as decimal(18,2))/a.total_proj as decimal(18,2)) as yield 
	, cast(cast(a.total_ATTACH_speed as decimal(18,2))/a.ATTACH_speed_proj as decimal(18,2)) as ATTACH_speed
	, cast(cast(a.total_GTC_speed as decimal(18,2))/a.GTC_speed_proj as decimal(18,2)) as GTC_speed
	, cast(cast(a.total_tpv_speed as decimal(18,2))/a.tpv_speed_proj as decimal(18,2)) as TPV_speed 
from( 
select Year(CREATE_DATE) as CREATE_YEAR
	, MONTH(CREATE_DATE) as CREATE_MONTH
	, pod
	, Publish_Channel
	, count(proj_id) as total_proj
	, COUNT(CASE WHEN tpv_count<>0 THEN tpv_count END) as success_proj
	, COUNT(CASE WHEN ATTACH_speed<>0 THEN ATTACH_speed END) as ATTACH_speed_proj
	, COUNT(CASE WHEN GTC_speed<>0 THEN GTC_speed END) as GTC_speed_proj
	, COUNT(CASE WHEN tpv_speed<>0 THEN tpv_speed END) as tpv_speed_proj
	, sum(tpv_count) as total_tpv
	, sum(ATTACH_speed) as total_ATTACH_speed
	, sum(GTC_speed) as total_GTC_speed
	, sum(tpv_speed) as total_tpv_speed
from #Temp
where pod='FS - Beijing FS' or pod='FS - Shanghai FS' or pod='FS - South China FS' or pod='FS - Greater China Private Equity'
group by Year(CREATE_DATE)
	, MONTH(CREATE_DATE)
	, pod
	, Publish_Channel) a
order by a.Publish_Channel, a.pod, a.CREATE_Year
	, a.CREATE_MONTH

select a.*
	, ISNULL(cast(cast(a.success_proj as decimal(18,2))/NULLIF(a.total_proj,0) as decimal(18,2)),0) as success_rate 
	, ISNULL(cast(cast(a.total_tpv as decimal(18,2))/NULLIF(a.total_proj,0) as decimal(18,2)),0) as yield 
	, ISNULL(cast(cast(a.total_ATTACH_speed as decimal(18,2))/NULLIF(a.ATTACH_speed_proj,0) as decimal(18,2)),0) as ATTACH_speed
	, ISNULL(cast(cast(a.total_GTC_speed as decimal(18,2))/NULLIF(a.GTC_speed_proj,0) as decimal(18,2)),0) as GTC_speed
	, ISNULL(cast(cast(a.total_tpv_speed as decimal(18,2))/NULLIF(a.tpv_speed_proj,0) as decimal(18,2)),0) as TPV_speed 
from( 
select distinct employee_ID
	, Publish_Channel
	, count(proj_id) as total_proj
	, COUNT(CASE WHEN tpv_count<>0 THEN tpv_count END) as success_proj
	, COUNT(CASE WHEN ATTACH_speed<>0 THEN ATTACH_speed END) as ATTACH_speed_proj
	, COUNT(CASE WHEN GTC_speed<>0 THEN GTC_speed END) as GTC_speed_proj
	, COUNT(CASE WHEN tpv_speed<>0 THEN tpv_speed END) as tpv_speed_proj
	, sum(tpv_count) as total_tpv
	, sum(ATTACH_speed) as total_ATTACH_speed
	, sum(GTC_speed) as total_GTC_speed
	, sum(tpv_speed) as total_tpv_speed
from #Temp
group by employee_ID
	, Publish_Channel) a
order by a.Publish_Channel, a.employee_ID

select a.*
	, cast(cast(a.success_proj as decimal(18,2))/a.total_proj as decimal(18,2)) as success_rate 
	, cast(cast(a.total_tpv as decimal(18,2))/a.total_proj as decimal(18,2)) as yield 
	, cast(cast(a.total_proj-LAG(a.total_proj) OVER (ORDER BY a.CREATE_YEAR, a.CREATE_MONTH) as decimal(18,2))/ LAG(a.total_proj) OVER (ORDER BY a.CREATE_YEAR, a.CREATE_MONTH ) as decimal(18,2)) AS total_growth 
from( 
select Year(CREATE_DATE) as CREATE_YEAR
	, MONTH(CREATE_DATE) as CREATE_MONTH
	, count(proj_id) as total_proj
	, COUNT(CASE WHEN tpv_count<>0 THEN tpv_count END) as success_proj
	, sum(tpv_count) as total_tpv
from #Temp
where Publish_Channel='recruiting partner'
group by Year(CREATE_DATE)
	, MONTH(CREATE_DATE)) a
order by a.CREATE_Year
	, a.CREATE_MONTH
