-- ============================================================
-- QUERY 1: Engagement Drop Detection
-- Finds active accounts with no logged activity in 30+ days
-- Signal: declining engagement often precedes churn by 30-60 days
-- ============================================================

SELECT
    a.account_id,
    a.account_name,
    a.account_owner,
    a.mrr,
    a.last_activity_date,
    DATEDIFF(day, a.last_activity_date, GETDATE()) AS days_since_activity,
    CASE
        WHEN DATEDIFF(day, a.last_activity_date, GETDATE()) > 90 THEN 'Critical'
        WHEN DATEDIFF(day, a.last_activity_date, GETDATE()) > 60 THEN 'High'
        WHEN DATEDIFF(day, a.last_activity_date, GETDATE()) > 30 THEN 'Medium'
    END AS engagement_risk

FROM accounts a

WHERE
    a.status = 'Active'
    AND a.last_activity_date < DATEADD(day, -30, GETDATE())

ORDER BY
    days_since_activity DESC,
    a.mrr DESC;

-- Expected output: ranked list of accounts going silent
-- sorted by longest inactive first, then by MRR to prioritise value
