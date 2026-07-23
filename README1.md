# Churn Risk Detector — SQL Portfolio Project
By Amandeep Singh | Revenue Operations

## The Problem
Customer Success teams find out about churn when customers cancel.
By then it is too late.

This project uses SQL to surface at-risk accounts BEFORE CS knows,
using three signals that consistently predict churn in B2B SaaS:

1. Engagement drop — no logged activity in 30+ days
2. Support friction — unresolved high-priority tickets
3. Combined risk score — daily CS morning brief ranked by risk

## Data Model
accounts: account_id, account_name, account_owner, mrr, status, created_date, last_activity_date
activities: activity_id, account_id, activity_type, activity_date, created_by
support_tickets: ticket_id, account_id, priority, status, created_date, resolved_date

## The 5 Queries
1. 01_engagement_drop.sql
2. 02_high_value_silent.sql
3. 03_support_friction.sql
4. 04_new_account_risk.sql
5. 05_churn_risk_score.sql

## Why This Matters
Saving 2 accounts/month at $2,000 MRR = $48,000 ARR retained annually.
The query takes 30 seconds to run.

Built as part of Project 100K — transitioning from Sales Ops to RevOps Manager.
Follow: linkedin.com/in/amandeeptheanalyst
