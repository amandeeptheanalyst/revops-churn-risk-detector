-- ============================================================
-- QUERY 4: New Account Onboarding Risk
-- Finds accounts created in last 90 days with no activity in 14+ days
-- Signal: early disengagement during onboarding = highest churn predictor
-- ============================================================

WITH new_accounts AS (
    SELECT
        account_id,
        account_name,
        account_owner,
        mrr,
        created_date,
        DATEDIFF(day, created_date, GETDATE()) AS account_age_days
    FROM accounts
    WHERE
        status = 'Active'
        AND created_date >= DATEADD(day, -90, GETDATE())
),

activity_counts AS (
    SELECT
        account_id,
        COUNT(*)            AS total_activities,
        MAX(activity_date)  AS last_activity
    FROM activities
    WHERE activity_date >= DATEADD(day, -90, GETDATE())
    GROUP BY account_id
)

SELECT
    n.account_name,
    n.account_owner,
    n.mrr,
    n.account_age_days,
    COALESCE(ac.total_activities, 0)                    AS activities_logged,
    ac.last_activity,
    DATEDIFF(day, ac.last_activity, GETDATE())          AS days_since_last_activity,
    CASE
        WHEN COALESCE(ac.total_activities, 0) = 0       THEN 'No activity ever logged'
        WHEN DATEDIFF(day, ac.last_activity, GETDATE()) > 14
                                                         THEN 'Disengaged early'
        ELSE                                                  'Engaged'
    END AS onboarding_status

FROM new_accounts n
LEFT JOIN activity_counts ac ON n.account_id = ac.account_id

WHERE
    COALESCE(ac.total_activities, 0) = 0
    OR DATEDIFF(day, ac.last_activity, GETDATE()) > 14

ORDER BY
    activities_logged ASC,
    n.mrr DESC;

-- Accounts with ZERO activities logged are the most critical
-- They signed up and disappeared — needs immediate CS outreach
