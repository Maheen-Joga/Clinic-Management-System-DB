-- Q1. Monthly Revenue Report: total billed, collected, outstanding

SELECT
    DATE_FORMAT(a.appt_date, '%Y-%m')       AS month,
    COUNT(DISTINCT i.invoice_id)            AS total_invoices,
    FORMAT(SUM(i.total_amount), 2)          AS total_billed_eur,
    FORMAT(SUM(i.paid_amount),  2)          AS total_collected_eur,
    FORMAT(SUM(i.total_amount - i.paid_amount), 2) AS outstanding_eur,
    ROUND(SUM(i.paid_amount) / SUM(i.total_amount) * 100, 1) AS collection_rate_pct
FROM Invoice i
JOIN Appointment a ON i.appointment_id = a.appointment_id
GROUP BY DATE_FORMAT(a.appt_date, '%Y-%m')
ORDER BY month;






-- Q2. Multi-diagnosis appointments (demonstrates M:M power)

SELECT
    a.appointment_id,
    a.appt_date,
    CONCAT(p.first_name, ' ', p.last_name)          AS patient,
    CONCAT(d.first_name, ' ', d.last_name)          AS doctor,
    COUNT(dg.diagnosis_id)                          AS diagnosis_count,
    GROUP_CONCAT(ic.code ORDER BY ic.code SEPARATOR ', ')        AS icd_codes,
    GROUP_CONCAT(ic.description ORDER BY ic.code SEPARATOR ' | ') AS diagnoses
FROM Appointment a
JOIN Patient  p  ON a.patient_id      = p.patient_id
JOIN Doctor   d  ON a.doctor_id       = d.doctor_id
JOIN Diagnosis dg ON a.appointment_id = dg.appointment_id
JOIN ICD_Code  ic ON dg.icd_code_id   = ic.icd_code_id
WHERE a.status = 'Completed'
GROUP BY a.appointment_id, a.appt_date, p.first_name, p.last_name, d.first_name, d.last_name
HAVING COUNT(dg.diagnosis_id) > 1
ORDER BY diagnosis_count DESC;



