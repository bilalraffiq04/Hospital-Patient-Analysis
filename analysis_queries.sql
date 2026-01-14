-- HOSPITAL PATIENT ANALYSIS
-- Massachusetts General Hospital (2011-2022)

USE hospital_db;

-- Total encounters by year
SELECT
	YEAR(START) AS encounter_year,
	COUNT(*) AS total_encounters
FROM encounters
GROUP BY encounter_year
ORDER BY encounter_year;

-- Encounter breakdown by year and class with percentage distribution
SELECT
	YEAR(START) AS encounter_year,
    ENCOUNTERCLASS,
    COUNT(*) AS records_count,
    ROUND(
		(COUNT(*) * 100.0) / SUM(COUNT(*)) OVER (PARTITION BY YEAR(START)),
        2
    ) AS percentage_of_total
FROM encounters
GROUP BY YEAR(START), ENCOUNTERCLASS
ORDER BY encounter_year, ENCOUNTERCLASS;

-- Categorise encounters by duration (over/under 24 hours)
SELECT
    CASE
        WHEN TIMESTAMPDIFF(HOUR, START, STOP) >= 24 THEN 'Over 24 Hours'
        ELSE 'Under 24 Hours'
    END AS duration_category,
    COUNT(*) AS total_encounters,
    ROUND(
        (COUNT(*) * 100.0 / (SELECT COUNT(*) FROM encounters)),
        2
    ) AS percentage
FROM encounters
GROUP BY duration_category;

-- Identify encounters with zero payer coverage
SELECT
    COUNT(*) AS zero_coverage_count,
    ROUND((COUNT(*) * 100.0) / (SELECT COUNT(*) FROM encounters), 2) AS percentage_zero_coverage
FROM encounters
WHERE Payer_Coverage = 0;

-- Average claim cost by insurance provider
SELECT
    Description AS procedure_name,
    COUNT(*) AS times_performed,
    ROUND(AVG(Base_Cost), 2) AS avg_cost
FROM procedures
GROUP BY procedure_name
ORDER BY times_performed DESC
LIMIT 10;

-- Top 10 most frequently performed procedures
SELECT
    Description AS procedure_name,
    COUNT(*) AS times_performed,
    ROUND(AVG(Base_Cost), 2) AS avg_cost
FROM procedures
GROUP BY procedure_name
ORDER BY avg_cost DESC
LIMIT 10;

-- Top 10 most expensive procedures by average cost
SELECT
    p.Name AS payer_name,
    ROUND(AVG(e.Total_Claim_Cost), 2) AS avg_cost
FROM encounters e
JOIN payers p ON e.Payer = p.Id
GROUP BY p.Name
ORDER BY avg_cost DESC;

-- Unique patient admissions by quarter
SELECT
    YEAR(START) AS admission_year,
    QUARTER(START) AS admission_quarter,
    COUNT(DISTINCT Patient) AS unique_patients
FROM encounters
GROUP BY admission_year, admission_quarter
ORDER BY admission_year, admission_quarter;

-- Total 30-day readmissions
SELECT
    COUNT(*) AS readmissions_count
FROM (
    SELECT
        Patient,
        START,
        LAG(STOP) OVER (PARTITION BY Patient ORDER BY START) AS previous_stop_date
    FROM encounters
) AS ordered_visits
WHERE DATEDIFF(START, previous_stop_date) <= 30;

-- Top 10 patients with highest readmission rates
SELECT
    p.Id AS patient_id,
    CONCAT(p.First, ' ', p.Last) AS patient_name,
    COUNT(*) AS readmission_count
FROM (
    SELECT
        Patient,
        START,
        LAG(STOP) OVER (PARTITION BY Patient ORDER BY START) AS previous_stop_date
    FROM encounters
) AS ordered_visits
JOIN patients p ON ordered_visits.Patient = p.Id
WHERE DATEDIFF(START, previous_stop_date) <= 30
GROUP BY p.Id, p.First, p.Last
ORDER BY readmission_count DESC
LIMIT 10;