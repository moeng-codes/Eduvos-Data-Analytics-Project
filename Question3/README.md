# Question 3 -- Web Scraping and Text Summarisation

This folder contains the R scripts and supporting documentation for extracting, preprocessing and summarising textual data from a website.
TF-IDF-based summarisation: Selected three sentences using TF-IDF scores.

## Overview
This analysis uses R to extract, preprocess and summarise textual information from a WorldAtlas article about pollution.

**Source:** https://www.worldatlas.com/articles/what-is-pollution.html

## 3.1 Web Scraping
- Extracted five relevant paragraphs using `rvest`.
- Organised the extracted content into a data frame.

## 3.2 Text Preprocessing
- Converted text to lowercase.
- Removed punctuation, numbers and stop words.
- Tokenised the text for further analysis.
- Verified the cleaned paragraphs.

## 3.3 Extractive Summarisation
Applied two summarisation techniques:
1. **Word-frequency-based summarisation:** Selected three sentences based on frequent terms.
2. **TF-IDF-based summarisation:** Selected three sentences using TF-IDF scores.

## Results and Visualisations
- Analysed 30 sentences from the article.
- Generated a bar chart showing the 15 most frequent words.
- Visualised the TF-IDF scores of the selected summary sentences.

## Interpretation
The frequency-based method emphasised recurring pollution concepts, while TF-IDF identified sentences containing more distinctive terms. Both techniques provided different perspectives on the article's content.

## Project Files
- `PRJ2.Question3.R` 
- `website link`
## Tools Used
R, RStudio, rvest, dplyr, stringr, tidytext and ggplot2.
