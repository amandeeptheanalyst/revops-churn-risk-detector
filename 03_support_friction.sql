-- ============================================================
-- QUERY 3: Support Friction Detection
-- Finds accounts with unresolved high-priority or critical tickets
-- Signal: unresolved tickets + silence = imminent churn risk
-- ============================================================

WITH open_high_priority_tickets AS (
    SELECT
        account_id,
        COUNT(*)                                            AS open_ticket_count,
        SUM(CASE WHEN priority = 'Critical' THEN 1 ELSE 0
            END)                                           AS critical_tickets,
        MIN(created_date)                                  AS oldest_ticket_date,
        DATEDIFF(day, MIN(created_date), GETDATE())        AS max_ticket_age_days
    FROM support_tickets
    WHERE
        status NOT IN ('Resolved', 'Closed')
        AND priority IN ('High', 'Critical')
    GROUP BY account_id
)

SELECT
    a.account_name,
    a.account_owner,
    a.mrr,
    t.open_ticket_count,
    t.critical_tickets,
    t.max_ticket_age_days,
    t.oldest_ticket_date,
    CASE
        WHEN t.critical_tickets > 0 AND t.max_ticket_age_days > 7  THEN 'Critical'
        WHEN t.open_ticket_count >= 3                               THEN 'High'
        WHEN t.max_ticket_age_days > 14                             THEN 'High'
        ELSE                                                             'Medium'
    END AS support_risk_level

FROM open_high_priority_tickets t
INNER JOIN accounts a ON t.account_id = a.account_id

WHERE a.status = 'Active'

ORDER BY
    support_risk_level,
    t.critical_tickets DESC,
    t.max_ticket_age_days DESC;

-- Critical + 7+ days unresolved = highest churn predictor
-- in most B2B SaaS businesses
