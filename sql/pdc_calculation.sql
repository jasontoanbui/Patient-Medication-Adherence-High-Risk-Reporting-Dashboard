-- PDC per patient + drug_class (optimized; no calendar CTE)
-- Period: 2025-07-01 to 2025-12-31 (184 days)

WITH fills_expanded AS (
  SELECT
    patient_id,
    drug_class,
    DATE(fill_date) AS start_date,
    DATE(fill_date, printf('+%d day', days_supply - 1)) AS end_date
  FROM fills
  WHERE paid_status = 'paid'
),
period AS (
  SELECT DATE('2025-07-01') AS start_date,
         DATE('2025-12-31')   AS end_date
),
coverage AS (
  SELECT
    f.patient_id,
    f.drug_class,
    MAX(f.start_date, p.start_date) AS cov_start,
    MIN(f.end_date, p.end_date)     AS cov_end
  FROM fills_expanded f
  JOIN period p
    ON f.end_date >= p.start_date
   AND f.start_date <= p.end_date
),
covered_days AS (
  SELECT
    patient_id,
    drug_class,
    SUM(JULIANDAY(cov_end) - JULIANDAY(cov_start) + 1) AS covered_days
  FROM coverage
  WHERE cov_end >= cov_start
  GROUP BY patient_id, drug_class
)
SELECT
  patient_id,
  drug_class,
  CAST(covered_days AS INT) AS covered_days,
  184 AS period_days,
  ROUND(covered_days / 184.0, 3) AS pdc,
  CASE
    WHEN covered_days / 184.0 >= 0.80 THEN 'Adherent'
    WHEN covered_days / 184.0 >= 0.60 THEN 'Moderate Risk'
    ELSE 'High Risk'
  END AS risk_band
FROM covered_days
ORDER BY pdc ASC, patient_id;

