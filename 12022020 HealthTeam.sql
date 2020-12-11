WITH d_emp AS (select
                cc.hire_date as HIRE_DATE_KEY,
                e.*,
                e_latest.EmployeeName as Current_Employee_Name,
                e_latest.BU as Current_BU,
                e_latest.TEAM as Current_TEAM,
                e_latest.SEGMENT as Current_SEGMENT,
                e_latest.POD as Current_Pod,
                e_latest.FUSION_BUSINESS_UNIT as Current_FUSION_BUSINESS_UNIT,
                e_latest.IS_CDA as CURRENT_IS_CDA,
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
                e.user_id = e_latest.user_id and e_latest.END_DATE_KEY = 99991231
               )
  ,  d_user AS (select
                u.*,
                u_latest.PL_NAME as Current_PL_NAME,
                u_latest.PL_STRATEGY as CURRENT_PL_STRATEGY,
                u_latest.PL_SEGMENT as CURRENT_PL_SEGMENT,
                u_latest.PL_LOCATION as CURRENT_PL_LOCATION,
                u_latest.PL_REGION as CURRENT_PL_REGION,
                u_latest.AT_FIRM as CURRENT_AT_FIRM,
                u_latest.PROFESSIONAL_EXPERIENCE as CURRENT_PROFESSIONAL_EXPERIENCE,
                u_latest.Title as CURRENT_TITLE,
                latest_cs.fusion_id as CURRENT_CS_FUSION_ID
              from WARS.bi.D_USER u
              inner join WARS.bi.D_USER u_latest on
                u.CONTACT_ID = u_latest.CONTACT_ID
                and u_latest.END_DATE_KEY = 99991231
            left join WARS.bi.d_emp latest_cs on
                latest_cs.d_emp_key = u_latest.USER_RESEARCH_OWNER_D_EMP_KEY)
SELECT
    d_user_research_owner.POD  AS "d_user_research_owner.pod",
	dc.client_id,
    f_project.PROJECT_ID  AS "f_project.project_id",
    CONVERT(VARCHAR(7),d_date.DATE ,120) AS "d_date.date_month",
    f_project.TITLE  AS "f_project.title",
    d_emp_tpv_owner.EMPLOYEENAME  AS "d_emp_tpv_owner.employeename",
    d_emp_tpv_owner.TEAM  AS "d_emp_tpv_owner.team",
    tpv_product.product_name
	,tpv_product.product_type
	,COUNT(DISTINCT f_tpv.F_TPV_KEY ) AS TPV
	,CASE WHEN tpv_product.Product_Type = 'Phone Consultation' or tpv_product.Product_Name = 'Consultation Transcript' then 1*count(DISTINCT f_tpv.F_TPV_KEY)
	 WHEN tpv_product.Product_Type in ('BTC', 'Survey') then 4*count(DISTINCT f_tpv.F_TPV_KEY)
	 WHEN tpv_product.Product_Type = 'In Person Event' then 1.5*count(DISTINCT f_tpv.F_TPV_KEY)
	 WHEN tpv_product.Product_Type = 'Visit' then 2*count(DISTINCT f_tpv.F_TPV_KEY)
	 WHEN tpv_product.PRODUCT_NAME in ('Transcript','Webcast Replay') then 0
     WHEN tpv_product.Product_Type = 'Virtual Event' then 0.33*count(DISTINCT f_tpv.F_TPV_KEY) else 0 end as										 wTPV
FROM WARS.bi.F_PROJECT  AS f_project
LEFT JOIN WARS.bi.F_TPV  AS f_tpv ON f_project.F_PROJECT_KEY = f_tpv.F_PROJECT_KEY
INNER JOIN WARS.bi.D_DATE  AS d_date ON d_date.DATE_KEY = f_tpv.TPV_DATE_KEY
INNER JOIN WARS.bi.d_user ON d_user.D_USER_KEY = f_tpv.D_USER_KEY
LEFT JOIN WARS.bi.d_emp AS d_emp_tpv_owner ON (COALESCE(f_project.DELEGATE_RM_D_EMP_KEY,f_project.PRIMARY_RM_D_EMP_KEY)) = d_emp_tpv_owner.D_EMP_KEY
LEFT JOIN WARS.bi.D_PRODUCT  AS tpv_product ON f_tpv.D_PRODUCT_KEY = tpv_product.D_PRODUCT_KEY
LEFT JOIN WARS.bi.d_emp AS d_user_research_owner ON d_user_research_owner.D_EMP_KEY = d_user.USER_RESEARCH_OWNER_D_EMP_KEY
left join WARS.BI.D_CLIENT dc on dc.D_CLIENT_KEY = f_tpv.D_CLIENT_KEY
WHERE (d_date.DATE  IS NOT NULL) AND (d_user.PL_NAME = 'Greater China') AND ((d_emp_tpv_owner.BU IS NOT NULL))  AND ((tpv_product.PRODUCT_NAME  NOT IN ('Webcast Replay', 'Transcript') OR tpv_product.PRODUCT_NAME IS NULL)) AND (d_user_research_owner.BU = 'Greater China')
GROUP BY d_user_research_owner.POD ,dc.client_id,f_project.PROJECT_ID ,CONVERT(VARCHAR(7),d_date.DATE ,120),f_project.TITLE ,d_emp_tpv_owner.EMPLOYEENAME ,d_emp_tpv_owner.TEAM,    tpv_product.product_name
	,tpv_product.product_type
ORDER BY 7 DESC