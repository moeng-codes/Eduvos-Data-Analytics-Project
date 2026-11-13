# QUESTION 3.1: WEB TEXT EXTRACTION

library(rvest)
library(dplyr)
library(stringr)

# Specify the article URL
url <- "https://www.worldatlas.com/articles/what-is-pollution.html"

# Read the webpage
webpage <- read_html(url)

# Extract paragraph text
paragraphs <- webpage |>
  html_elements("p") |>
  html_text2()

# Check the extracted text
head(paragraphs)


# Remove copyright and non-article information
article_paragraphs <- paragraphs[
  !grepl("All maps, graphics, flags",
         paragraphs,
         ignore.case = TRUE)
]

# Remove empty paragraphs
article_paragraphs <- article_paragraphs[
  nzchar(trimws(article_paragraphs))
]

# Create an R data frame
web_df <- data.frame(
  paragraph_id = seq_along(article_paragraphs),
  content = article_paragraphs,
  stringsAsFactors = FALSE
)

# Display the data frame
View(web_df)

# Check the dimensions
dim(web_df)

# Check the structure
str(web_df)



# QUESTION 3.2: TEXT PREPROCESSING
library(dplyr)
library(stringr)
library(tm)

# Load English stopwords
stop_words <- tm::stopwords("english")

# Check the stopwords
head(stop_words)


# Create a new column for cleaned text
web_df$clean_content <- web_df$content

# Convert text to lowercase
web_df$clean_content <- str_to_lower(
  web_df$clean_content
)

# Remove URLs
web_df$clean_content <- str_remove_all(
  web_df$clean_content,
  "https?://\\S+|www\\.\\S+"
)

# Remove HTML tags, if present
web_df$clean_content <- str_remove_all(
  web_df$clean_content,
  "<[^>]+>"
)

# Remove punctuation and special characters
web_df$clean_content <- str_replace_all(
  web_df$clean_content,
  "[^a-z\\s]",
  " "
)

# Remove extra whitespace
web_df$clean_content <- str_squish(
  web_df$clean_content
)


# Remove stopwords while preserving word boundaries

web_df$clean_content <- vapply(
  web_df$clean_content,
  function(text) {
    
    # Split text into individual words
    words <- str_split(text, "\\s+")[[1]]
    
    # Remove empty words and stopwords
    words <- words[
      nzchar(words) & !(words %in% stop_words)
    ]
    
    # Recombine remaining words
    paste(words, collapse = " ")
  },
  character(1)
)


# Display the updated data frame
View(web_df)

# Check dimensions
dim(web_df)

# Check structure
str(web_df)

# Preview cleaned text
head(web_df$clean_content)

# Check for empty paragraphs
cat(
  "Empty paragraphs:",
  sum(!nzchar(web_df$clean_content)),
  "\n"
)



# Compare original and cleaned text

comparison <- data.frame(
  paragraph_id = web_df$paragraph_id,
  original_words = str_count(
    str_squish(web_df$content),
    "\\S+"
  ),
  cleaned_words = str_count(
    web_df$clean_content,
    "\\S+"
  )
)

# Calculate words removed
comparison$words_removed <-
  comparison$original_words -
  comparison$cleaned_words

# Display comparison
print(comparison)


# QUESTION 3.3: TEXT SUMMARISATION
library(dplyr)
library(stringr)
library(tidytext)
library(ggplot2)

# Combine all five paragraphs into one article
article_text <- paste(
  web_df$content,
  collapse = " "
)

# Split the article into individual sentences
sentences_df <- data.frame(
  sentence_id = seq_along(
    unlist(str_split(
      article_text,
      "(?<=[.!?])\\s+(?=[A-Z])"
    ))
  ),
  sentence = unlist(str_split(
    article_text,
    "(?<=[.!?])\\s+(?=[A-Z])"
  )),
  stringsAsFactors = FALSE
)

# Remove empty sentences
sentences_df <- sentences_df |>
  filter(nzchar(str_trim(sentence)))

# Display the number of sentences
cat(
  "Total sentences:",
  nrow(sentences_df),
  "\n"
)

# Preview the first sentences
head(sentences_df)



# Tokenise sentences into individual words
sentence_words <- sentences_df |>
  unnest_tokens(word, sentence, drop = FALSE) |>
  filter(
    !word %in% stop_words,
    str_detect(word, "^[a-z]+$"),
    nchar(word) > 1
  )

# Display tokenised words
head(sentence_words)

# Count word frequencies
word_frequency <- sentence_words |>
  count(word, sort = TRUE)

# Display the 15 most frequent words
head(word_frequency, 15)




# TECHNIQUE 1: WORD-FREQUENCY SUMMARISATION
# Calculate sentence scores
frequency_scores <- sentence_words |>
  left_join(
    word_frequency,
    by = "word"
  ) |>
  group_by(sentence_id, sentence) |>
  summarise(
    score = mean(n),
    .groups = "drop"
  )

# Select the top 3 sentences
frequency_summary <- frequency_scores |>
  slice_max(
    score,
    n = 3,
    with_ties = FALSE
  ) |>
  arrange(sentence_id)

# Display the summary
cat("\nWORD-FREQUENCY SUMMARY\n\n")

for (i in seq_len(nrow(frequency_summary))) {
  cat(frequency_summary$sentence[i], "\n\n")
}



# TECHNIQUE 2: TF-IDF SUMMARISATION

tfidf_summary <- tfidf_summary |>
  dplyr::select(
    sentence_id,
    sentence = sentence.x,
    score
  )

# Display the summary
print(tfidf_summary)

# Print the three selected sentences
cat("\nTF-IDF SUMMARY\n\n")

for (i in seq_len(nrow(tfidf_summary))) {
  cat(i, ".", tfidf_summary$sentence[i], "\n\n")
}





# Check the TF-IDF summary
print(tfidf_summary)

# Check column names
names(tfidf_summary)

# View the summary in RStudio
View(tfidf_summary)







# QUESTION 3.3: VISUALISATION 1
# Most frequent words in the pollution article

library(ggplot2)
library(dplyr)

top_15_words <- word_frequency |>
  slice_max(n, n = 15, with_ties = FALSE)

ggplot(
  top_15_words,
  aes(x = reorder(word, n), y = n)
) +
  geom_col(fill = "steelblue") +
  coord_flip() +
  labs(
    title = "Top 15 Most Frequent Words in the Pollution Article",
    subtitle = "Word-frequency analysis of cleaned web text",
    x = "Words",
    y = "Frequency"
  ) +
  theme_minimal()



# QUESTION 3.3: VISUALISATION 2
# TF-IDF sentence importance

library(ggplot2)
library(dplyr)

# Prepare the selected sentences for plotting
tfidf_plot <- tfidf_summary |>
  mutate(
    sentence_label = paste("Sentence", sentence_id)
  )

# Create the TF-IDF bar chart
ggplot(
  tfidf_plot,
  aes(
    x = reorder(sentence_label, score),
    y = score
  )
) +
  geom_col(fill = "darkcyan", width = 0.6) +
  geom_text(
    aes(label = round(score, 3)),
    hjust = -0.15,
    size = 4
  ) +
  coord_flip() +
  scale_y_continuous(
    limits = c(0, max(tfidf_plot$score) * 1.15)
  ) +
  labs(
    title = "TF-IDF Scores of Selected Summary Sentences",
    subtitle = "Extractive summarisation of the pollution article",
    x = "Selected Sentences",
    y = "TF-IDF Importance Score"
  ) +
  theme_minimal()
