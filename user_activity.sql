SELECT distinct
  date.YEAR_NUMBER as ACTIVITY_YEAR_NUMBER,
  date.MONTH_NUMBER as ACTIVITY_MONTH_NUMBER,
  date.WORK_DAYS_IN_MONTH as ACTIVITY_WORK_DAYS_IN_MONTH,
  date.WEEK_NUMBER as ACTIVITY_WEEK_NUMBER,
  DATEPART(HOUR, act.CREATED_DATE) as ACTIVITY_HOUR_NUMBER,
  date.IS_WORK_DAY  as ACTIVITY_IS_WORK_DAY,
  CONVERT(varchar, act.CREATED_DATE, 100) as CREATED_DATE,
  u.PL_NAME,
  u.PL_REGION,
  CASE WHEN u.PL_NAME like '%Americas%' then 'Americas'
	 WHEN u.PL_NAME like '%EMEA%' then 'EMEA'
	 WHEN u.PL_NAME like '%Greater China%' then 'Greater China'
	 WHEN u.PL_NAME like '%Southeast Asia%' then 'APAC ex-China'
	 WHEN u.PL_NAME like '%Japan%' then 'APAC ex-China'
	 WHEN u.PL_NAME like '%South Korea%' then 'APAC ex-China'
	 WHEN u.PL_NAME like '%India%' then 'APAC ex-China'
     WHEN u.PL_NAME like '%Australia%' then 'APAC ex-China' else 'Other' end as										 PL_NAME2,
  act.CREATED_BY,
  act.SOURCE_APPLICATION,
  act_status.PROJECT_ACTIVITY_STATUS_ID,
  act_status.PROJECT_ACTIVITY_STATUS,
  project_date.YEAR_NUMBER as PROJECT_YEAR_NUMBER,
  project_date.MONTH_NUMBER as PROJET_MONTH_NUMBER,
  project_date.WORK_DAYS_IN_MONTH as PROJECT_WORK_DAYS_IN_MONTH,
  project_date.WEEK_NUMBER as PROJECT_WEEK_NUMBER,
  DATEPART(HOUR, p.CREATE_DATE) as PROJECT_HOUR_NUMBER,
  project_date.IS_WORK_DAY as PROJECT_IS_WORK_DAY,
  CONVERT(varchar, p.CREATE_DATE, 100) as CREATE_DATE


FROM wars.bi.F_PROJECT p
JOIN wars.bi.D_PRODUCT pdt
    ON pdt.d_product_key = p.d_product_key
JOIN wars.bi.F_PROJECT_MEETING_ACTIVITY act
    ON p.project_id = act.project_id 
JOIN wars.bi.D_PROJECT_ACTIVITY_STATUS act_status 
    ON act.D_PROJECT_ACTIVITY_STATUS_KEY = act_status.D_PROJECT_ACTIVITY_STATUS_KEY
JOIN wars.bi.D_DATE [date]
    ON act.CREATED_DATE_KEY = date.DATE_KEY
JOIN wars.bi.D_DATE project_date
    ON p.CREATE_DATE_KEY = project_date.DATE_KEY
LEFT join wars.bi.B_PROJECT_USER bpu on p.F_PROJECT_KEY = bpu.F_PROJECT_KEY
LEFT join wars.bi.D_USER u on bpu.D_USER_KEY = u.D_USER_KEY 
LEFT join wars.bi.D_CLIENT c on bpu.D_CLIENT_KEY =  c.D_CLIENT_KEY
LEFT join wars.bi.D_CLIENT_TYPE client_type ON client_type.D_CLIENT_TYPE_KEY = c.D_CLIENT_TYPE_KEY

where
  pdt.PRODUCT_NAME = 'Phone Consultation'
  and date.year_number >= 2020
  and date.month_number=9
  and act_status.PROJECT_ACTIVITY_STATUS in ('Accepted', 'Invite Queued', 'Invited', 'Highlights Added', 'Given to Client', 'Accept Started', 'Scheduled')
  and u.PL_Segment = 'Private'
  and (CASE WHEN u.PL_NAME like '%Americas%' then 'Americas'
	 WHEN u.PL_NAME like '%EMEA%' then 'EMEA'
	 WHEN u.PL_NAME like '%Greater China%' then 'Greater China'
	 WHEN u.PL_NAME like '%Southeast Asia%' then 'APAC ex-China'
	 WHEN u.PL_NAME like '%Japan%' then 'APAC ex-China'
	 WHEN u.PL_NAME like '%South Korea%' then 'APAC ex-China'
	 WHEN u.PL_NAME like '%India%' then 'APAC ex-China'
     WHEN u.PL_NAME like '%Australia%' then 'APAC ex-China' else 'Other' end) not like 'Other'