# 🏥 Healthcare Clinic Management System
### B103 Databases & Big Data — Gisma University of Applied Sciences

![MySQL](https://img.shields.io/badge/MySQL-8.0-blue?logo=mysql&logoColor=white)
![Status](https://img.shields.io/badge/Status-Complete-brightgreen)
![License](https://img.shields.io/badge/License-Academic-lightgrey)

---

## 📋 Project Overview

A fully normalised relational database system designed to manage the core operations of an outpatient medical clinic. The system handles patients, doctors, departments, appointments, clinical diagnoses (ICD-10 coded), multi-drug prescriptions, and patient invoicing — all enforced with proper constraints, foreign keys, and indexing.

- **Technology:** MySQL 8.0  
- **Tables:** 11 (including 2 many-to-many bridge tables)  
- **Normalisation:** Third Normal Form (3NF) throughout  

---

## 🎥 Video Demonstration

▶️ **Watch here:** [Click to watch the demo](https://youtu.be/YOUR_VIDEO_ID)

---

## 📁 Repository Structure
---

## 🗄️ Database Schema

### Reference Tables
| Table | Description |
|---|---|
| `Department` | Clinical departments (Cardiology, Neurology, etc.) |
| `Insurance` | Insurance providers and coverage percentages |
| `ICD_Code` | Standard ICD-10 diagnosis classification codes |
| `Medication` | Drug inventory with pricing and stock levels |

### Core Transactional Tables
| Table | Description |
|---|---|
| `Doctor` | Medical staff linked to departments |
| `Patient` | Patient demographics and insurance linkage |
| `Appointment` | Scheduled or completed patient-doctor encounters |
| `Prescription` | Prescriptions issued per appointment |
| `Invoice` | Billing and payment records per appointment |

### Many-to-Many Bridge Tables
| Table | Resolves |
|---|---|
| `Diagnosis` | `Appointment` ↔ `ICD_Code` |
| `Prescription_Medication` | `Prescription` ↔ `Medication` |

---

## ⚙️ Setup Instructions

**Prerequisites:** MySQL 8.0 or higher
```bash
# 1. Clone the repository
git clone https://github.com/YOUR_USERNAME/clinic-db.git
cd clinic-db

# 2. Log into MySQL
mysql -u root -p

# 3. Run scripts in order
SOURCE sql/01_create_database.sql;
SOURCE sql/02_insert_data.sql;
SOURCE sql/03_queries.sql;
```

---

## 🔑 Key Design Decisions

- **Circular FK via `ALTER TABLE`** — `Department` and `Doctor` reference each other; resolved by adding the head doctor FK after both tables are created  
- **ICD-10 as a reference table** — diagnosis descriptions stored once, eliminating update anomalies  
- **Cross-column CHECK constraint** — `CHECK (paid_amount <= total_amount)` enforced at the database layer  
- **`ON DELETE CASCADE`** — deleting an appointment automatically cleans up diagnoses, prescriptions, and invoices  

---

## 📊 Sample Queries

**Monthly Revenue Report**
```sql
SELECT
    DATE_FORMAT(a.appt_date, '%Y-%m') AS month,
    FORMAT(SUM(i.total_amount), 2)    AS total_billed_eur,
    FORMAT(SUM(i.paid_amount),  2)    AS total_collected_eur,
    ROUND(SUM(i.paid_amount) / SUM(i.total_amount) * 100, 1) AS collection_rate_pct
FROM Invoice i
JOIN Appointment a ON i.appointment_id = a.appointment_id
GROUP BY DATE_FORMAT(a.appt_date, '%Y-%m')
ORDER BY month;
```

**Multi-Diagnosis Appointments**
```sql
SELECT
    a.appointment_id,
    CONCAT(p.first_name, ' ', p.last_name) AS patient,
    COUNT(dg.diagnosis_id)                 AS diagnosis_count,
    GROUP_CONCAT(ic.code SEPARATOR ', ')   AS icd_codes
FROM Appointment a
JOIN Patient   p  ON a.patient_id     = p.patient_id
JOIN Diagnosis dg ON a.appointment_id = dg.appointment_id
JOIN ICD_Code  ic ON dg.icd_code_id   = ic.icd_code_id
WHERE a.status = 'Completed'
GROUP BY a.appointment_id
HAVING COUNT(dg.diagnosis_id) > 1;
```

---

## 👤 Author

| Field | Detail |
|---|---|
| **Name** | Maheen Joga |
| **Student ID** | GH1038258 |
| **University** | Gisma University of Applied Sciences |
| **Module** | B103 Databases & Big Data |


---

> ⚠️ **Academic Note:** This repository was frozen at the submission deadline in accordance with the assessment brief. No changes were made after submission.
