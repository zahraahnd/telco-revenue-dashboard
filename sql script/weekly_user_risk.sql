--CREATE VIEW p2_telco_dashboard.weekly_user_risk_wow AS

WITH
tab1 AS (
	SELECT msisdn, week, revenue,
	LAG(week, 1) OVER (PARTITION BY msisdn ORDER BY week ASC) as week_prev,
	LAG(revenue, 1) OVER (PARTITION BY msisdn ORDER BY week ASC) as rev_prev,
	(week - LAG(week, 1) OVER (PARTITION BY msisdn ORDER BY week ASC))-1 as blank_week,
	MAX(week) OVER (PARTITION BY msisdn) as latest_week,
	35 - MAX(week) OVER (PARTITION BY msisdn) as diff_latest_week
	FROM p2_telco_dashboard.revenue_cleaned
	ORDER BY msisdn, week
), 

at_risk_tab as (
	SELECT
	tab1.msisdn,
	tab1.week_prev + tab2.tenure_blank as week,
	tab2.tenure_blank,
	tab1.blank_week as total_tenure_blank,
	tab1.week_prev as week_latest_rev,
	tab1.rev_prev as latest_rev,
	'At-Risk' as remark
	FROM tab1
	LEFT JOIN (
			SELECT DISTINCT msisdn,
			generate_series(4, 7, 1) as tenure_blank
			from tab1
		) as tab2
		ON 	tab2.msisdn = tab1.msisdn
			AND tab2.tenure_blank BETWEEN 4 AND tab1.blank_week
	WHERE tab1.blank_week BETWEEN 4 AND 7
	ORDER BY tab1.msisdn, tab1.week, tab2.tenure_blank
),

at_risk_latest_tab as (
	SELECT
	tab1.msisdn,
	tab1.latest_week + tab2.tenure_blank as week,
	tab2.tenure_blank,
	tab1.diff_latest_week as total_tenure_blank,
	tab1.latest_week as week_latest_rev,
	tab1.revenue as latest_rev,
	'At-Risk' as remark
	FROM tab1
	LEFT JOIN (
		SELECT DISTINCT msisdn,
		generate_series(4, 7, 1) as tenure_blank
		from tab1
		) as tab2
			ON 	tab2.msisdn = tab1.msisdn
			AND tab2.tenure_blank BETWEEN 4 AND tab1.diff_latest_week
	WHERE tab1.week = tab1.latest_week AND tab1.diff_latest_week >= 4 AND tab1.diff_latest_week <= 7
	ORDER BY tab1.msisdn, tab1.week, tab2.tenure_blank
),

churned_tab as (
	SELECT
	tab1.msisdn,
	tab1.week_prev + tab2.tenure_blank as week,
	tab2.tenure_blank,
	tab1.blank_week as total_tenure_blank,
	tab1.week_prev as week_latest_rev,
	tab1.rev_prev as latest_rev,
	'Churned' as remark
	FROM tab1
	LEFT JOIN (
			SELECT DISTINCT msisdn,
			generate_series(8, (SELECT max(blank_week) FROM tab1), 1) as tenure_blank
			from tab1
		) as tab2
		ON 	tab2.msisdn = tab1.msisdn
			AND tab2.tenure_blank BETWEEN 8 AND tab1.blank_week
	WHERE blank_week >= 8
	ORDER BY tab1.msisdn, tab1.week, tab2.tenure_blank
),

churned_latest_tab as (
	SELECT
	tab1.msisdn,
	tab1.latest_week + tab2.tenure_blank as week,
	tab2.tenure_blank,
	tab1.diff_latest_week as total_tenure_blank,
	tab1.latest_week as week_latest_rev,
	tab1.revenue as latest_rev,
	'Churned' as remark
	FROM tab1
	LEFT JOIN (
		SELECT DISTINCT msisdn,
		generate_series(8, (SELECT max(diff_latest_week) FROM tab1), 1) as tenure_blank
		from tab1
		) as tab2
			ON 	tab2.msisdn = tab1.msisdn
			AND tab2.tenure_blank BETWEEN 8 AND tab1.diff_latest_week
	WHERE tab1.week = tab1.latest_week AND tab1.diff_latest_week >= 8
	ORDER BY tab1.msisdn, tab1.week, tab2.tenure_blank
),

user_risk_table AS (
	SELECT joined.*,
	ROUND(joined.total_msisdn*100.00 / base.total_msisdn, 2) as msisdn_percent_of_base,
	ROUND(joined.revenue_latest*100.00 / base.total_revenue, 2) as revenue_percent_of_base
	FROM (
		--SELECT week, remark,
		SELECT week, remark, tenure_blank,
		COUNT(DISTINCT msisdn) as total_msisdn,
		ROUND(AVG(tenure_blank), 2) as avg_tenure_blank,
		SUM(latest_rev) as revenue_latest
		FROM (
			SELECT * FROM at_risk_tab
			UNION ALL
			SELECT * FROM at_risk_latest_tab
		) as at_risk
		--GROUP BY week, remark
		GROUP BY week, remark, tenure_blank
		
		UNION ALL
		
		--SELECT week, remark,
		SELECT week, remark, tenure_blank,
		COUNT(DISTINCT msisdn) as total_msisdn,
		ROUND(AVG(tenure_blank), 2) as avg_tenure_blank,
		SUM(latest_rev) as revenue_latest
		FROM (
			SELECT * FROM churned_tab
			UNION ALL
			SELECT * FROM churned_latest_tab
		) as churned
		--GROUP BY week, remark
		GROUP BY week, remark, tenure_blank
		
		ORDER BY remark, week
	) as joined
	LEFT JOIN p2_telco_dashboard.weekly_revenue as base
	 ON base.week = joined.week - 1
)

SELECT * FROM user_risk_table