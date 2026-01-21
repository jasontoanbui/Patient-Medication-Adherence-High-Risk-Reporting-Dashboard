-- Provider panel summary (by provider + drug_class)
WITH fills_expanded AS (
  SELECT patient_id, drug_class,
         DATE(fill_date) AS start_date,
         DATE(fill_date, printf('+%d day', days_supply - 1)) AS end_date
  FROM fills
  WHERE paid_status='paid'
),
period AS (
  SELECT DATE('2025-07-01') AS start_date,
         DATE('2025-12-31') AS end_date
),
coverage AS (
  SELECT f.patient_id, f.drug_class,
         MAX(f.start_date, p.start_date) AS cov_start,
         MIN(f.end_date, p.end_date) AS cov_end
  FROM fills_expanded f
  JOIN period p
    ON f.end_date >= p.start_date AND f.start_date <= p.end_date
),
covered_days AS (
  SELECT patient_id, drug_class,
         SUM(JULIANDAY(cov_end) - JULIANDAY(cov_start) + 1) AS covered_days
  FROM coverage
  WHERE cov_end >= cov_start
  GROUP BY patient_id, drug_class
),
pdc AS (
  SELECT patient_id, drug_class, covered_days / 184.0 AS pdc
  FROM covered_days
),
pdc_with_provider AS (
  SELECT pat.provider_id, pdc.patient_id, pdc.drug_class, pdc.pdc,
         CASE WHEN pdc.pdc >= 0.80 THEN 1 ELSE 0 END AS is_adherent,
         CASE WHEN pdc.pdc < 0.60 THEN 1 ELSE 0 END AS is_high_risk
  FROM pdc
  JOIN patients pat ON pat.patient_id = pdc.patient_id
)
SELECT pr.provider_id, pr.provider_name, pr.clinic, pdc.drug_class,
       COUNT(DISTINCT pdc.patient_id) AS patients_in_class,
       ROUND(AVG(pdc.is_adherent)*100.0,1) AS pct_adherent,
       ROUND(AVG(pdc.is_high_risk)*100.0,1) AS pct_high_risk,
       ROUND(AVG(pdc.pdc),3) AS avg_pdc
FROM pdc_with_provider pdc
JOIN providers pr ON pr.provider_id = pdc.provider_id
GROUP BY pr.provider_id, pr.provider_name, pr.clinic, pdc.drug_class
ORDER BY pr.provider_id, pdc.drug_class;
