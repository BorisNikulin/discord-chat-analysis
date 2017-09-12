library(jsonlite)
library(purrr)
library(lubridate)
library(tibble)
library(tidytext)
library(dplyr)
library(magrittr)

chat_json <- read_json('./discord_chat.json')

timestamps <- map(chat_json, ~.x$timestamp) %>% unlist() %>% ymd_hms()
usernames <- map(chat_json, ~.$author$username) %>% unlist()
messages <- map(chat_json, ~.x$content) %>% unlist()

chat <- tibble(timestamap = timestamps, username = usernames, message = messages)

words <- chat %>%
	unnest_tokens(word, message)

bigrams <- chat %>%
	unnest_tokens(bigram, message, token = 'ngrams', n = 2)
