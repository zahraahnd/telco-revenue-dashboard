--CREATE VIEW p2_telco_dashboard.weekly_user_movement_wow AS

WITH
retained_user_level AS (
	SELECT
	tab_current.msisdn,
	tab_current.week,
	tab_current.revenue,
	'Retained' as remark
	FROM p2_telco_dashboard.revenue_cleaned as tab_current
	LEFT JOIN p2_telco_dashboard.revenue_cleaned as tab_prev
		ON tab_prev.msisdn = tab_current.msisdn
		AND tab_prev.week = tab_current.week - 1
	WHERE tab_prev.msisdn IS NOT NULL
	ORDER BY tab_current.msisdn, tab_current.week
),

new_user_level as (
	SELECT
	tab_current.msisdn,
	tab_current.week,
	AVG(tab_current.revenue) as revenue,
	'New' as Remark
	FROM p2_telco_dashboard.revenue_cleaned as tab_current
	LEFT JOIN p2_telco_dashboard.revenue_cleaned as tab_prev
		ON tab_prev.msisdn = tab_current.msisdn
		AND tab_prev.week BETWEEN 22 AND tab_current.week - 1
	GROUP BY tab_current.msisdn, tab_current.week
	HAVING COUNT(tab_prev.msisdn) = 0 AND tab_current.week > 22
	ORDER BY tab_current.week
),

reactivated_user_level as (
	SELECT
	tab_current.msisdn, 
	tab_current.week,
	COUNT(tab_lastw.msisdn) as exist_lastw,
	COUNT(tab_prev.msisdn) as exist_before_lastw,
	AVG(tab_current.revenue) as revenue,
	'Reactivated' as remark
	FROM p2_telco_dashboard.revenue_cleaned as tab_current
	LEFT JOIN p2_telco_dashboard.revenue_cleaned as tab_lastw
		ON tab_lastw.msisdn = tab_current.msisdn
		AND tab_lastw.week = tab_current.week - 1
	LEFT JOIN p2_telco_dashboard.revenue_cleaned as tab_prev
		ON tab_prev.msisdn = tab_current.msisdn
		AND tab_prev.week BETWEEN 22 AND tab_current.week - 2
	WHERE tab_current.week > 23 AND tab_lastw.msisdn IS NULL
	GROUP BY tab_current.msisdn, tab_current.week
	HAVING COUNT(tab_prev.msisdn) > 0
	ORDER BY tab_current.week, tab_current.week
),

dropped_user_level as (
	SELECT
	tab_lastw.msisdn,
	tab_lastw.week + 1 as week, --week user dropped
	tab_lastw.revenue,
	'Dropped' as remark
	FROM p2_telco_dashboard.revenue_cleaned as tab_lastw
	LEFT JOIN p2_telco_dashboard.revenue_cleaned as tab_current
		ON tab_current.msisdn = tab_lastw.msisdn
		AND tab_current.week = tab_lastw.week + 1
	WHERE tab_current.msisdn IS NULL
	ORDER BY tab_lastw.week + 1, tab_lastw.msisdn
),

week_level AS (
	SELECT 
	main_tab.*,
	retained_tab.msisdn_retained,
	retained_tab.revenue_retained,
	new_tab.msisdn_new,
	new_tab.revenue_new,
	reactived_tab.msisdn_reactivated,
	reactived_tab.revenue_reactivated,
	dropped_tab.msisdn_dropped,
	dropped_tab.revenue_dropped
	FROM (
		SELECT
		year, month, week,
		COUNT(DISTINCT msisdn) as msisdn_current,
		SUM(revenue) as revenue_current
		FROM p2_telco_dashboard.revenue_cleaned
		GROUP BY year, month, week
	) as main_tab
	LEFT JOIN (
		SELECT week,
		COUNT(DISTINCT msisdn) as msisdn_retained,
		SUM(revenue) as revenue_retained
		FROM retained_user_level
		GROUP BY week
	) as retained_tab ON main_tab.week = retained_tab.week
	LEFT JOIN (
		SELECT week,
		COUNT(DISTINCT msisdn) as msisdn_new,
		SUM(revenue) as revenue_new
		FROM new_user_level
		GROUP BY week
	) as new_tab ON main_tab.week = new_tab.week
	LEFT JOIN (
		SELECT week, 
		COUNT(DISTINCT msisdn) as msisdn_reactivated,
		SUM(revenue) as revenue_reactivated
		FROM reactivated_user_level
		GROUP BY week
	) as reactived_tab ON main_tab.week = reactived_tab.week
	LEFT JOIN (
		SELECT week, 
		COUNT(DISTINCT msisdn) as msisdn_dropped,
		SUM(revenue) as revenue_dropped
		FROM dropped_user_level
		GROUP BY week
	) as dropped_tab ON main_tab.week = dropped_tab.week
),

week_remak_level AS (
	SELECT tab.*,
	CASE
		WHEN remark != 'Dropped' THEN
			tab.total_msisdn*100.00 / tab_current.msisdn_current
		WHEN remark = 'Dropped' THEN
			tab.total_msisdn*100.00 / LAG(tab_current.msisdn_current, 1) OVER (PARTITION BY tab.remark ORDER BY tab.week)
		ELSE NULL
		END as msisdn_rate,
	CASE
		WHEN remark != 'Dropped' THEN
			tab.total_revenue*100.00 / tab_current.revenue_current
		WHEN remark = 'Dropped' THEN
			tab.total_revenue*100.00 / LAG(tab_current.revenue_current, 1) OVER (PARTITION BY tab.remark ORDER BY tab.week)
		ELSE NULL
		END as revenue_rate
	FROM (
		SELECT week, remark,
		COUNT(DISTINCT msisdn) as total_msisdn,
		SUM(revenue) as total_revenue
		FROM retained_user_level
		GROUP BY week, remark
		
		UNION ALL
		
		SELECT week, remark,
		COUNT(DISTINCT msisdn) as total_msisdn,
		SUM(revenue) as total_revenue
		FROM new_user_level
		GROUP BY week, remark
	
		UNION ALL
		
		SELECT week, remark,
		COUNT(DISTINCT msisdn) as total_msisdn,
		SUM(revenue) as total_revenue
		FROM reactivated_user_level
		GROUP BY week, remark
	
		UNION ALL
		
		SELECT week, remark,
		COUNT(DISTINCT msisdn) as total_msisdn,
		SUM(revenue) as total_revenue
		FROM dropped_user_level
		GROUP BY week, remark
	) as tab
	LEFT JOIN (
	    SELECT
		week,
		COUNT(DISTINCT msisdn) as msisdn_current,
		SUM(revenue) as revenue_current
		FROM p2_telco_dashboard.revenue_cleaned
		GROUP BY week
	) as tab_current
	ON tab_current.week = tab.week
)

SELECT * FROM week_remak_level