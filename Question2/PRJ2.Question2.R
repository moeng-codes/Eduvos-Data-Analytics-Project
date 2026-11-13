
# ==================================================
# QUESTION 2.1: LOAD NEWS ARTICLES
# ==================================================

# Select any text file inside the extracted news folder
folder_path <- dirname(file.choose())

# Find all text files
news_files <- list.files(
  folder_path,
  pattern = "\\.txt$",
  full.names = TRUE,
  recursive = TRUE
)

# Read the content of each article
news_content <- sapply(news_files, function(file) {
  paste(
    readLines(file, warn = FALSE),
    collapse = " "
  )
}, USE.NAMES = FALSE)

# Create the required data frame
news_df <- data.frame(
  file_name = basename(news_files),
  content = news_content,
  stringsAsFactors = FALSE
)

# Display the data frame
print(news_df)

# Check the number of articles
cat("Total news articles:", nrow(news_df), "\n")




# Check the structure
str(news_df)

# Display the first few records
head(news_df)

# Open the table in RStudio
View(news_df)


# TEXT PREPROCESSING
library(stringr)

# Convert text to lowercase
news_df$clean_content <- tolower(news_df$content)

# Remove website links
news_df$clean_content <- str_replace_all(
  news_df$clean_content,
  "https?://\\S+|www\\.\\S+",
  " "
)

# Remove punctuation and numbers
news_df$clean_content <- str_replace_all(
  news_df$clean_content,
  "[^a-z\\s]",
  " "
)

# Remove extra spaces
news_df$clean_content <- str_squish(
  news_df$clean_content
)

install.packages("tm")

# Load stopwords
stop_words <- tm::stopwords("english")

# Remove stopwords while preserving word boundaries
news_df$clean_content <- vapply(
  news_df$clean_content,
  function(text) {
    
    words <- str_split(text, "\\s+")[[1]]
    
    words <- words[
      nzchar(words) & !(words %in% stop_words)
    ]
    
    paste(words, collapse = " ")
  },
  character(1)
)


#VERIFYING PREPROCESSING

# Compare original and cleaned content
comparison <- data.frame(
  file_name = news_df$file_name,
  original = substr(news_df$content, 1, 100),
  cleaned = substr(news_df$clean_content, 1, 100)
)

# Display comparison
print(comparison)

# Check for empty documents
cat("Empty documents:",
    sum(!nzchar(news_df$clean_content)), "\n")

# Display cleaned data frame
View(news_df)


# Count words remaining in each article
word_counts <- vapply(
  news_df$clean_content,
  function(text) {
    if (!nzchar(text)) return(0L)
    length(strsplit(text, "\\s+")[[1]])
  },
  integer(1)
)

# Display word counts per article
data.frame(
  file_name = news_df$file_name,
  word_count = word_counts
)



# QUESTION 2.2

# Install once if needed
install.packages(c("topicmodels", "tidytext"))

# Load packages
library(tm)
library(topicmodels)
library(tidytext)
library(dplyr)


# Create a text corpus from cleaned articles
news_corpus <- VCorpus(
  VectorSource(news_df$clean_content)
)

# Create Document-Term Matrix
dtm <- DocumentTermMatrix(
  news_corpus,
  control = list(
    wordLengths = c(2, Inf)
  )
)

# Remove empty documents if any
dtm <- dtm[row_sums(dtm) > 0, ]

# Display DTM information
inspect(dtm[1:min(5, nrow(dtm)), ])

dim(dtm)


# Set number of topics
n_topics <- 3

# Fit the LDA model
set.seed(123)

lda_model <- LDA(
  dtm,
  k = n_topics,
  method = "Gibbs",
  control = list(
    seed = 123,
    burnin = 500,
    iter = 1500,
    thin = 100
  )
)

# Display model summary
lda_model


# Extract topic-word probabilities
topic_words <- tidy(
  lda_model,
  matrix = "beta"
)

# Select the top 10 words per topic
top_words <- topic_words |>
  group_by(topic) |>
  slice_max(beta, n = 10, with_ties = FALSE) |>
  arrange(topic, desc(beta))

# Display results
print(top_words, n = 30)


# 

# Extract topic probabilities per document
document_topics <- tidy(
  lda_model,
  matrix = "gamma"
)

# Display the probabilities
print(document_topics, n = 30)

# Identify the dominant topic for each document
dominant_topics <- document_topics |>
  group_by(document) |>
  slice_max(gamma, n = 1, with_ties = FALSE) |>
  ungroup()

# Display dominant topics
print(dominant_topics)




# QUESTION 2.3: BAR CHART

library(ggplot2)

ggplot(
  top_words,
  aes(
    x = reorder_within(term, beta, topic),
    y = beta,
    fill = factor(topic)
  )
) +
  geom_col(show.legend = FALSE) +
  facet_wrap(~ topic, scales = "free") +
  coord_flip() +
  scale_x_reordered() +
  labs(
    title = "Top 10 Keywords per LDA Topic",
    x = "Keywords",
    y = "Word Probability (Beta)"
  ) +
  theme_minimal()


install.packages("wordcloud")


# QUESTION 2.3: WORD CLOUDS
library(wordcloud)

# Display one word cloud for each topic
par(mfrow = c(1, 3))

for (i in 1:n_topics) {
  
  topic_data <- top_words |>
    filter(topic == i)
  
  wordcloud(
    words = topic_data$term,
    freq = topic_data$beta,
    max.words = 10,
    random.order = FALSE,
    scale = c(3, 0.8)
  )
  
  title(main = paste("Topic", i))
}

# Restore default plot layout
par(mfrow = c(1, 1))


# Match document numbers to filenames
dominant_topics$file_name <- news_df$file_name[
  as.integer(dominant_topics$document)
]

# Display results with filenames
print(
  dominant_topics[, c(
    "file_name", "topic", "gamma"
  )]
)



