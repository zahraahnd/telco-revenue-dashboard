--CREATE VIEW p2_telco_dashboard.weekly_revenue AS

WITH weekly AS (
	SELECT
	year,
	EXTRACT('month' FROM start_date) as month,
	week,
	week - (EXTRACT(WEEK FROM DATE_TRUNC('month', start_date))) as week_in_month,
	start_date,
	end_date,
	COUNT(msisdn) as total_msisdn,
	SUM(revenue) as total_revenue,
	ROUND(SUM(revenue)/COUNT(msisdn), 2) as arpu
	FROM p2_telco_dashboard.revenue_cleaned
	GROUP BY year, week, start_date, end_date
	ORDER BY week ASC
),

weekly_added AS (
SELECT *,
LAG(total_msisdn, 1) OVER (ORDER BY week ASC) AS total_msisdn_prev,
LAG(total_msisdn, 1) OVER (PARTITION BY week_in_month ORDER BY week_in_month ASC, month ASC) as total_msisdn_prev_month,
LAG(total_revenue, 1) OVER (ORDER BY week ASC) AS total_revenue_prev,
LAG(total_revenue, 1) OVER (PARTITION BY week_in_month ORDER BY week_in_month ASC, month ASC) as total_revenue_prev_month,
LAG(arpu, 1) OVER (ORDER BY week ASC) AS arpu_prev,
LAG(arpu, 1) OVER (PARTITION BY week_in_month ORDER BY week_in_month ASC, month ASC) as arpu_prev_month
FROM weekly
)

SELECT
year,
month,
week,
week_in_month,
start_date,
end_date,
total_msisdn,
total_revenue,
arpu,
COALESCE(ROUND(((total_msisdn - total_msisdn_prev)*100.00/total_msisdn_prev),2), NULL) AS delta_msisdn_prev,
COALESCE(ROUND(((total_msisdn - total_msisdn_prev_month)*100.00/total_msisdn_prev_month),2), NULL) AS delta_msisdn_prev_month,
COALESCE(ROUND(((total_revenue - total_revenue_prev)*100.00/total_revenue_prev),2), NULL) AS delta_revenue_prev,
COALESCE(ROUND(((total_revenue - total_revenue_prev_month)*100.00/total_revenue_prev_month),2), NULL) AS delta_revenue_prev_month,
COALESCE(ROUND(((arpu - arpu_prev)*100.00/arpu_prev),2), NULL) AS delta_arpu_prev,
COALESCE(ROUND(((arpu - arpu_prev_month)*100.00/arpu_prev_month),2), NULL) AS delta_arpu_prev_month
FROM weekly_added
ORDER BY week