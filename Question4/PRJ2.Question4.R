# QUESTION 4.1: WEB SCRAPING AND REGEX
# Step 1: Check website scraping permissions

library(rvest)
library(dplyr)
library(stringr)

# Website chosen to investigate
url <- "https://www.eduvos.com/qualifications/"

# Inspect robots.txt
robots_url <- "https://www.eduvos.com/robots.txt"

robots_text <- tryCatch(
  readLines(robots_url, warn = FALSE),
  error = function(e) {
    message("Could not retrieve robots.txt: ", e$message)
    character(0)
  }
)

cat(paste(robots_text, collapse = "\n"))

# QUESTION 4.1
# Step 2: Inspect the webpage

# Read the Eduvos qualifications webpage
page <- read_html(url)

# Extract visible text from the page
page_text <- page |>
  html_elements("body") |>
  html_text2()

# Display the first 1500 characters
cat(substr(page_text, 1, 1500))



# QUESTION 4.1
# Step 3: Check for programme information

# Search the downloaded HTML text for qualification terms
programme_terms <- c(
  "Bachelor",
  "Diploma",
  "Higher Certificate",
  "Honours"
)

# Count occurrences of each term
term_counts <- sapply(
  programme_terms,
  function(term) {
    str_count(
      page_text,
      regex(term, ignore_case = TRUE)
    )
  }
)

# Display results
print(term_counts)

# QUESTION 4.1
# Step 4: Inspect possible programme headings

# Extract headings from the webpage
programme_headings <- page |>
  html_elements("h1, h2, h3, h4") |>
  html_text2()

# Remove empty headings
programme_headings <- programme_headings[
  nzchar(trimws(programme_headings))
]

# Display number of headings
length(programme_headings)

# Display first 30 headings
head(programme_headings, 30)
]
# QUESTION 4.1
# Step 5: Identify potential programme records

# Find headings containing qualification keywords
programme_matches <- programme_headings[
  str_detect(
    programme_headings,
    regex(
      "Bachelor|Diploma|Higher Certificate|Honours|Master|Doctor",
      ignore_case = TRUE
    )
  )
]

# Count potential programme records
length(programme_matches)

# Display the matching headings
print(programme_matches)


# QUESTION 4.1
# Step 6: Create the initial programme data frame

# Create a data frame from the extracted headings
raw_programmes <- data.frame(
  programme_name = programme_matches,
  stringsAsFactors = FALSE
)

# Extract qualification types using regex
raw_programmes$qualification_type <- str_extract(
  raw_programmes$programme_name,
  regex(
    "Higher Certificate|Postgraduate Diploma|Bachelor|Diploma|Honours|Master|Doctor",
    ignore_case = TRUE
  )
)

# Infer a numerical attribute: programme title word count
raw_programmes$title_word_count <- str_count(
  raw_programmes$programme_name,
  "\\S+"
)

# Display the number of extracted records
nrow(raw_programmes)

# Check how many unique programme names we have
n_distinct(raw_programmes$programme_name)

# Inspect the first 20 records
print(head(raw_programmes, 20))


# QUESTION 4.1
# Step 7: Improve classification using regex

raw_programmes <- raw_programmes |>
  mutate(
    qualification_type = case_when(
      str_detect(programme_name,
                 regex("Honours", ignore_case = TRUE)) ~ "Honours",
      str_detect(programme_name,
                 regex("Postgraduate Diploma", ignore_case = TRUE)) ~ "Postgraduate Diploma",
      str_detect(programme_name,
                 regex("Higher Certificate", ignore_case = TRUE)) ~ "Higher Certificate",
      str_detect(programme_name,
                 regex("Master", ignore_case = TRUE)) ~ "Master",
      str_detect(programme_name,
                 regex("Doctor", ignore_case = TRUE)) ~ "Doctorate",
      str_detect(programme_name,
                 regex("Bachelor", ignore_case = TRUE)) ~ "Bachelor",
      str_detect(programme_name,
                 regex("Diploma", ignore_case = TRUE)) ~ "Diploma",
      TRUE ~ NA_character_
    )
  )

# Check missing values
colSums(is.na(raw_programmes))

# Check duplicated programme names
sum(duplicated(raw_programmes$programme_name))

# Check qualification categories
table(raw_programmes$qualification_type, useNA = "ifany")

# Inspect the data frame
View(raw_programmes)




# QUESTION 4.1
# Step 8: Inspect HTML surrounding programme listings

# Find an actual programme heading
programme_node <- page |>
  html_elements("h1, h2, h3, h4") |>
  purrr::keep(
    ~ str_detect(
      html_text2(.x),
      fixed("Bachelor of Arts Access Programme")
    )
  )

# Check how many matching heading nodes exist
length(programme_node)

if (length(programme_node) > 0) {
  
  # Find the parent HTML element
  parent_node <- programme_node[[1]] |>
    html_element(xpath = "..")
  
  # Display the surrounding HTML
  cat(
    substr(
      as.character(parent_node),
      1,
      3000
    )
  )
}


# QUESTION 4.1
# Step 9: Extract programme cards and their attributes

# Identify individual programme cards
programme_cards <- page |>
  html_elements(".qf-card-body")

# Count programme cards
length(programme_cards)

# Extract information from each card
raw_programmes_full <- data.frame(
  programme_name = programme_cards |>
    html_element(".qf-card-title") |>
    html_text2(),
  
  faculty = programme_cards |>
    html_element(".qf-card-faculty") |>
    html_text2(),
  
  description = programme_cards |>
    html_element(".qf-card-description") |>
    html_text2(),
  
  start_date_raw = programme_cards |>
    html_element(".qf-start-date") |>
    html_text2(),
  
  stringsAsFactors = FALSE
)

# Inspect the extracted data
dim(raw_programmes_full)

head(raw_programmes_full, 10)

# QUESTION 4.1
# Step 10: Apply regex and derive numerical attributes

raw_programmes_full <- raw_programmes_full |>
  mutate(
    # Extract the qualification type from the programme title
    qualification_type = case_when(
      str_detect(programme_name, regex("Honours", ignore_case = TRUE)) ~ "Honours",
      str_detect(programme_name, regex("Postgraduate Diploma", ignore_case = TRUE)) ~ "Postgraduate Diploma",
      str_detect(programme_name, regex("Higher Certificate", ignore_case = TRUE)) ~ "Higher Certificate",
      str_detect(programme_name, regex("Master", ignore_case = TRUE)) ~ "Master",
      str_detect(programme_name, regex("Doctor", ignore_case = TRUE)) ~ "Doctorate",
      str_detect(programme_name, regex("Bachelor", ignore_case = TRUE)) ~ "Bachelor",
      str_detect(programme_name, regex("Diploma", ignore_case = TRUE)) ~ "Diploma",
      TRUE ~ NA_character_
    ),
    
    # Count words in each description
    description_word_count = str_count(
      description,
      "\\S+"
    ),
    
    # Extract a four-digit year from the raw date
    start_year = as.integer(
      str_extract(start_date_raw, "\\b20[0-9]{2}\\b")
    ),
    
    # Identify descriptions that appear truncated
    description_truncated = str_detect(
      description,
      "\\.\\.\\."
    )
  )

# Display dimensions
dim(raw_programmes_full)

# Check missing values
colSums(is.na(raw_programmes_full))

# Check truncated descriptions
table(raw_programmes_full$description_truncated, useNA = "ifany")

# Check duplicate programme names
sum(duplicated(raw_programmes_full$programme_name))

# Inspect the data frame
View(raw_programmes_full)

# QUESTION 4.1
# Step 11: Investigate missing qualification classifications

# Extract records with missing qualification types
unclassified_programmes <- raw_programmes_full |>
  filter(is.na(qualification_type)) |>
  select(programme_name, faculty)

# Display the number of unclassified programmes
nrow(unclassified_programmes)

# Display their names and faculties
print(unclassified_programmes, row.names = FALSE)


# QUESTION 4.1
# Step 12: Summarise raw data quality

data_quality_report <- data.frame(
  metric = c(
    "Total extracted records",
    "Unique programme names",
    "Missing qualification types",
    "Truncated descriptions",
    "Duplicate programme names",
    "Missing start years"
  ),
  
  count = c(
    nrow(raw_programmes_full),
    n_distinct(raw_programmes_full$programme_name),
    sum(is.na(raw_programmes_full$qualification_type)),
    sum(raw_programmes_full$description_truncated, na.rm = TRUE),
    sum(duplicated(raw_programmes_full$programme_name)),
    sum(is.na(raw_programmes_full$start_year))
  )
)

print(data_quality_report)


# ==================================================
# QUESTION 4.2: DATA CLEANING AND TRANSFORMATION
# ==================================================

library(dplyr)
library(stringr)

# Step 1: Create a cleaned copy of the raw dataset
clean_programmes <- raw_programmes_full |>
  mutate(
    # Standardise text formatting
    programme_name = str_squish(programme_name),
    faculty = str_squish(faculty),
    description = str_squish(description),
    
    # Remove trailing ellipses from shortened descriptions
    # This does not restore the missing original text
    description = str_remove(description, "\\s*\\.{3,}\\s*$"),
    
    # Remove the "Start date:" label
    start_date = str_remove(
      start_date_raw,
      regex("^Start date:\\s*", ignore_case = TRUE)
    ),
    
    start_date = str_squish(start_date),
    
    # Improve qualification classification
    qualification_type = case_when(
      str_detect(programme_name, regex("Honours", ignore_case = TRUE)) ~ "Honours",
      str_detect(programme_name, regex("Postgraduate Diploma", ignore_case = TRUE)) ~ "Postgraduate Diploma",
      str_detect(programme_name, regex("Postgraduate Certificate", ignore_case = TRUE)) ~ "Postgraduate Certificate",
      str_detect(programme_name, regex("Higher Certificate", ignore_case = TRUE)) ~ "Higher Certificate",
      str_detect(programme_name, regex("National Certificate", ignore_case = TRUE)) ~ "National Certificate",
      str_detect(programme_name, regex("Master", ignore_case = TRUE)) ~ "Master",
      str_detect(programme_name, regex("Doctor", ignore_case = TRUE)) ~ "Doctorate",
      str_detect(programme_name, regex("Bachelor", ignore_case = TRUE)) ~ "Bachelor",
      str_detect(programme_name, regex("Diploma", ignore_case = TRUE)) ~ "Diploma",
      str_detect(programme_name, regex("Bridging Programme", ignore_case = TRUE)) ~ "Bridging Programme",
      str_detect(programme_name, regex("Pre-degree Foundation", ignore_case = TRUE)) ~ "Foundation Programme",
      str_detect(programme_name, regex("Short Course", ignore_case = TRUE)) ~ "Short Course",
      str_detect(programme_name, regex("Effective Directorship|Entrepreneurship|Management Development Programme", ignore_case = TRUE)) ~ "Professional Development",
      TRUE ~ NA_character_
    )
  ) |>
  # Recalculate word counts after cleaning
  mutate(
    description_word_count = str_count(description, "\\S+")
  ) |>
  # Remove duplicated programme names if present
  distinct(programme_name, .keep_all = TRUE)

# Inspect dimensions
dim(clean_programmes)

# Check missing values after cleaning
colSums(is.na(clean_programmes))

# Inspect qualification categories
table(clean_programmes$qualification_type, useNA = "ifany")

# View cleaned data
View(clean_programmes)

# QUESTION 4.2
# Step 2: Export the cleaned dataset to CSV

# Export the cleaned data
write.csv(
  clean_programmes,
  file = "eduvos_programmes_cleaned.csv",
  row.names = FALSE,
  na = ""
)

# Confirm where the file was saved
getwd()

# Confirm that the file exists
file.exists("eduvos_programmes_cleaned.csv")

# Import the CSV again to verify its contents
verified_programmes <- read.csv(
  "eduvos_programmes_cleaned.csv",
  stringsAsFactors = FALSE
)

# Verify dimensions
dim(verified_programmes)

# Display the first five records
head(verified_programmes, 5)





getwd()
file.exists("eduvos_programmes_cleaned.csv")
normalizePath("eduvos_programmes_cleaned.csv")
