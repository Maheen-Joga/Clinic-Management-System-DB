

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



-- Q2. Doctor Workload & Earnings: appointments, completion rate, revenue

SELECT
    CONCAT(d.first_name, ' ', d.last_name)  AS doctor,
    d.specialization,
    dept.dept_name                           AS department,
    COUNT(a.appointment_id)                 AS total_appointments,
    SUM(CASE WHEN a.status = 'Completed' THEN 1 ELSE 0 END)  AS completed,
    ROUND(
        SUM(CASE WHEN a.status = 'Completed' THEN 1 ELSE 0 END)
        * 100.0 / COUNT(a.appointment_id), 1)               AS completion_pct,
    FORMAT(COALESCE(SUM(i.paid_amount), 0), 2)              AS revenue_generated_eur
FROM Doctor d
JOIN Department dept  ON d.department_id  = dept.department_id
LEFT JOIN Appointment a ON d.doctor_id    = a.doctor_id
LEFT JOIN Invoice i     ON a.appointment_id = i.appointment_id
GROUP BY d.doctor_id, d.first_name, d.last_name, d.specialization, dept.dept_name
ORDER BY SUM(COALESCE(i.paid_amount, 0)) DESC;



-- Q3. Top 5 Most Prescribed Medications with cost analysis

SELECT
    m.med_name,
    m.manufacturer,
    COUNT(pm.pm_id)                          AS times_prescribed,
    SUM(pm.duration_days)                    AS total_patient_days,
    FORMAT(SUM(pm.duration_days * m.price_per_unit), 2) AS estimated_cost_eur
FROM Prescription_Medication pm
JOIN Medication m ON pm.medication_id = m.medication_id
GROUP BY m.medication_id, m.med_name, m.manufacturer
ORDER BY times_prescribed DESC
LIMIT 5;



-- Q4. Patient Diagnosis History with insurance coverage detail

SELECT
    CONCAT(p.first_name, ' ', p.last_name)  AS patient,
    p.date_of_birth,
    TIMESTAMPDIFF(YEAR, p.date_of_birth, CURDATE()) AS age,
    i.provider_name                          AS insurer,
    i.coverage_pct,
    a.appt_date,
    ic.code                                  AS icd_code,
    ic.description                           AS diagnosis,
    ic.category,
    dg.severity,
    CONCAT(d.first_name, ' ', d.last_name)  AS treating_doctor
FROM Patient p
LEFT JOIN Insurance   i  ON p.insurance_id    = i.insurance_id
JOIN      Appointment a  ON p.patient_id      = a.patient_id
JOIN      Diagnosis   dg ON a.appointment_id  = dg.appointment_id
JOIN      ICD_Code    ic ON dg.icd_code_id    = ic.icd_code_id
JOIN      Doctor      d  ON a.doctor_id       = d.doctor_id
WHERE a.status = 'Completed'
ORDER BY p.last_name, a.appt_date DESC;


-- Q5. Multi-diagnosis appointments (demonstrates M:M power)

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



-- Q6. Patients with outstanding balances (accounts receivable)

SELECT
    CONCAT(p.first_name, ' ', p.last_name)      AS patient,
    p.email,
    p.phone,
    COALESCE(ins.provider_name, 'Self-Pay')     AS insurer,
    COUNT(i.invoice_id)                         AS open_invoices,
    FORMAT(SUM(i.total_amount - i.paid_amount), 2) AS total_outstanding_eur
FROM Patient p
LEFT JOIN Insurance ins ON p.insurance_id = ins.insurance_id
JOIN Appointment a      ON p.patient_id   = a.patient_id
JOIN Invoice i          ON a.appointment_id = i.appointment_id
WHERE i.status IN ('Pending', 'Partial')
GROUP BY p.patient_id, p.first_name, p.last_name, p.email, p.phone, ins.provider_name
HAVING SUM(i.total_amount - i.paid_amount) > 0
ORDER BY SUM(i.total_amount - i.paid_amount) DESC;

-- Q7. Department performance summary (nested aggregation)

SELECT
    dept.dept_name,
    COUNT(DISTINCT doc.doctor_id)               AS num_doctors,
    COUNT(DISTINCT a.appointment_id)            AS total_appointments,
    SUM(CASE WHEN a.status='Completed' THEN 1 ELSE 0 END) AS completed_appts,
    FORMAT(SUM(COALESCE(i.paid_amount, 0)), 2)  AS dept_revenue_eur,
    COUNT(DISTINCT dg.icd_code_id)              AS unique_diagnoses_treated
FROM Department dept
LEFT JOIN Doctor      doc ON dept.department_id   = doc.department_id
LEFT JOIN Appointment a   ON doc.doctor_id        = a.doctor_id
LEFT JOIN Invoice     i   ON a.appointment_id     = i.appointment_id
LEFT JOIN Diagnosis   dg  ON a.appointment_id     = dg.appointment_id
GROUP BY dept.department_id, dept.dept_name
ORDER BY SUM(COALESCE(i.paid_amount, 0)) DESC;
