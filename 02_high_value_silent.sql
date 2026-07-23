-- ============================================================
-- QUERY 2: High-Value Silent Accounts
-- Finds high-MRR accounts ($1,000+) with no activity in 45+ days
-- Signal: high-value accounts going silent = high churn risk AND high revenue impact
-- ============================================================

WITH recent_activity AS (
    -- Get the most recent activity date per account
    SELECT
        account_id,
        MAX(activity_date) AS last_logged_activity
    FROM activities
    GROUP BY account_id
),

high_value_accounts AS (
    -- Filter to active accounts above MRR threshold
    SELECT
        a.account_id,
        a.account_name,
        a.account_owner,
        a.mrr,
        a.created_date,
        ra.last_logged_activity
    FROM accounts a
    LEFT JOIN recent_activity ra ON a.account_id = ra.account_id
    WHERE
        a.status = 'Active'
        AND a.mrr >= 1000
)

SELECT
    account_id,
    account_name,
    account_owner,
    mrr,
    last_logged_activity,
    DATEDIFF(day, last_logged_activity, GETDATE()) AS days_silent,
    mrr * 12                                        AS arr_at_risk

FROM high_value_accounts

WHERE
    last_logged_activity < DATEADD(day, -45, GETDATE())
    OR last_logged_activity IS NULL  -- never had an activity logged

ORDER BY
    arr_at_risk DESC,
    days_silent DESC;

-- NOTE: IS NULL catches accounts that were onboarded
-- but never had a single activity logged — highest risk segment
