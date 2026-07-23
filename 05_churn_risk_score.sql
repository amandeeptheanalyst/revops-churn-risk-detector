-- ============================================================
-- QUERY 5: Combined Churn Risk Score
-- The daily CS morning brief — all signals combined into one ranked list
-- Schedule this to run every morning at 8am
-- ============================================================

WITH engagement_signal AS (
    SELECT
        account_id,
        DATEDIFF(day, last_activity_date, GETDATE()) AS days_inactive,
        CASE
            WHEN DATEDIFF(day, last_activity_date, GETDATE()) > 90 THEN 40
            WHEN DATEDIFF(day, last_activity_date, GETDATE()) > 60 THEN 25
            WHEN DATEDIFF(day, last_activity_date, GETDATE()) > 30 THEN 10
            ELSE 0
        END AS engagement_score
    FROM accounts
    WHERE status = 'Active'
),

support_signal AS (
    SELECT
        account_id,
        COUNT(*)                                    AS open_tickets,
        SUM(CASE WHEN priority = 'Critical' THEN 30
                 WHEN priority = 'High'     THEN 15
                 ELSE 0 END)                       AS support_score
    FROM support_tickets
    WHERE status NOT IN ('Resolved', 'Closed')
    GROUP BY account_id
),

onboarding_signal AS (
    SELECT
        a.account_id,
        CASE
            WHEN DATEDIFF(day, a.created_date, GETDATE()) <= 90
             AND COALESCE(act.activity_count, 0) = 0 THEN 25
            WHEN DATEDIFF(day, a.created_date, GETDATE()) <= 90
             AND DATEDIFF(day, act.last_activity, GETDATE()) > 14 THEN 15
            ELSE 0
        END AS onboarding_score
    FROM accounts a
    LEFT JOIN (
        SELECT account_id,
               COUNT(*)          AS activity_count,
               MAX(activity_date) AS last_activity
        FROM activities
        GROUP BY account_id
    ) act ON a.account_id = act.account_id
    WHERE a.status = 'Active'
),

combined_scores AS (
    SELECT
        a.account_id,
        a.account_name,
        a.account_owner,
        a.mrr,
        a.last_activity_date,
        COALESCE(e.days_inactive, 0)                              AS days_inactive,
        COALESCE(e.engagement_score, 0)                           AS engagement_score,
        COALESCE(s.open_tickets, 0)                               AS open_tickets,
        COALESCE(s.support_score, 0)                              AS support_score,
        COALESCE(o.onboarding_score, 0)                           AS onboarding_score,
        COALESCE(e.engagement_score, 0)
            + COALESCE(s.support_score, 0)
            + COALESCE(o.onboarding_score, 0)                     AS total_risk_score
    FROM accounts a
    LEFT JOIN engagement_signal e  ON a.account_id = e.account_id
    LEFT JOIN support_signal    s  ON a.account_id = s.account_id
    LEFT JOIN onboarding_signal o  ON a.account_id = o.account_id
    WHERE a.status = 'Active'
)

SELECT
    account_name,
    account_owner,
    mrr,
    mrr * 12                                            AS arr_at_risk,
    days_inactive,
    open_tickets,
    total_risk_score,
    CASE
        WHEN total_risk_score >= 50 THEN 'CRITICAL — Act today'
        WHEN total_risk_score >= 30 THEN 'HIGH — Act this week'
        WHEN total_risk_score >= 15 THEN 'MEDIUM — Monitor closely'
        ELSE                              'LOW — Healthy'
    END                                                 AS risk_level,
    engagement_score,
    support_score,
    onboarding_score

FROM combined_scores

WHERE total_risk_score > 0

ORDER BY
    total_risk_score DESC,
    mrr DESC;

-- This is your daily CS morning brief
-- Top accounts = most urgent outreach today
-- Schedule via Power Automate, dbt, or any SQL runner
-- Output feeds into Teams message, Power BI dashboard, or email digest
