# Text and sentiment analysis of Hungarian scripts
Term Project for *Data Science 4: Unstructured Text Analysis* at CEU, Budapest. It leverages the outputs of the [dubbR package](https://github.com/szigony/dubbR) that I created for this specific use-case.

#### Table of contents

- [Goal of the analysis](#goal-of-the-analysis)
- [About the data](#about-the-data)
- [About the package](#about-the-package)
- [Term frequency analysis](#term-frequency-analysis)
  - [Exploration](#exploration)
  - [Relative term frequency](#relative-term-frequency)
  - [Tf-idf](#tf-idf)
- [Sentiment analysis](#sentiment-analysis)
- [Summary](#summary)
- [Recommendations](#recommendations)

## Goal of the analysis

The goal of this analysis is to see how well the topics of certain scripts written for the Hungarian Discovery Channel can be used to identify the contents of a show. Would it be possible for a tech-savvy intern at one of the production companies to "take the lazy way" and write the synopsis for certain episodes merely based on term frequency analysis? I'm also looking into the Hungarian Sentiment Lexicon created by Szabó (2014) to see if it can be used to perform meaningful text analysis. Can we determine based on the scripts whether for example the outcome of a car test is positive or negative? These are the questions I'm attempting to answer.

## About the data

Between August 2014 and February 2016 I worked for Mafilm Audio as an audiovisual translator, writing Hungarian dubs for TV shows that aired on Discovery Channel or one of its sister channels (TLC, Animal Planet etc.). Little did I know back then, but the seemingly strict formal requirements came in handy when looking for a project for a course at CEU.

I had written exactly 100 scripts, all with the same format - timestamp, character and text within several tables per script. For this excercise, I ended up using 52 scripts from 7 TV shows with different topics:

- **Backroad Bounty** - Two guys looking for treasure in other people's junk, bidding on various items.
- **Ed Stafford Into the Unknown** - Ed Stafford wandering around the globe, looking for mysterious places and adventures.
- **Fifth Gear** - Your tipical motor magazine with car tests.
- **Finding Bigfoot** - A team in search of the mysterious creature called Bigfoot.
- **Fire in the Hole** - An explosives expert... blowing stuff up.
- **Incredible Engineering Blunders Fixed** - Looking for engineering "miracles" in the worst possible sense of the word.
- **Misfit Garage** - Pimp My Ride style garage with lots of rivalry.

## About the package

I created the [dubbR package](https://github.com/szigony/dubbR) to bring my scripts into a format that's convenient for text analysis - for a more detailed description about functionalities, please visit the aforementioned link.

The package loads all the scripts in their original format with the help of the `read_docx` function from the `docxtractr` package. It dissects the input file names and creates a metadata tibble by utilizing the `str_extract` function with RegEx, as well as the `str_replace` function from the `stringr` package. For ease of identification, it also automatically assigns a `dub_id` for each script. Initially, there are three tibbles created that later serve as inputs for the functions within the package, these are: `dubbr_metadata`, `dubbr_text` and `dubbr_characters`.

**Functions:**

- `dub_shows()` - Returns the list of shows that are available in the package. This can be used to identify which shows we'd like to filter on for the other functions, if we'd like to limit our dataset.
- `dub_metadata()` - Metadata about the audiovisual translations (`dub_id`, `production_code`, `show`, `season` and `episode`).
- `dub_text()` - The text of the scripts with `dub_id` and `text`.
- `dub_characters()` - The characters that appear in the different shows. This can be used for `anti_join`s to remove character names that would disturbe the analysis.

## Term frequency analysis

> **The full code can be found in the [text-analysis.R](text-analysis.R) file.**

- I used the following packages to perform the analysis: `tidytext`, `dplyr`, `stringr`, `ggplot2`, `tidyr` and `scales`, as well as my own `dubbR` package.
  
- In addition to the Hungarian stopwords from the `tidytext` package, I included my custom list with possessives, suffixes and words such as "ha" (*if*), "is" (*too*), "szóval" (*so*), etc.

  ```r
  hu_stopwords <- bind_rows(
    get_stopwords("hu"),
    tibble(
      word = c("is", "ha", "as", "es", "le", "t", "a", "á", "én", "te", "ő", "mi", "ti", "ők", "engem", "téged", "őt", "minket", "titeket",
               "őket", "oké", "szóval", "se"),
      lexicon = c("custom")
    )
  )
  ```

- Since I'd like to perform analysis on all available shows, I looped through the results of `dub_shows()` and created a `tidy_shows` tibble that leverages `unnest_tokens` on the filtered results of `dub_text()` and gets rid of all the character names by `anti_join`ing the filtered set of `dub_characters()` on `dub_id`. I also removed the stopwords, and joined the filtered `dub_metadata()` set to maintain information about which show and which episode a certain word belonges to. Since cars in Fifth Gear tend to have numbers in their names, I removed these as well.

### Exploration

I started with a simple term frequency for each of the shows to see if it approximates the topics properly.

![alt text](assets/term-frequency-per-show.png "Term Frequency per Show")

### Relative term frequency

### Tf-idf

## Sentiment analysis

## Summary

## Recommendations
