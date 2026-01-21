# Medication Adherence Reporting (portfolio project)

**Measurement period:** 2025-07-01 to 2025-12-31 (184 days)  
**Focus:** Statins, HTN meds, Diabetes meds  
**Database:** SQLite (`med_adherence.db`)

## Overview
This project analyzes pharmacy refill data to assess medication adherence using
**Proportion of Days Covered (PDC)** and summarizes the results in an Excel dashboard.

The intent is to provide a simple reporting view that helps providers and care teams
identify patients who may be at risk for non-adherence and prioritize follow-up.


## Adherence Definitions
- **PDC (Proportion of Days Covered)**  
  Covered medication days divided by total days in the measurement period

- **Adherent:** PDC ≥ 80%  
- **Moderate Risk:** PDC 60–79%  
- **High Risk:** PDC < 60%

These thresholds are consistent with commonly used quality and population health standards.


## What This Project Produces
- Patient-level PDC calculations by medication class
- Provider-level summaries for high-level review
- A high-risk patient list to support outreach
- An Excel dashboard with basic filtering by provider and medication class
