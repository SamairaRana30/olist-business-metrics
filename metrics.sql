-- Business metrics on Olist: the 10 metrics from the "top 10 metrics every data analyst should know" video.
-- Habit for every query: the plan in English first (the "plan:" line), then check row counts and totals.
-- Full months only: Olist is sparse before 2017-01 and incomplete after 2018-08, so trend queries use 2017-01 to 2018-08.
-- Run with: python run_metrics.py   (each "name:" block becomes a CSV in outputs/)

-- name: q01_revenue_by_month
-- family: money coming in | metric 1: Revenue
-- plan: revenue = item price of delivered orders, per purchase month. Freight is not revenue. CHECK: months = 20; sum of months = total delivered item price.
WITH monthly AS (
  SELECT strftime('%Y-%m', o.order_purchase_timestamp) AS month,
         ROUND(SUM(i.price), 2) AS revenue,
         COUNT(DISTINCT o.order_id) AS orders
  FROM orders o JOIN order_items i ON i.order_id = o.order_id
  WHERE o.order_status = 'delivered'
  GROUP BY month
)
SELECT month, revenue, orders,
       ROUND(100.0 * (revenue - LAG(revenue) OVER (ORDER BY month)) / LAG(revenue) OVER (ORDER BY month), 1) AS mom_growth_pct
FROM monthly
WHERE month BETWEEN '2017-01' AND '2018-08'
ORDER BY month;

-- name: q02_aov_and_growth_drivers
-- family: money coming in | metric 2: AOV (average order value)
-- plan: revenue = orders x AOV. For each month in 2018 compare with the same month of 2017: did revenue grow because of more orders, or bigger baskets? CHECK: (1+orders_yoy)*(1+aov_yoy) is about (1+revenue_yoy).
WITH m AS (
  SELECT strftime('%Y-%m', o.order_purchase_timestamp) AS month,
         SUM(i.price) AS revenue,
         COUNT(DISTINCT o.order_id) AS orders
  FROM orders o JOIN order_items i ON i.order_id = o.order_id
  WHERE o.order_status = 'delivered'
  GROUP BY month
)
SELECT cur.month,
       ROUND(cur.revenue, 0) AS revenue,
       cur.orders,
       ROUND(cur.revenue / cur.orders, 2) AS aov,
       ROUND(100.0 * (cur.revenue / prev.revenue - 1), 1) AS revenue_yoy_pct,
       ROUND(100.0 * (cur.orders * 1.0 / prev.orders - 1), 1) AS orders_yoy_pct,
       ROUND(100.0 * ((cur.revenue / cur.orders) / (prev.revenue / prev.orders) - 1), 1) AS aov_yoy_pct
FROM m cur JOIN m prev ON prev.month = strftime('%Y-%m', date(cur.month || '-01', '-1 year'))
WHERE cur.month BETWEEN '2018-01' AND '2018-08'
ORDER BY cur.month;

-- name: q02b_category_mix
-- family: money coming in | metric 2: AOV (product mix, the "Apple AirPods vs MacBook" idea)
-- plan: top 10 categories by revenue with units, average item price and share of total. Cheap categories growing = weaker mix. CHECK: shares of all categories sum to 100.
WITH cat AS (
  SELECT COALESCE(t.product_category_name_english, p.product_category_name, 'unknown') AS category,
         SUM(i.price) AS revenue, COUNT(*) AS units, AVG(i.price) AS avg_item_price
  FROM orders o
  JOIN order_items i ON i.order_id = o.order_id
  LEFT JOIN products p ON p.product_id = i.product_id
  LEFT JOIN category_translation t ON t.product_category_name = p.product_category_name
  WHERE o.order_status = 'delivered'
  GROUP BY category
)
SELECT category, ROUND(revenue, 0) AS revenue, units, ROUND(avg_item_price, 2) AS avg_item_price,
       ROUND(100.0 * revenue / (SELECT SUM(revenue) FROM cat), 1) AS share_pct
FROM cat ORDER BY revenue DESC LIMIT 10;

-- name: q03_freight_share_margin_proxy
-- family: money going out | metric 3: Gross margin (NOT in the data: Olist has no cost or commission figures)
-- plan: the closest thing we have is how much of what the customer pays goes to delivery. freight share = freight / (price + freight), per month. This is a PROXY for cost pressure, not a margin.
SELECT strftime('%Y-%m', o.order_purchase_timestamp) AS month,
       ROUND(SUM(i.price), 0) AS item_revenue,
       ROUND(SUM(i.freight_value), 0) AS freight,
       ROUND(100.0 * SUM(i.freight_value) / (SUM(i.price) + SUM(i.freight_value)), 1) AS freight_share_pct
FROM orders o JOIN order_items i ON i.order_id = o.order_id
WHERE o.order_status = 'delivered'
GROUP BY month
HAVING month BETWEEN '2017-01' AND '2018-08'
ORDER BY month;

-- name: q04_ltv_cac_margin_scenarios
-- family: money going out | metrics 3 and 4: Gross margin and CAC (SCENARIOS: the numbers marked assumed_ are made up, not data)
-- plan: Olist has no cost or spend data, so practise the interview logic instead. Take the real average LTV (payments) and test a grid of ASSUMED CAC values and ASSUMED gross margins. LTV:CAC should use margin, not revenue: a customer worth 100 in revenue at 20% margin is only worth 20 to the business. CHECK: ltv_to_cac_margin = avg_ltv * margin / cac.
WITH order_val AS (
  SELECT order_id, SUM(payment_value) AS v FROM order_payments GROUP BY order_id
), cust AS (
  SELECT c.customer_unique_id, SUM(ov.v) AS ltv
  FROM orders o
  JOIN customers c ON c.customer_id = o.customer_id
  JOIN order_val ov ON ov.order_id = o.order_id
  WHERE o.order_status = 'delivered'
  GROUP BY c.customer_unique_id
), a AS (SELECT AVG(ltv) AS avg_ltv FROM cust),
cac(assumed_cac) AS (VALUES (20), (40), (60), (80), (100)),
gm(assumed_gross_margin) AS (VALUES (0.10), (0.20), (0.30))
SELECT cac.assumed_cac, gm.assumed_gross_margin,
       ROUND(a.avg_ltv, 2) AS avg_ltv_real,
       ROUND(a.avg_ltv / cac.assumed_cac, 2) AS ltv_to_cac_on_revenue,
       ROUND(a.avg_ltv * gm.assumed_gross_margin / cac.assumed_cac, 2) AS ltv_to_cac_on_margin,
       CASE WHEN a.avg_ltv * gm.assumed_gross_margin / cac.assumed_cac >= 3 THEN 'healthy (3:1 or better)' ELSE 'below 3:1' END AS verdict
FROM a, cac, gm
ORDER BY gm.assumed_gross_margin, cac.assumed_cac;

-- name: q05_ltv
-- family: customer behavior | metric 5: Lifetime value (also gives the CAC ceiling, metric 4)
-- plan: one row per real customer (customer_unique_id, NOT customer_id). LTV so far = total payments of their delivered orders. CAC is not in the data, so we report the MAXIMUM affordable CAC at a healthy 3:1 LTV:CAC ratio. CHECK: customers = distinct customer_unique_id with a delivered order.
WITH order_val AS (
  SELECT order_id, SUM(payment_value) AS v FROM order_payments GROUP BY order_id
), cust AS (
  SELECT c.customer_unique_id, COUNT(DISTINCT o.order_id) AS n_orders, SUM(ov.v) AS ltv
  FROM orders o
  JOIN customers c ON c.customer_id = o.customer_id
  JOIN order_val ov ON ov.order_id = o.order_id
  WHERE o.order_status = 'delivered'
  GROUP BY c.customer_unique_id
)
SELECT COUNT(*) AS customers,
       ROUND(AVG(ltv), 2) AS avg_ltv,
       ROUND(AVG(CASE WHEN n_orders = 1 THEN ltv END), 2) AS avg_ltv_one_time,
       ROUND(AVG(CASE WHEN n_orders >= 2 THEN ltv END), 2) AS avg_ltv_repeat,
       ROUND(100.0 * SUM(n_orders >= 2) / COUNT(*), 2) AS repeat_customers_pct,
       ROUND(AVG(ltv) / 3, 2) AS max_affordable_cac_at_3x
FROM cust;

-- name: q06_customers_new_vs_returning
-- family: customer behavior | metric 6: Number of customers (new vs returning, like newly acquired vs churned)
-- plan: count active customers per month and split them into new (first ever order that month) and returning. Definition: a customer = customer_unique_id with a delivered order. CHECK: new + returning = active.
WITH o AS (
  SELECT c.customer_unique_id AS u, strftime('%Y-%m', o.order_purchase_timestamp) AS m
  FROM orders o JOIN customers c ON c.customer_id = o.customer_id
  WHERE o.order_status = 'delivered'
), f AS (
  SELECT u, MIN(m) AS first_month FROM o GROUP BY u
)
SELECT o.m AS month,
       COUNT(DISTINCT o.u) AS active_customers,
       COUNT(DISTINCT CASE WHEN o.m = f.first_month THEN o.u END) AS new_customers,
       COUNT(DISTINCT CASE WHEN o.m > f.first_month THEN o.u END) AS returning_customers
FROM o JOIN f ON f.u = o.u
WHERE o.m BETWEEN '2017-01' AND '2018-08'
GROUP BY o.m ORDER BY o.m;

-- name: q06b_definition_check
-- family: customer behavior | metric 6: why the definition matters
-- plan: the same table gives two different customer counts depending on the ID you pick. Show both.
SELECT COUNT(DISTINCT customer_id) AS customer_id_count,
       COUNT(DISTINCT customer_unique_id) AS real_people_count
FROM customers;

-- name: q07_nps_proxy_by_delivery
-- family: customer behavior | metric 7: NPS (proxy from the 1-5 review score)
-- plan: Olist has no 0-10 recommend question. Proxy: promoters = 5 stars, detractors = 1-3 stars, NPS = %promoters - %detractors. Split by late vs on-time delivery (estimated date vs actual). CHECK: n adds up to delivered orders with a review and a delivery date.
WITH r AS (
  SELECT rv.review_score AS s,
         CASE WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date THEN 'late' ELSE 'on_time' END AS delivery
  FROM orders o JOIN order_reviews rv ON rv.order_id = o.order_id
  WHERE o.order_status = 'delivered' AND o.order_delivered_customer_date IS NOT NULL
)
SELECT delivery, COUNT(*) AS reviews, ROUND(AVG(s), 2) AS avg_score,
       ROUND(100.0 * SUM(s = 5) / COUNT(*) - 100.0 * SUM(s <= 3) / COUNT(*), 1) AS nps_proxy
FROM r GROUP BY delivery
UNION ALL
SELECT 'all', COUNT(*), ROUND(AVG(s), 2),
       ROUND(100.0 * SUM(s = 5) / COUNT(*) - 100.0 * SUM(s <= 3) / COUNT(*), 1)
FROM r;

-- name: q07b_nps_proxy_by_state
-- family: customer behavior | metric 7: NPS sliced by a customer dimension (region)
-- plan: same NPS proxy per customer state, only states with at least 300 reviews so small samples don't mislead.
SELECT c.customer_state AS state, COUNT(*) AS reviews, ROUND(AVG(rv.review_score), 2) AS avg_score,
       ROUND(100.0 * SUM(rv.review_score = 5) / COUNT(*) - 100.0 * SUM(rv.review_score <= 3) / COUNT(*), 1) AS nps_proxy
FROM orders o
JOIN order_reviews rv ON rv.order_id = o.order_id
JOIN customers c ON c.customer_id = o.customer_id
WHERE o.order_status = 'delivered'
GROUP BY c.customer_state
HAVING COUNT(*) >= 300
ORDER BY nps_proxy DESC;

-- name: q08_order_funnel
-- family: funnel health | metric 8: Conversion rate (order funnel)
-- plan: follow every order from placed to approved, handed to carrier, delivered, reviewed. Each step as % of orders placed. CHECK: steps never increase from left to right (except reviewed vs delivered, which can differ).
SELECT COUNT(*) AS placed,
       SUM(o.order_approved_at IS NOT NULL) AS approved,
       SUM(o.order_delivered_carrier_date IS NOT NULL) AS shipped,
       SUM(o.order_delivered_customer_date IS NOT NULL) AS delivered,
       SUM(EXISTS (SELECT 1 FROM order_reviews rv WHERE rv.order_id = o.order_id)) AS reviewed,
       SUM(o.order_status IN ('canceled', 'unavailable')) AS canceled_or_unavailable,
       ROUND(100.0 * SUM(o.order_approved_at IS NOT NULL) / COUNT(*), 1) AS approved_pct,
       ROUND(100.0 * SUM(o.order_delivered_carrier_date IS NOT NULL) / COUNT(*), 1) AS shipped_pct,
       ROUND(100.0 * SUM(o.order_delivered_customer_date IS NOT NULL) / COUNT(*), 1) AS delivered_pct
FROM orders o;

-- name: q08b_marketing_funnel_by_origin
-- family: funnel health | metric 8: Conversion rate (seller-acquisition funnel; needs the optional "Marketing Funnel by Olist" files)
-- plan: of the marketing qualified leads (MQLs) per origin channel, what % became a closed deal? CHECK: closed deals total = rows in closed_deals.
SELECT COALESCE(m.origin, 'unknown') AS origin, COUNT(*) AS mqls,
       SUM(d.mql_id IS NOT NULL) AS closed_deals,
       ROUND(100.0 * SUM(d.mql_id IS NOT NULL) / COUNT(*), 1) AS conversion_pct
FROM mqls m LEFT JOIN closed_deals d ON d.mql_id = m.mql_id
GROUP BY origin ORDER BY mqls DESC;

-- name: q09_repeat_rate_by_year
-- family: funnel health | metrics 9 and 10: Retention and churn (headline)
-- plan: per customer_unique_id, did they ever order twice? Group by the year of their FIRST order. Retention proxy = % who ordered again, churn proxy = 100 - that. CHECK: one_time + repeat = customers.
WITH o AS (
  SELECT c.customer_unique_id AS u, o.order_id, o.order_purchase_timestamp AS ts
  FROM orders o JOIN customers c ON c.customer_id = o.customer_id
  WHERE o.order_status = 'delivered'
), per AS (
  SELECT u, COUNT(DISTINCT order_id) AS n, strftime('%Y', MIN(ts)) AS first_year FROM o GROUP BY u
)
SELECT first_year, COUNT(*) AS customers, SUM(n = 1) AS one_time, SUM(n >= 2) AS repeat,
       ROUND(100.0 * SUM(n >= 2) / COUNT(*), 2) AS retention_pct,
       ROUND(100.0 * SUM(n = 1) / COUNT(*), 2) AS churn_pct
FROM per GROUP BY first_year ORDER BY first_year;

-- name: q10_cohort_retention
-- family: funnel health | metrics 9 and 10: Retention by monthly cohort
-- plan: cohort = month of first order. For each cohort, % of customers who ordered again 1, 3 and 6 months later. Only cohorts old enough to have a full 6 months (first order up to 2018-02).
WITH o AS (
  SELECT c.customer_unique_id AS u, strftime('%Y-%m', o.order_purchase_timestamp) AS m
  FROM orders o JOIN customers c ON c.customer_id = o.customer_id
  WHERE o.order_status = 'delivered'
), f AS (
  SELECT u, MIN(m) AS cohort FROM o GROUP BY u
), x AS (
  SELECT f.cohort, o.u,
         (CAST(substr(o.m, 1, 4) AS INT) * 12 + CAST(substr(o.m, 6, 2) AS INT))
       - (CAST(substr(f.cohort, 1, 4) AS INT) * 12 + CAST(substr(f.cohort, 6, 2) AS INT)) AS off
  FROM o JOIN f ON f.u = o.u
)
SELECT cohort,
       COUNT(DISTINCT CASE WHEN off = 0 THEN u END) AS cohort_size,
       ROUND(100.0 * COUNT(DISTINCT CASE WHEN off = 1 THEN u END) / COUNT(DISTINCT CASE WHEN off = 0 THEN u END), 2) AS m1_pct,
       ROUND(100.0 * COUNT(DISTINCT CASE WHEN off = 3 THEN u END) / COUNT(DISTINCT CASE WHEN off = 0 THEN u END), 2) AS m3_pct,
       ROUND(100.0 * COUNT(DISTINCT CASE WHEN off = 6 THEN u END) / COUNT(DISTINCT CASE WHEN off = 0 THEN u END), 2) AS m6_pct
FROM x
WHERE cohort BETWEEN '2017-01' AND '2018-02'
GROUP BY cohort ORDER BY cohort;

-- name: q11_daily_revenue_nov_2017
-- family: money coming in | metric 1: Revenue (checking the Nov 2017 spike)
-- plan: revenue per purchase day in Nov 2017, biggest days first. If one or two days dwarf the rest, the spike is an event. Black Friday 2017 was Fri 24 Nov. CHECK: sum of all days = Nov 2017 revenue in q01.
SELECT date(o.order_purchase_timestamp) AS day,
       ROUND(SUM(i.price), 0) AS revenue,
       COUNT(DISTINCT o.order_id) AS orders
FROM orders o JOIN order_items i ON i.order_id = o.order_id
WHERE o.order_status = 'delivered' AND strftime('%Y-%m', o.order_purchase_timestamp) = '2017-11'
GROUP BY day ORDER BY revenue DESC;

-- name: q12_late_rate_by_state
-- family: customer behavior | metric 7: NPS (where lateness hurts most)
-- plan: share of delivered orders that arrived after the estimated date, per customer state, with the average review score. States with at least 300 delivered orders. CHECK: late_pct between 0 and 100.
SELECT c.customer_state AS state,
       COUNT(*) AS delivered_orders,
       ROUND(100.0 * SUM(o.order_delivered_customer_date > o.order_estimated_delivery_date) / COUNT(*), 1) AS late_pct
FROM orders o JOIN customers c ON c.customer_id = o.customer_id
WHERE o.order_status = 'delivered' AND o.order_delivered_customer_date IS NOT NULL
GROUP BY c.customer_state
HAVING COUNT(*) >= 300
ORDER BY late_pct DESC;

-- name: q12b_late_rate_by_seller
-- family: customer behavior | metric 7: NPS (which sellers drive late deliveries)
-- plan: per seller with at least 100 delivered orders, the late rate and average review score. The worst ten tell the business where to start. CHECK: a seller's orders are counted once even with several items (DISTINCT).
WITH so AS (
  SELECT DISTINCT i.seller_id, o.order_id,
         (o.order_delivered_customer_date > o.order_estimated_delivery_date) AS late
  FROM orders o JOIN order_items i ON i.order_id = o.order_id
  WHERE o.order_status = 'delivered' AND o.order_delivered_customer_date IS NOT NULL
)
SELECT so.seller_id, COUNT(*) AS delivered_orders,
       ROUND(100.0 * SUM(so.late) / COUNT(*), 1) AS late_pct,
       ROUND(AVG(rv.review_score), 2) AS avg_review_score
FROM so LEFT JOIN order_reviews rv ON rv.order_id = so.order_id
GROUP BY so.seller_id
HAVING COUNT(*) >= 100
ORDER BY late_pct DESC LIMIT 10;
