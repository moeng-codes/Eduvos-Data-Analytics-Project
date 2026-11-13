# QUESTION 1.2: MAP FUNCTION

mapper <- function(file_path, keyword) {
  
  # Read the document
  lines <- readLines(file_path, warn = FALSE)
  
  # Create an empty results table
  results <- data.frame(
    Document = character(),
    Row = integer(),
    Column = integer()
  )
  
  # Convert keyword to lowercase
  keyword <- tolower(keyword)
  
  # Search each line
  for (i in seq_along(lines)) {
    
    # Convert line to lowercase
    line_lower <- tolower(lines[i])
    
    # Find all keyword positions
    positions <- gregexpr(
      keyword,
      line_lower,
      fixed = TRUE
    )[[1]]
    
    # Store matching positions
    if (positions[1] != -1) {
      
      for (pos in positions) {
        
        results <- rbind(
          results,
          data.frame(
            Document = basename(file_path),
            Row = i,
            Column = pos
          )
        )
      }
    }
  }
  
  return(results)
}


# Select the folder containing the text documents
folder_path <- file.choose()
folder_path <- dirname(folder_path)

# Get all text files
files <- list.files(
  folder_path,
  pattern = "\\.txt$",
  full.names = TRUE,
  recursive = TRUE
)

# Enter the keyword dynamically
keyword <- readline(
  prompt = "Enter keyword to search: "
)

# Validate the keyword
if (!nzchar(trimws(keyword))) {
  stop("Please enter a valid keyword.")
}

# Run the Mapper on every document
mapped_results <- do.call(
  rbind,
  lapply(files, mapper, keyword = keyword)
)

# Display results
print(mapped_results)


# QUESTION 1.3: REDUCER FUNCTION

# SHUFFLE AND SORT PHASE

# Group mapped results by document
shuffled_results <- split(
  mapped_results,
  mapped_results$Document
)

# Sort the matches by row and column
shuffled_results <- lapply(
  shuffled_results,
  function(data) {
    data[order(data$Row, data$Column), ]
  }
)

# Display number of matches per document
print(sapply(shuffled_results, nrow))



# QUESTION 1.3: REDUCER FUNCTION

reducer <- function(shuffled_data) {
  
  # Combine the positions for each document
  reduced_results <- lapply(shuffled_data, function(data) {
    
    positions <- paste0(
      "(Row: ", data$Row,
      ", Column: ", data$Column, ")"
    )
    
    paste(positions, collapse = "; ")
  })
  
  return(reduced_results)
}

# Run the Reducer using shuffled results
reduced_results <- reducer(shuffled_results)

# Display final output
print(reduced_results)

# QUESTION 1.4: MAPREDUCE CONFIGURATION

# Define the configuration settings
mapreduce_config <- list(
  
  job_name = "Keyword_Search_MapReduce",
  
  framework = "Hadoop MapReduce",
  
  input_path = folder_path,
  
  output_path = "keyword_search_output",
  
  keyword = keyword,
  
  mapper = "mapper",
  
  reducer = "reducer",
  
  input_format = "TextInputFormat",
  
  output_format = "TextOutputFormat",
  
  num_reduce_tasks = 1L
)

# Display configuration
print(mapreduce_config)






# FINAL OUTPUT: SAVE MAPREDUCE RESULTS

# Convert reduced results into a data frame
final_output <- data.frame(
  Document = names(reduced_results),
  Positions = unlist(reduced_results),
  row.names = NULL
)

# Save the results as a CSV file
output_file <- file.path(
  folder_path,
  "keyword_search_output.csv"
)

write.csv(
  final_output,
  output_file,
  row.names = FALSE
)

# Display final output
print(final_output)

# Confirm where the file was saved
cat("Results saved to:", output_file, "\n")


