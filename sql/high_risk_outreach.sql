-- High-risk outreach list (PDC < 0.60) + last fill/runout
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
last_paid_fill AS (
  SELECT patient_id, drug_class, MAX(DATE(fill_date)) AS last_fill_date
  FROM fills
  WHERE paid_status='paid' AND DATE(fill_date) <= DATE('2025-12-31')
  GROUP BY patient_id, drug_class
),
last_fill_details AS (
  SELECT f.patient_id, f.drug_class, DATE(f.fill_date) AS fill_date, f.days_supply
  FROM fills f
  JOIN last_paid_fill l
    ON l.patient_id=f.patient_id AND l.drug_class=f.drug_class AND DATE(f.fill_date)=l.last_fill_date
  WHERE f.paid_status='paid'
)
SELECT pat.provider_id, pr.provider_name, pr.clinic,
       pdc.patient_id, pdc.drug_class, ROUND(pdc.pdc,3) AS pdc,
       lfd.fill_date AS last_fill_date,
       DATE(lfd.fill_date, printf('+%d day', lfd.days_supply - 1)) AS estimated_runout_date,
       CAST((JULIANDAY(DATE('2025-12-31')) - JULIANDAY(DATE(lfd.fill_date, printf('+%d day', lfd.days_supply - 1)))) AS INT) AS days_since_runout_by_period_end
FROM pdc
JOIN patients pat ON pat.patient_id=pdc.patient_id
JOIN providers pr ON pr.provider_id=pat.provider_id
JOIN last_fill_details lfd ON lfd.patient_id=pdc.patient_id AND lfd.drug_class=pdc.drug_class
WHERE pdc.pdc < 0.60
ORDER BY pdc.pdc ASC, days_since_runout_by_period_end DESC, pdc.patient_id;
