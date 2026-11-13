# Question 4 -- ETL Using R and PostgreSQL

This folder contains the R web-scraping and data-cleaning scripts, the cleaned Eduvos programme dataset, and PostgreSQL SQL queries.

The workflow extracted 68 programme records from the Eduvos website, cleaned the data, exported it to CSV, and imported it into PostgreSQL for two SQL investigations.

### 4.1 Web Scraping
Extracted 68 Eduvos academic programmes using R and web scraping. Data quality checks identified 17 missing qualification classifications and 67 truncated descriptions.

### 4.2 Data Cleaning
Cleaned and standardised the extracted data and processed starting dates. The final dataset contains 68 records and 9 attributes with no missing values, exported as `eduvos_programmes_cleaned.csv`.

### 4.3 PostgreSQL Analysis
Imported the cleaned dataset into PostgreSQL and performed two SQL investigations:

- **Qualification distribution:** Bachelor's degrees were the largest category (25 programmes), followed by Higher Certificates (10) and Honours (8).
- **Faculty distribution:** Technology had the most programmes (29.41%), followed by Commerce (27.94%) and Humanities and Arts (25%).

### Tools Used
R, RStudio, rvest, dplyr, stringr, PostgreSQL and pgAdmin.

### Project Files
- `PRJ2.Question4.R` — R script
- `eduvos_programmes_cleaned.csv` — cleaned dataset
- `question4_postgresql.sql` — SQL queries
