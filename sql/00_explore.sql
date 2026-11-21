-- =========================================================
-- 00_explore.sql
-- 데이터 탐색 (2026-11-21)
-- 데이터: bigquery-public-data.google_analytics_sample (2016-08-01 ~ 2017-08-01)
-- =========================================================


-- ① 전체 규모: 방문자, 세션, 재방문 세션 수
-- 결과: visitors 714,167 / sessions 903,653 / return_sessions 200,593 (약 22%)
SELECT
  COUNT(DISTINCT fullVisitorId) AS visitors,
  COUNT(*)                      AS sessions,
  COUNTIF(visitNumber > 1)      AS return_sessions
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
WHERE _TABLE_SUFFIX BETWEEN '20160801' AND '20170801';


-- ② 재구매 유저 수
-- 결과: buyers 10,022 / repeat_buyers 971 / repeat_rate 0.097
SELECT
  COUNT(*)                                             AS buyers,
  COUNTIF(purchase_sessions >= 2)                      AS repeat_buyers,
  ROUND(COUNTIF(purchase_sessions >= 2) / COUNT(*), 3) AS repeat_rate
FROM (
  SELECT fullVisitorId, COUNT(*) AS purchase_sessions
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
  WHERE _TABLE_SUFFIX BETWEEN '20160801' AND '20170801'
    AND totals.transactions >= 1
  GROUP BY fullVisitorId
);


-- ③ 첫 구매 후 다시 방문한 유저 수
-- 결과: buyers 10,022 / revisited_after_buy 3,902 (약 39%)
WITH s AS (
  SELECT fullVisitorId,
         PARSE_DATE('%Y%m%d', date) AS d,
         totals.transactions        AS tx
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
  WHERE _TABLE_SUFFIX BETWEEN '20160801' AND '20170801'
),
first_buy AS (
  SELECT fullVisitorId, MIN(d) AS first_buy_date
  FROM s
  WHERE tx >= 1
  GROUP BY fullVisitorId
)
SELECT
  COUNT(DISTINCT f.fullVisitorId) AS buyers,
  COUNT(DISTINCT IF(s.d > f.first_buy_date, f.fullVisitorId, NULL)) AS revisited_after_buy
FROM first_buy AS f
JOIN s USING (fullVisitorId);
