# Business Growth & Revenue Health Monitoring Dashboard

overview in front page : 

> This dashboard analyzes weekly revenue performance for a Telco company through user base dynamics, breaking growth and decline into retention, acquisition, reactivation, and leakage. It highlights not only what changed, but why it changed, and surfaces near-term revenue exposure driven by user inactivity, to support data-driven growth and retention decisions.
> 

## Objective

1. Purpose
    
    The objective of this dashboard is to provide a weekly business health snapshot by linking revenue performance with underlying user behavior. 
    
    This helps to identify whether revenue changes are driven by core retention, new acquisition, reactivation, or user drop, and to detect early signals of potential revenue risk based on inactivity patterns.
    
2. Dataset 
    
    This dashboard uses a public Telco Customer and Revenue Dataset from Kaggle, including three raw tables :
    
    - CRM (13.6M records)
    - Device (2.4M records)
    - Revenue (1.7M records)
3. Tools
    - SQL : data cleaning, user movement classification, and weekly aggregation
    - Tableau : visualization & dashboard design

## User Definition

Users contribute to the current week's revenue: 

- Retained : Users generating revenue in the current week and W-1
- New : Users generating revenue for the first time, with no prior revenue history
- Re-activated : Users generating revenue in the current week, inactive in W-1, but with at least one revenue-generating week before W-1

Users with potential revenue loss: 

- Dropped : Users who generate revenue in W-1 but not in the current week (WoW loss)
- At-Risk : Users with no revenue in the current week and 4 - 7 consecutive weeks of inactivity (no revenue) backwards, indicate exposure to short-term revenue but unconfirmed churn 
Churn is defined as 8 consecutive inactive weeks.

All user states are created using SQL  documented in the attached .sql file.

## Dashboard Section

1. Dashboard 1 : Weekly Business Health & Growth Snapshot
    
    Provides a high-level overview of weekly revenue, user base, and ARPU performance, along with a user movement breakdown to explain what drives revenue changes in the current week.
    
2. Dashboard 2 : Near-Term Revenue Exposure & Retention Risk
    
    Focuses on users approaching the churn threshold, measures at-risk user volume & potential revenue loss  if no action is taken.
    

## Key Insight

- Overall revenue trend shows significant positive growth since W26. However, the **first decreasing event** occurs in the latest week (-2.12%)
  
- ARPU this week remains stable, indicating the revenue loss is primarily driven by **fewer active users** rather than spending usage per user
  
- Based on user movement breakdown, the proportion of drop users is increasing while the number of new and re-activated users is decreasing, reflected in negative net user change. This indicates the **overall active revenue-generating user base is shrinking this week**
  
- By correlating the revenue and user trends in Dashboard 1 and the At-Risk Users & Revenue pool trends in Dashboard 2, it is revealed :
  
    - Alignment between the at-risk user pool peak timing in earlier week (W28 - 30) with revenue declining in the current week, reflecting a **lagged impact of inactive users**.
      
    - On the contrary, revenue improvement from W31 onwards aligns with the at-risk declination, indicating that **revenue growth coincides with a contraction in the at-risk pool**.
      
    - The majority of at-risk users (99.38%) fall into **4-week inactivity duration**, suggesting the possibility of at-risk users transitioning into churned, and revenue impact will occur around W39 if no intervention
      
- In Week 35, retained users performed well by an increase in their proportion (97%, +2%), indicating a **healthy core of existing users**
  
- However, a **few shares of new & reactivated users**, combined with a **higher number of dropped users**, contribute to a net revenue decline in W35.

- Given the inactivity pattern of at-risk users, continued weakness in acquisition or reactivation could add to revenue loss in future weeks.

## Next Steps & Recommendations

1. Focus on the 162 at-risk users analysis  with prioritized higher historical ARPU to plan targeted retention actions.
2. Analyze declining new and reactivated users, focusing on acquisition channels and reactivation.
3. Monitor the next 3 -4 weeks closely to validate whether current at-risk users turn into churn and  impact revenue loss.
