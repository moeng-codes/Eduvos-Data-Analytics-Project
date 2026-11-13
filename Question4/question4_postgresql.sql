-- QUESTION 4.3: PostgreSQL Database Analysis
-- Dataset: Eduvos Academic Programmes
-- Source: Eduvos website
-- Records: 68

-- 1. Create the relational table
-- Run this before importing the cleaned CSV.
CREATE TABLE IF NOT EXISTS public.eduvos_programmes (
    programme_id SERIAL PRIMARY KEY,
    programme_name TEXT,
    faculty TEXT,
    description TEXT,
    start_date_raw TEXT,
    qualification_type VARCHAR(100),
    description_word_count INTEGER,
    start_year INTEGER,
    description_truncated BOOLEAN,
    start_date TEXT
);

-- 2. Verify the imported dataset
SELECT COUNT(*) AS total_records
FROM public.eduvos_programmes;

-- 3. Investigation 1:
-- Distribution of programmes by qualification type
SELECT
    qualification_type,
    COUNT(*) AS programme_count
FROM public.eduvos_programmes
GROUP BY qualification_type
ORDER BY programme_count DESC;

-- 4. Investigation 2:
-- Distribution of programmes across faculties
SELECT
    faculty,
    COUNT(*) AS total_programmes,
    ROUND(
        COUNT(*) * 100.0 /
        (SELECT COUNT(*) FROM public.eduvos_programmes),
        2
    ) AS percentage
FROM public.eduvos_programmes
GROUP BY faculty
ORDER BY total_programmes DESC;
