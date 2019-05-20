############################
## Libraries
library(tidytext)
library(dplyr)
library(stringr)
library(dubbR)
library(ggplot2)
library(tidyr)
library(scales)

############################
## Stopwords
# Remove possessives, suffixes and words such as "if" ("ha"), "too" ("is"), "so" ("szóval"), etc.
hu_stopwords <- bind_rows(
  get_stopwords("hu"),
  tibble(
    word = c("is", "ha", "as", "es", "le", "t", "a", "á", "én", "te", "ő", "mi", "ti", "ők", "engem", "téged", "őt", "minket", "titeket",
             "őket", "oké", "szóval", "se"),
    lexicon = c("custom")
  )
)

############################
## Data wrangling
# Create tidy text tibbles
tidy_shows <- NULL
for (i in dub_shows()) {
  tidy_shows <- bind_rows(tidy_shows,
                          dub_text(i) %>%
                            unnest_tokens(word, text) %>%
                            anti_join(
                              dub_characters(i) %>%
                                rename(word = character) %>% 
                                select(word) %>% 
                                mutate(word = tolower(word)) %>% 
                                distinct()
                            ) %>% 
                            anti_join(hu_stopwords) %>% 
                            inner_join(dub_metadata(i)) %>% 
                            select(show, episode, word) %>%
                            mutate(word = str_remove(word, "\\d+")) %>% 
                            filter(word != "")
                          )
}

############################
## Analysis
# Summary, characteristics of the dataset
# Most frequently used words in all episodes of each show - Can we figure out the content of the show?
tidy_shows %>%
  count(show, word, sort = TRUE) %>% 
  group_by(show) %>% 
  top_n(10) %>% 
  arrange(show, -n) %>% 
  ungroup() %>% 
  ggplot(aes(reorder(word, n), n, fill = show)) +
    geom_col(show.legend = FALSE) +
    facet_wrap(~show, scales = "free") +
    labs(x = NULL, y = NULL) +
    coord_flip()

ggsave("assets/term-frequency-per-show.png")

# Most frequently used words in the first 4 episodes of Fifth Gear - Can we help the work of those having to write a synopsis about the episodes?
tidy_shows %>% 
  filter(show == "Fifth Gear", episode %in% c("01", "02", "03", "04"), word != "autó") %>% 
  count(episode, word, sort = TRUE) %>%
  group_by(episode) %>% 
  top_n(10) %>% 
  ungroup() %>%
  mutate(word = reorder(word, n)) %>% 
  ggplot(aes(word, n, fill = episode)) +
    geom_col(show.legend = FALSE) +
    facet_wrap(~episode, scales = "free_y") +
    labs(x = NULL, y  = NULL) +
    coord_flip()

ggsave("assets/term-frequency-first-episodes-of-fifth-gear.png")

# Relative word frequencies for Fifth Gear (cars), Finding Bigfoot (supernatural) and Incredible Engineering Blunders Fixed (engineering)
relative_frequency <- tidy_shows %>% 
  filter(show %in% c("Fifth Gear", "Finding Bigfoot", "Incredible Engineering Blunders Fixed")) %>% 
  select(show, word) %>% 
  count(show, word) %>% 
  group_by(show) %>% 
  mutate(proportion = n / sum(n)) %>% 
  select(-n) %>% 
  spread(show, proportion) %>% 
  gather(show, proportion, `Fifth Gear`:`Finding Bigfoot`)

ggplot(relative_frequency, aes(x = proportion, y = `Incredible Engineering Blunders Fixed`, 
                               color = abs(`Incredible Engineering Blunders Fixed` - proportion))) +
  geom_abline(color = "gray40", lty = 2) +
  geom_jitter(alpha = 0.1, size = 2.5, width = 0.3, height = 0.3) +
  geom_text(aes(label = word), check_overlap = TRUE, vjust = 1.5) +
  scale_x_log10(labels = percent_format()) +
  scale_y_log10(labels = percent_format()) +
  scale_color_gradient(limits = c(0, 0.001), low = "darkslategray4", high = "gray75") +
  facet_wrap(~show, ncol = 2) +
  theme(legend.position="none") +
  labs(y = "Incredible Engineering Blunders Fixed", x = NULL)

ggsave("assets/relative-term-frequency.png")

############################
## Word and document frequency - tf-idf
show_words <- tidy_shows %>% 
  count(show, word, sort = TRUE) %>% 
  ungroup()

total_words <- show_words %>% 
  group_by(show) %>% 
  summarize(total = sum(n))

show_words <- left_join(show_words, total_words)

# Term Distribution
ggplot(show_words, aes(n / total, fill = show)) +
  geom_histogram(show.legend = FALSE) +
  labs(x = NULL, y = NULL) +
  xlim(NA, 0.003) +
  facet_wrap(~show, ncol = 2, scales = "free_y")

ggsave("assets/term-distribution.png")

# tf-idf
show_words <- show_words %>% 
  bind_tf_idf(word, show, n) %>% 
  select(-total) %>% 
  arrange(desc(tf_idf))

show_words %>% 
  mutate(word = factor(word, levels = rev(unique(word)))) %>% 
  group_by(show) %>% 
  top_n(10) %>% 
  ungroup() %>% 
  ggplot(aes(word, tf_idf, fill = show)) +
  geom_col(show.legend = FALSE) +
  labs(x = NULL, y = "tf-idf") +
  facet_wrap(~show, ncol = 2, scales = "free") +
  coord_flip()

ggsave("assets/tf-idf.png")

############################
## Sentiment analysis
# Hungarian sentiments
# The dictionary consists of 1748 positive, and 5940 negative words.
hu_sentiments <- bind_rows(
  read.delim("hu_sentiment/PrecoNeg.txt", header = F, encoding = "UTF-8") %>% 
    mutate(sentiment = -1),
  read.delim("hu_sentiment/PrecoPos.txt", header = F, encoding = "UTF-8") %>% 
    mutate(sentiment = 1)
  ) %>% 
  rename(word = V1)

# Sentiments in all shows
tidy_shows %>% 
  inner_join(hu_sentiments) %>% 
  count(show, word, sentiment, sort = TRUE) %>%
  ungroup() %>% 
  group_by(show) %>% 
  top_n(10) %>%
  ungroup() %>% 
  mutate(word = reorder(word, n)) %>% 
  ggplot(aes(word, n * sentiment, fill = sentiment)) +
  geom_col(show.legend = FALSE) +
  labs(x = NULL, y = NULL) +
  facet_wrap(~show, scales = "free_y") +
  coord_flip()

ggsave("assets/sentiments-in-all-shows.png")

# Sentiments in Fifth Gear
tidy_shows %>% 
  filter(show == "Fifth Gear") %>% 
  inner_join(hu_sentiments) %>% 
  count(word, sentiment) %>% 
  filter(n * sentiment > 20 | n * sentiment < - 20) %>% 
  mutate(word = reorder(word, n)) %>% 
  ggplot(aes(word, n * sentiment, fill = sentiment)) +
    geom_col(show.legend = FALSE) +
    labs(y = "Contribution to sentiment", x = NULL) +
    coord_flip()

ggsave("assets/fifth-gear-sentiments.png")

# Can sentiment analysis predict if they liked the cars in a certain episode?
tidy_shows %>% 
  filter(show == "Fifth Gear", episode %in% c("01", "02", "03", "04"), word != "autó") %>% 
  inner_join(hu_sentiments) %>% 
  count(episode, word, sentiment) %>% 
  group_by(episode) %>% 
  top_n(10) %>% 
  ungroup() %>% 
  mutate(word = reorder(word, n)) %>% 
  ggplot(aes(word, n * sentiment, fill = sentiment)) +
    geom_col(show.legend = FALSE) +
    facet_wrap(~episode, scales = "free_y") +
    labs(y = "Contribution to sentiment", x = NULL) +
    coord_flip()

ggsave("assets/fifth-gear-episode-sentiments.png")
