-- 1. First, tell MySQL which database we are talking to
USE hospital_db;

-- 2. Run the query for Question 1a
SELECT
	YEAR(START) AS encounter_year, -- Extract '2011' from '2011-01-05'
	COUNT(*) AS total_encounters   -- Count the rows
FROM encounters
GROUP BY encounter_year            -- Bucket them by year
ORDER BY encounter_year;           -- Sort them chronologically


SELECT
	YEAR(START) AS encounter_year,
    ENCOUNTERCLASS,
    COUNT(*) AS records_count,
    -- The Window Function to calculate the percentage:
    ROUND(
		(COUNT(*) * 100.0) / SUM(COUNT(*)) OVER (PARTITION BY YEAR(START)),
        2
    ) AS percentage_of_total
FROM encounters
GROUP BY YEAR(START), ENCOUNTERCLASS
ORDER BY encounter_year, ENCOUNTERCLASS;


SELECT
    -- 1. Create the buckets using CASE
    CASE
        WHEN TIMESTAMPDIFF(HOUR, START, STOP) >= 24 THEN 'Over 24 Hours'
        ELSE 'Under 24 Hours'
    END AS duration_category,

    -- 2. Count how many fall into each bucket
    COUNT(*) AS total_encounters,

    -- 3. Calculate the percentage (Count / Total * 100)
    ROUND(
        (COUNT(*) * 100.0 / (SELECT COUNT(*) FROM encounters)),
        2
    ) AS percentage
FROM encounters
GROUP BY duration_category;


SELECT
    COUNT(*) AS zero_coverage_count,
    ROUND((COUNT(*) * 100.0) / (SELECT COUNT(*) FROM encounters), 2) AS percentage_zero_coverage
FROM encounters
WHERE Payer_Coverage = 0;


SELECT
    Description AS procedure_name,
    COUNT(*) AS times_performed,
    ROUND(AVG(Base_Cost), 2) AS avg_cost
FROM procedures
GROUP BY procedure_name
ORDER BY times_performed DESC
LIMIT 10;


SELECT
    Description AS procedure_name,
    COUNT(*) AS times_performed,
    ROUND(AVG(Base_Cost), 2) AS avg_cost
FROM procedures
GROUP BY procedure_name
ORDER BY avg_cost DESC
LIMIT 10;


SELECT
    p.Name AS payer_name,
    ROUND(AVG(e.Total_Claim_Cost), 2) AS avg_cost
FROM encounters e
JOIN payers p ON e.Payer = p.Id
GROUP BY p.Name
ORDER BY avg_cost DESC;


SELECT
    YEAR(START) AS admission_year,
    QUARTER(START) AS admission_quarter,
    COUNT(DISTINCT Patient) AS unique_patients
FROM encounters
GROUP BY admission_year, admission_quarter
ORDER BY admission_year, admission_quarter;


SELECT
    COUNT(*) AS readmissions_count
FROM (
    -- Step 1: Get the Previous Stop Date for each patient
    SELECT
        Patient,
        START,
        LAG(STOP) OVER (PARTITION BY Patient ORDER BY START) AS previous_stop_date
    FROM encounters
) AS ordered_visits
-- Step 2: Filter for readmissions (within 30 days)
WHERE DATEDIFF(START, previous_stop_date) <= 30;


SELECT
    p.Id AS patient_id,              -- The unique ID (Best Practice)
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