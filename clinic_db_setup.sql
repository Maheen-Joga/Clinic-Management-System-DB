
-- DATABASE: clinic_db
-- Healthcare Clinic Management System
-- Name  : Maheen Joga
-- Module   : B103 Databases & Big Data — Gisma University


DROP DATABASE IF EXISTS clinic_db;
CREATE DATABASE clinic_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE clinic_db;

-- 1. DEPARTMENT
--    head_doctor_id FK added after DOCTOR exists (circular ref)

CREATE TABLE Department (
    department_id   INT            AUTO_INCREMENT PRIMARY KEY,
    dept_name       VARCHAR(100)   NOT NULL,
    location        VARCHAR(100),
    phone           VARCHAR(20),
    head_doctor_id  INT            NULL
);


-- 2. DOCTOR

CREATE TABLE Doctor (
    doctor_id       INT            AUTO_INCREMENT PRIMARY KEY,
    first_name      VARCHAR(50)    NOT NULL,
    last_name       VARCHAR(50)    NOT NULL,
    specialization  VARCHAR(100),
    email           VARCHAR(100)   UNIQUE,
    phone           VARCHAR(20),
    hire_date       DATE,
    department_id   INT            NOT NULL,
    CONSTRAINT fk_doctor_dept
        FOREIGN KEY (department_id) REFERENCES Department(department_id)
        ON DELETE RESTRICT ON UPDATE CASCADE
);

-- Resolve circular reference: Department -> Doctor
ALTER TABLE Department
    ADD CONSTRAINT fk_dept_head
        FOREIGN KEY (head_doctor_id) REFERENCES Doctor(doctor_id)
        ON DELETE SET NULL ON UPDATE CASCADE;


-- 3. INSURANCE

CREATE TABLE Insurance (
    insurance_id    INT            AUTO_INCREMENT PRIMARY KEY,
    provider_name   VARCHAR(100)   NOT NULL,
    policy_number   VARCHAR(50)    NOT NULL UNIQUE,
    coverage_pct    DECIMAL(5,2)   NOT NULL
                    CHECK (coverage_pct BETWEEN 0.00 AND 100.00),
    expiry_date     DATE           NOT NULL
);


-- 4. PATIENT

CREATE TABLE Patient (
    patient_id        INT            AUTO_INCREMENT PRIMARY KEY,
    first_name        VARCHAR(50)    NOT NULL,
    last_name         VARCHAR(50)    NOT NULL,
    date_of_birth     DATE           NOT NULL,
    gender            CHAR(1)        NOT NULL
                      CHECK (gender IN ('M','F','O')),
    email             VARCHAR(100)   UNIQUE,
    phone             VARCHAR(20),
    address           VARCHAR(200),
    registration_date DATE           NOT NULL DEFAULT (CURRENT_DATE),
    insurance_id      INT            NULL,
    CONSTRAINT fk_patient_insurance
        FOREIGN KEY (insurance_id) REFERENCES Insurance(insurance_id)
        ON DELETE SET NULL ON UPDATE CASCADE
);


-- 5. ICD_CODE  (International Classification of Diseases)

CREATE TABLE ICD_Code (
    icd_code_id     INT            AUTO_INCREMENT PRIMARY KEY,
    code            VARCHAR(10)    NOT NULL UNIQUE,
    description     VARCHAR(200)   NOT NULL,
    category        VARCHAR(100)
);


-- 6. APPOINTMENT

CREATE TABLE Appointment (
    appointment_id  INT            AUTO_INCREMENT PRIMARY KEY,
    patient_id      INT            NOT NULL,
    doctor_id       INT            NOT NULL,
    appt_date       DATE           NOT NULL,
    appt_time       TIME           NOT NULL,
    status          VARCHAR(20)    NOT NULL DEFAULT 'Scheduled'
                    CHECK (status IN ('Scheduled','Completed','Cancelled','No-Show')),
    notes           TEXT,
    CONSTRAINT fk_appt_patient
        FOREIGN KEY (patient_id) REFERENCES Patient(patient_id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_appt_doctor
        FOREIGN KEY (doctor_id)  REFERENCES Doctor(doctor_id)
        ON DELETE RESTRICT ON UPDATE CASCADE
);


-- 7. DIAGNOSIS  (M:M bridge: Appointment <-> ICD_Code)

CREATE TABLE Diagnosis (
    diagnosis_id    INT            AUTO_INCREMENT PRIMARY KEY,
    appointment_id  INT            NOT NULL,
    icd_code_id     INT            NOT NULL,
    severity        VARCHAR(20)    NOT NULL
                    CHECK (severity IN ('Mild','Moderate','Severe','Critical')),
    CONSTRAINT fk_diag_appt
        FOREIGN KEY (appointment_id) REFERENCES Appointment(appointment_id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_diag_icd
        FOREIGN KEY (icd_code_id)    REFERENCES ICD_Code(icd_code_id)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT uq_diag_appt_icd
        UNIQUE (appointment_id, icd_code_id)
);


-- 8. MEDICATION

CREATE TABLE Medication (
    medication_id   INT            AUTO_INCREMENT PRIMARY KEY,
    med_name        VARCHAR(100)   NOT NULL,
    manufacturer    VARCHAR(100),
    unit            VARCHAR(20),
    price_per_unit  DECIMAL(8,2)   NOT NULL
                    CHECK (price_per_unit >= 0.00),
    stock_quantity  INT            NOT NULL DEFAULT 0
                    CHECK (stock_quantity >= 0)
);


-- 9. PRESCRIPTION

CREATE TABLE Prescription (
    prescription_id INT            AUTO_INCREMENT PRIMARY KEY,
    appointment_id  INT            NOT NULL UNIQUE,
    issue_date      DATE           NOT NULL DEFAULT (CURRENT_DATE),
    valid_until     DATE,
    pharmacist_notes TEXT,
    CONSTRAINT fk_rx_appt
        FOREIGN KEY (appointment_id) REFERENCES Appointment(appointment_id)
        ON DELETE CASCADE ON UPDATE CASCADE
);


-- 10. PRESCRIPTION_MEDICATION (M:M bridge: Prescription <-> Medication)

CREATE TABLE Prescription_Medication (
    pm_id           INT            AUTO_INCREMENT PRIMARY KEY,
    prescription_id INT            NOT NULL,
    medication_id   INT            NOT NULL,
    dosage          VARCHAR(50)    NOT NULL,
    frequency       VARCHAR(50),
    duration_days   INT            NOT NULL
                    CHECK (duration_days > 0),
    CONSTRAINT fk_pm_rx
        FOREIGN KEY (prescription_id) REFERENCES Prescription(prescription_id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_pm_med
        FOREIGN KEY (medication_id)   REFERENCES Medication(medication_id)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT uq_pm_rx_med
        UNIQUE (prescription_id, medication_id)
);


-- 11. INVOICE

CREATE TABLE Invoice (
    invoice_id      INT            AUTO_INCREMENT PRIMARY KEY,
    appointment_id  INT            NOT NULL UNIQUE,
    total_amount    DECIMAL(10,2)  NOT NULL
                    CHECK (total_amount >= 0),
    paid_amount     DECIMAL(10,2)  NOT NULL DEFAULT 0.00
                    CHECK (paid_amount >= 0),
    payment_date    DATE,
    payment_method  VARCHAR(30)
                    CHECK (payment_method IN ('Cash','Card','Insurance','Bank Transfer')),
    status          VARCHAR(20)    NOT NULL DEFAULT 'Pending'
                    CHECK (status IN ('Pending','Paid','Partial','Waived')),
    CONSTRAINT fk_inv_appt
        FOREIGN KEY (appointment_id) REFERENCES Appointment(appointment_id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT chk_paid_lte_total
        CHECK (paid_amount <= total_amount)
);


-- INDEXES (performance optimisation)

CREATE INDEX idx_doctor_dept     ON Doctor(department_id);
CREATE INDEX idx_patient_ins     ON Patient(insurance_id);
CREATE INDEX idx_appt_patient    ON Appointment(patient_id);
CREATE INDEX idx_appt_doctor     ON Appointment(doctor_id);
CREATE INDEX idx_appt_date       ON Appointment(appt_date);
CREATE INDEX idx_diag_appt       ON Diagnosis(appointment_id);
CREATE INDEX idx_diag_icd        ON Diagnosis(icd_code_id);
CREATE INDEX idx_rx_appt         ON Prescription(appointment_id);
CREATE INDEX idx_pm_rx           ON Prescription_Medication(prescription_id);
CREATE INDEX idx_pm_med          ON Prescription_Medication(medication_id);
CREATE INDEX idx_inv_status      ON Invoice(status);



-- SAMPLE DATA


-- Departments (no head yet; set after doctors are inserted)
INSERT INTO Department (dept_name, location, phone) VALUES
  ('Cardiology',        'Building A, Floor 2', '+49-30-1234-100'),
  ('General Practice',  'Building B, Floor 1', '+49-30-1234-200'),
  ('Neurology',         'Building A, Floor 3', '+49-30-1234-300'),
  ('Orthopaedics',      'Building C, Floor 1', '+49-30-1234-400'),
  ('Paediatrics',       'Building B, Floor 2', '+49-30-1234-500');

-- Doctors
INSERT INTO Doctor (first_name, last_name, specialization, email, phone, hire_date, department_id) VALUES
  ('Elena',   'Fischer',   'Cardiologist',          'e.fischer@clinic.de',   '+49-171-001', '2018-03-15', 1),
  ('Marco',   'Bauer',     'Cardiologist',           'm.bauer@clinic.de',     '+49-171-002', '2020-07-01', 1),
  ('Sarah',   'Weber',     'General Practitioner',   's.weber@clinic.de',     '+49-171-003', '2016-09-10', 2),
  ('Jonas',   'Schreiber', 'General Practitioner',   'j.schreiber@clinic.de', '+49-171-004', '2021-01-20', 2),
  ('Amira',   'Hassan',    'Neurologist',             'a.hassan@clinic.de',    '+49-171-005', '2019-05-11', 3),
  ('David',   'Klein',     'Orthopaedic Surgeon',    'd.klein@clinic.de',     '+49-171-006', '2017-11-03', 4),
  ('Laura',   'Hoffmann',  'Paediatrician',           'l.hoffmann@clinic.de',  '+49-171-007', '2022-02-14', 5);

-- Assign department heads
UPDATE Department SET head_doctor_id = 1 WHERE department_id = 1;
UPDATE Department SET head_doctor_id = 3 WHERE department_id = 2;
UPDATE Department SET head_doctor_id = 5 WHERE department_id = 3;
UPDATE Department SET head_doctor_id = 6 WHERE department_id = 4;
UPDATE Department SET head_doctor_id = 7 WHERE department_id = 5;

-- Insurance providers
INSERT INTO Insurance (provider_name, policy_number, coverage_pct, expiry_date) VALUES
  ('AOK Germany',       'AOK-2024-001', 80.00, '2026-12-31'),
  ('TK Techniker',      'TK-2024-002',  90.00, '2026-06-30'),
  ('Barmer GEK',        'BAR-2024-003', 75.00, '2025-12-31'),
  ('DAK Gesundheit',    'DAK-2024-004', 85.00, '2026-03-31'),
  ('Private Premium',   'PRI-2024-005', 100.00,'2027-01-01');

-- Patients
INSERT INTO Patient (first_name, last_name, date_of_birth, gender, email, phone, address, insurance_id) VALUES
  ('Lukas',    'Müller',    '1985-04-12', 'M', 'lukas.m@email.de',    '+49-160-001', 'Unter den Linden 5, Berlin',   1),
  ('Sophie',   'Schulz',   '1992-08-23', 'F', 'sophie.s@email.de',   '+49-160-002', 'Kurfürstendamm 14, Berlin',    2),
  ('Tom',      'Wagner',   '1978-01-05', 'M', 'tom.w@email.de',      '+49-160-003', 'Alexanderplatz 2, Berlin',     3),
  ('Anna',     'Becker',   '2000-11-30', 'F', 'anna.b@email.de',     '+49-160-004', 'Potsdamer Str 88, Berlin',     4),
  ('Felix',    'Koch',     '1965-07-19', 'M', 'felix.k@email.de',    '+49-160-005', 'Friedrichstr 50, Berlin',      5),
  ('Maria',    'Richter',  '1990-03-07', 'F', 'maria.r@email.de',    '+49-160-006', 'Prenzlauer Allee 10, Berlin',  1),
  ('Noah',     'Wolf',     '2010-09-15', 'M', 'noah.w@email.de',     '+49-160-007', 'Schönhauser Allee 30, Berlin', 2),
  ('Lena',     'Braun',    '1955-12-01', 'F', 'lena.b@email.de',     '+49-160-008', 'Torstr 200, Berlin',           NULL),
  ('Emre',     'Yilmaz',   '1988-06-14', 'M', 'emre.y@email.de',     '+49-160-009', 'Müllerstr 77, Berlin',         3),
  ('Clara',    'Krause',   '1975-02-28', 'F', 'clara.k@email.de',    '+49-160-010', 'Skalitzer Str 5, Berlin',      4);

-- ICD-10 Codes
INSERT INTO ICD_Code (code, description, category) VALUES
  ('I10',   'Essential (primary) hypertension',          'Circulatory System'),
  ('I25.1', 'Atherosclerotic heart disease',              'Circulatory System'),
  ('J06.9', 'Acute upper respiratory tract infection',    'Respiratory System'),
  ('M54.5', 'Low back pain',                             'Musculoskeletal'),
  ('G43.9', 'Migraine, unspecified',                     'Nervous System'),
  ('E11.9', 'Type 2 diabetes mellitus without comp.',    'Endocrine'),
  ('F32.1', 'Moderate depressive episode',               'Mental & Behavioural'),
  ('J45.9', 'Asthma, unspecified',                       'Respiratory System'),
  ('K21.0', 'Gastro-oesophageal reflux with oesophagitis','Digestive System'),
  ('H52.1', 'Myopia',                                    'Eye & Adnexa');

-- Appointments
INSERT INTO Appointment (patient_id, doctor_id, appt_date, appt_time, status, notes) VALUES
  (1,  1, '2024-11-05', '09:00', 'Completed', 'Follow-up for hypertension management'),
  (2,  3, '2024-11-06', '10:30', 'Completed', 'Routine check-up and flu symptoms'),
  (3,  6, '2024-11-07', '14:00', 'Completed', 'Chronic lower back pain review'),
  (4,  5, '2024-11-08', '11:00', 'Completed', 'Recurrent migraine assessment'),
  (5,  1, '2024-11-09', '09:30', 'Completed', 'Atherosclerosis monitoring and ECG'),
  (6,  3, '2024-11-12', '13:00', 'Completed', 'Diabetes and respiratory check'),
  (7,  7, '2024-11-13', '08:30', 'Completed', 'Childhood asthma follow-up'),
  (8,  5, '2024-11-14', '15:30', 'Completed', 'Migraine and depression screening'),
  (9,  3, '2024-11-15', '10:00', 'Completed', 'GERD symptoms review'),
  (10, 6, '2024-11-18', '12:00', 'Completed', 'Back pain post-physiotherapy'),
  (1,  2, '2024-12-02', '09:00', 'Completed', 'Cardiology second opinion'),
  (3,  4, '2024-12-03', '11:30', 'Cancelled', 'Patient cancelled - rescheduled'),
  (5,  2, '2024-12-05', '14:00', 'Completed', 'Post-procedure cardiac review'),
  (2,  3, '2024-12-10', '09:30', 'Scheduled', 'Annual blood panel review'),
  (4,  5, '2024-12-11', '10:00', 'No-Show',   'Patient did not attend');

-- Diagnoses (M:M: Appointment <-> ICD_Code)
INSERT INTO Diagnosis (appointment_id, icd_code_id, severity) VALUES
  (1,  1,  'Moderate'),   -- Appt 1: Hypertension
  (2,  3,  'Mild'),        -- Appt 2: URI
  (3,  4,  'Moderate'),   -- Appt 3: Back pain
  (4,  5,  'Severe'),     -- Appt 4: Migraine
  (5,  2,  'Severe'),     -- Appt 5: Atherosclerosis
  (5,  1,  'Moderate'),   -- Appt 5: Also hypertension (M:M demo)
  (6,  6,  'Moderate'),   -- Appt 6: Diabetes
  (6,  8,  'Mild'),        -- Appt 6: Also asthma (M:M demo)
  (7,  8,  'Moderate'),   -- Appt 7: Asthma
  (8,  5,  'Severe'),     -- Appt 8: Migraine
  (8,  7,  'Moderate'),   -- Appt 8: Also depression (M:M demo)
  (9,  9,  'Mild'),        -- Appt 9: GERD
  (10, 4,  'Mild'),        -- Appt 10: Back pain follow-up
  (11, 1,  'Moderate'),   -- Appt 11: Hypertension
  (13, 2,  'Severe');     -- Appt 13: Atherosclerosis

-- Medications
INSERT INTO Medication (med_name, manufacturer, unit, price_per_unit, stock_quantity) VALUES
  ('Amlodipine 5mg',       'Pfizer',        'tablet',  0.35, 5000),
  ('Metoprolol 50mg',      'AstraZeneca',   'tablet',  0.55, 4000),
  ('Amoxicillin 500mg',    'GSK',           'capsule', 0.80, 3000),
  ('Ibuprofen 400mg',      'Bayer',         'tablet',  0.20, 8000),
  ('Sumatriptan 50mg',     'Novartis',      'tablet',  2.10, 1500),
  ('Metformin 850mg',      'Merck',         'tablet',  0.15, 6000),
  ('Omeprazole 20mg',      'AstraZeneca',   'capsule', 0.40, 4500),
  ('Salbutamol Inhaler',   'GSK',           'inhaler', 8.50,  800),
  ('Sertraline 50mg',      'Pfizer',        'tablet',  0.90, 2000),
  ('Atorvastatin 20mg',    'Pfizer',        'tablet',  0.60, 3500),
  ('Diclofenac 75mg',      'Novartis',      'tablet',  0.45, 2500),
  ('Ramipril 5mg',         'Sanofi',        'capsule', 0.50, 3000);

-- Prescriptions (one per completed appointment where clinically appropriate)
INSERT INTO Prescription (appointment_id, issue_date, valid_until, pharmacist_notes) VALUES
  (1,  '2024-11-05', '2025-05-05', 'Continue current regimen; monitor BP weekly'),
  (2,  '2024-11-06', '2024-11-20', 'Complete full antibiotic course'),
  (3,  '2024-11-07', '2024-12-07', 'Combine with physiotherapy; avoid prolonged sitting'),
  (4,  '2024-11-08', '2025-02-08', 'Take at onset of migraine; max 2 tablets per attack'),
  (5,  '2024-11-09', '2025-11-09', 'Annual statin review in 12 months'),
  (6,  '2024-11-12', '2025-05-12', 'Check HbA1c in 3 months'),
  (7,  '2024-11-13', '2025-05-13', 'Salbutamol PRN; spacer device recommended'),
  (8,  '2024-11-14', '2025-02-14', 'Monitor mood; return in 4 weeks'),
  (9,  '2024-11-15', '2024-12-15', 'Take 30 min before meals'),
  (10, '2024-11-18', '2024-12-18', 'Short course only; physiotherapy referral made'),
  (11, '2024-12-02', '2025-06-02', 'Dual antihypertensive therapy'),
  (13, '2024-12-05', '2025-12-05', 'Continue statin; add antiplatelet therapy');

-- Prescription_Medication (M:M bridge)
INSERT INTO Prescription_Medication (prescription_id, medication_id, dosage, frequency, duration_days) VALUES
  (1,  1,  '5mg',   'Once daily',          90),   -- Rx1: Amlodipine
  (1,  2,  '50mg',  'Twice daily',         90),   -- Rx1: Metoprolol (dual therapy)
  (2,  3,  '500mg', 'Three times daily',   7),    -- Rx2: Amoxicillin
  (3,  4,  '400mg', 'Up to three times',   14),   -- Rx3: Ibuprofen
  (3,  11, '75mg',  'Twice daily',         14),   -- Rx3: Diclofenac (M:M demo)
  (4,  5,  '50mg',  'At onset, max 2/day', 30),   -- Rx4: Sumatriptan
  (5,  10, '20mg',  'Once daily at night', 365),  -- Rx5: Atorvastatin
  (5,  1,  '5mg',   'Once daily',          365),  -- Rx5: Amlodipine (M:M demo)
  (6,  6,  '850mg', 'Twice daily',         90),   -- Rx6: Metformin
  (7,  8,  'PRN',   'As required',         180),  -- Rx7: Salbutamol
  (8,  9,  '50mg',  'Once daily',          28),   -- Rx8: Sertraline
  (8,  5,  '50mg',  'At onset',            28),   -- Rx8: Sumatriptan (M:M demo)
  (9,  7,  '20mg',  '30 min before meals', 28),   -- Rx9: Omeprazole
  (10, 11, '75mg',  'Twice daily',         10),   -- Rx10: Diclofenac
  (11, 1,  '10mg',  'Once daily',          180),  -- Rx11: Amlodipine (higher dose)
  (11, 12, '5mg',   'Once daily',          180),  -- Rx11: Ramipril (M:M demo)
  (12, 10, '40mg',  'Once daily',          365),  -- Rx12: Atorvastatin (higher dose)
  (12, 2,  '100mg', 'Once daily',          365);  -- Rx12: Metoprolol

-- Invoices
INSERT INTO Invoice (appointment_id, total_amount, paid_amount, payment_date, payment_method, status) VALUES
  (1,  120.00, 96.00,  '2024-11-05', 'Insurance',     'Partial'),
  (2,   85.00, 85.00,  '2024-11-06', 'Card',          'Paid'),
  (3,  200.00, 150.00, '2024-11-07', 'Insurance',     'Partial'),
  (4,  160.00, 144.00, '2024-11-08', 'Insurance',     'Partial'),
  (5,  250.00, 250.00, '2024-11-09', 'Insurance',     'Paid'),
  (6,  175.00, 148.75, '2024-11-12', 'Insurance',     'Partial'),
  (7,  110.00,  99.00, '2024-11-13', 'Insurance',     'Partial'),
  (8,  140.00, 140.00, '2024-11-14', 'Card',          'Paid'),
  (9,   95.00,  95.00, '2024-11-15', 'Cash',          'Paid'),
  (10, 180.00, 153.00, '2024-11-18', 'Insurance',     'Partial'),
  (11, 220.00, 220.00, '2024-12-02', 'Bank Transfer', 'Paid'),
  (13, 310.00, 310.00, '2024-12-05', 'Insurance',     'Paid');
-- ── CREATE ──────────────────────────────────────────────────
-- Register a new patient
INSERT INTO Patient (first_name, last_name, date_of_birth, gender, email, phone, address, insurance_id)
VALUES ('Hannah', 'Stein', '1995-03-22', 'F', 'hannah.s@email.de', '+49-162-999', 'Bergmannstr 3, Berlin', 2);

-- Schedule a new appointment
INSERT INTO Appointment (patient_id, doctor_id, appt_date, appt_time, status, notes)
VALUES (11, 3, '2024-12-20', '10:00', 'Scheduled', 'Initial consultation for fatigue');


-- ── READ ────────────────────────────────────────────────────
-- List all upcoming appointments with patient and doctor names
SELECT
    a.appointment_id,
    a.appt_date,
    a.appt_time,
    CONCAT(p.first_name, ' ', p.last_name) AS patient_name,
    CONCAT(d.first_name, ' ', d.last_name) AS doctor_name,
    d.specialization,
    a.status
FROM Appointment a
JOIN Patient p ON a.patient_id = p.patient_id
JOIN Doctor  d ON a.doctor_id  = d.doctor_id
WHERE a.appt_date >= CURDATE()
ORDER BY a.appt_date, a.appt_time;


-- ── UPDATE ──────────────────────────────────────────────────
-- Mark an appointment as completed and add clinical notes
UPDATE Appointment
SET    status = 'Completed',
       notes  = 'Initial consultation completed; blood panel ordered.'
WHERE  appointment_id = 14;

-- Restock a medication
UPDATE Medication
SET    stock_quantity = stock_quantity + 2000
WHERE  med_name = 'Salbutamol Inhaler';


-- ── DELETE ──────────────────────────────────────────────────
-- Cancel and remove a scheduled appointment (cascades to Prescription, Diagnosis, Invoice)
DELETE FROM Appointment
WHERE  appointment_id = 15
  AND  status IN ('Scheduled', 'No-Show');

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
