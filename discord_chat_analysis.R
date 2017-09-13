library(jsonlite)
library(purrr)
library(lubridate)
library(tibble)
library(stringr)
library(tidytext)
library(dplyr)
library(tidyr)
library(magrittr)
library(ggplot2)
library(widyr)
library(igraph)
library(ggraph)

chat_json <- read_json('./discord_chat.json')

timestamps <- map(chat_json, ~.x$timestamp) %>% unlist() %>% ymd_hms()
usernames <- map(chat_json, ~.$author$username) %>% unlist() %>% as.factor()
messages <- map(chat_json, ~.x$content) %>% unlist()

big3 = c('Focu5', 'Caje', 'William') %>% as.factor()

chat <- tibble(timestamap = timestamps, username = usernames, message = messages)

words <- chat %>%
	mutate(message = str_replace(message, 'https?\\S+', '')) %>%
	unnest_tokens(word, message) %>%
	anti_join(stop_words) %>%
	count(username, word) %>%
	ungroup() %>%
	arrange(desc(n))

bigrams <- chat %>%
	mutate(message = str_replace(message, 'https?\\S+', '')) %>%
	unnest_tokens(bigram, message, token = 'ngrams', n = 2) %>%
	separate(bigram, c('word1', 'word2'), sep = ' ') %>%
	filter(!word1 %in% stop_words$word) %>%
	filter(!word2 %in% stop_words$word) %>%
	count(username, word1, word2) %>%
	ungroup() %>%
	arrange(desc(n))

tf_idf <- words %>%
	filter(username %in% big3) %>%
	bind_tf_idf(username, word, n) %>%
	arrange(desc(tf_idf))

tf_idf %>%
	mutate(word = factor(word, levels = rev(unique(word)))) %>%
	filter(tf < 1) %>%
	group_by(username) %>%
	top_n(30) %>%
	ungroup() %>%
	arrange(desc(tf_idf)) %>%
	ggplot(aes(word, tf_idf, fill = username)) +
	geom_col() +
	facet_wrap(~username, ncol = 2, scales = 'free') +
	coord_flip()


words %>%
	pairwise_cor(username, word, n, upper = T) %>%
	filter(correlation > 0.2) %>%
	graph_from_data_frame() %>%
	ggraph(layout = "fr") +
	geom_edge_link(aes(alpha = correlation, width = correlation)) +
	geom_node_point(size = 6, color = "lightblue") +
	geom_node_text(aes(label = name), repel = TRUE, color = 'red') +

words %>%
	pairwise_count(username, word, n, upper = T) %>%
	graph_from_data_frame() %>%
	ggraph(layout = "fr") +
	geom_edge_link(aes(alpha = n, width = n)) +
	geom_node_point(size = 6, color = "lightblue") +
	geom_node_text(aes(label = name), repel = TRUE, color = 'red') +
	theme_void()

bigrams %>%
	select(-username) %>%
	filter(n > 20) %>%
	graph_from_data_frame() %>%
	ggraph(layout = "fr") +
	geom_edge_link(aes(edge_alpha = n), show.legend = FALSE,
		arrow = grid::arrow(type = "closed", length = unit(.15, "inches")),
		end_cap = circle(.07, 'inches')) +
	geom_node_point(color = "lightblue", size = 5) +
	geom_node_text(aes(label = name), vjust = 1, hjust = 1) +
	theme_void()

sentiments_afinn <- words %>%
	inner_join(get_sentiments('afinn'))

sentiments_afinn_count <- sentiments_afinn  %>%
	count(word, score, sort = T) %>%
	ungroup()

sentiments_afinn %>%
	group_by(username) %>%
	summarise(sentiment = sum(score))

sentiments_bing <- words %>%
	inner_join(get_sentiments('bing'))

sentiments_bing %>%
	count(word, sentiment) %>%
	ungroup() %>%
	group_by(sentiment) %>%
	top_n(10) %>%
	ungroup()# %>%
	mutate(word = reorder(word, nn)) %>%
	ggplot(aes(word, nn, fill = score)) +
	geom_col() +
	facet_wrap(~score) +
	coord_flip()

