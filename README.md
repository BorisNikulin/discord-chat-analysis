
Text Analysis of a Discord Chat Group
=====================================

Thanks to the Editor
--------------------

A large thank you to [William Zhu](https://github.com/ZhuWilliam) for editing this poorly written document into something nice.

Data Acquisition
----------------

To get the data needed for analysis, there are two methods. First is the discord api's [Get Channel Message](https://discordapp.com/developers/docs/resources/channel#get-channel-messages) to manually retrieve the messages. The second, is to get a discord bot to do it for you. However, if you do not wish to setup a bot, you can use the first method to do bare api calls in python.

Big thanks to [DiscordArchiver](https://github.com/Jiiks/DiscordArchiver/blob/master/DiscordArchiver/Program.cs#L15) for the undocumented (and probably old api that may be discontinued on October 16, 2017) url parameter for the token.

After creating `discord_chat_dl.py` and running it with the token, the channel id, and the id of the last message, you can download all of the chat logs in a json format.

Data Import
-----------

``` r
library(jsonlite)

chat_json <- read_json('discord_chat_anonymized.json')
```

This imports the json chat log as an R list. However, the list is not uniform in fields across message entries as some messages have reactions, a feature introduced later in Discord's development that messages before the update do not have. This inconsistency prevents running the list into `data.table::rbindlist`, so I used an alternative method. I extracted the relevant fields with [purrr](https://cran.r-project.org/web/packages/purrr/vignettes/other-langs.html) and then stitched it back together into a [data.table](https://cran.r-project.org/web/packages/data.table/vignettes/datatable-intro.html). I then checked the result with [dplyr's](https://cran.r-project.org/web/packages/dplyr/vignettes/dplyr.html) glimpse.

``` r
library(purrr)
library(lubridate)
library(data.table)
library(dplyr)
library(dtplyr)

timestamps <- map(chat_json, ~.x$timestamp) %>% unlist() %>% ymd_hms()
usernames <- map(chat_json, ~.x$author$username) %>% unlist() %>% as.factor()
messages <- map(chat_json, ~.x$content) %>% unlist()

chat <- data.table(timestamp = timestamps, username = usernames, message = messages)

glimpse(chat)
```

    ## Observations: 245,977
    ## Variables: 3
    ## $ timestamp <dttm> 2017-09-12 08:03:34, 2017-09-12 08:03:17, 2017-09-1...
    ## $ username  <fctr> Benjamin, Benjamin, Benjamin, Benjamin, Wallace, Be...
    ## $ message   <chr> "although the rate limits are probably the most *rat...

Data Tidying
------------

### Word Tokenization

To convert the `chat` data.table into a more convienient [tidy format](http://tidytextmining.com/tidytext.html), with one token per row, we can use [tidytext](https://cran.r-project.org/web/packages/tidytext/vignettes/tidytext.html). URLs, long digits, and common words can cause problems, but they can be filtered out with regex and tidytext's `stop_words`. We also filtered out users who did not message a lot.

``` r
library(magrittr) # for %<>% (originator of %>%)
library(stringr)
library(tidytext)

chat %<>%
    .[username %in% c('Benjamin', 'Wallace', 'Michael', 'Molly', 'Peter')] %>%
    .[, message := str_replace(message, '(https?\\S+)|(\\d{4,})', '')]

words <- chat %>%
    unnest_tokens(word, message) %>%
    .[!data.table(stop_words), on = 'word'] # anti join

glimpse(words)
```

    ## Observations: 371,074
    ## Variables: 3
    ## $ timestamp <dttm> 2017-09-12 08:03:34, 2017-09-12 08:03:34, 2017-09-1...
    ## $ username  <fctr> Benjamin, Benjamin, Benjamin, Benjamin, Benjamin, B...
    ## $ word      <chr> "rate", "limits", "rate", "limiting", "goodbye", "pe...

### Bigram Tokenization

Next, we prepare the tokenization of bigrams in much the same fashion as for words by using `unnest_tokens`, followed by [tidyr's](https://cran.r-project.org/web/packages/tidyr/vignettes/tidy-data.html) separate, and finally removing common words.

``` r
library(tidyr)

bigrams <- chat %>%
    unnest_tokens(bigram, message, token = 'ngrams', n = 2) %>%
    data.table() %>% # unnest tokens on words returns the same structure but on bigrams it returns a tibble
    separate(bigram, c('word1', 'word2'), sep = ' ') %>%
    .[!word1 %in% stop_words$word & !word2 %in% stop_words$word,]

glimpse(bigrams)
```

    ## Observations: 105,642
    ## Variables: 4
    ## $ timestamp <dttm> 2017-09-12 08:03:34, 2017-09-12 08:03:34, 2017-09-1...
    ## $ username  <fctr> Benjamin, Benjamin, Benjamin, Benjamin, Benjamin, W...
    ## $ word1     <chr> "rate", "rate", "ive", "total", "14gb", "python", "d...
    ## $ word2     <chr> "limits", "limiting", "reached", "ram", "15.6gb", "d...

Data Analysis
-------------

### Word Counts

``` r
word_counts <- words %>%
    .[, .N, .(username, word)] %>%
    setorder(-N)

word_counts[, head(.SD, 3), username]
```

    ##     username   word    N
    ##  1: Benjamin    lol 4148
    ##  2: Benjamin   yeah 1418
    ##  3: Benjamin      1 1391
    ##  4:  Wallace     im 2005
    ##  5:  Wallace   dont 1515
    ##  6:  Wallace    lol 1346
    ##  7:  Michael    lol 1192
    ##  8:  Michael   yeah  514
    ##  9:  Michael     uh  221
    ## 10:    Molly    lol  278
    ## 11:    Molly   yeah   78
    ## 12:    Molly people   31
    ## 13:    Peter   yeah   37
    ## 14:    Peter people   17
    ## 15:    Peter   guys   17

### Bigram Counts

``` r
bigram_counts <- bigrams %>%
    .[, .N, .(username, word1, word2)] %>%
    setorder(-N)

bigram_counts[, head(.SD, 3), username]
```

    ##     username    word1       word2   N
    ##  1:  Wallace     holy        shit 331
    ##  2:  Wallace       im       gonna 131
    ##  3:  Wallace        2           3  80
    ##  4: Benjamin      1st          qu  96
    ##  5: Benjamin      3rd          qu  96
    ##  6: Benjamin      min         1st  93
    ##  7:  Michael     page       table  37
    ##  8:  Michael        0           0  19
    ##  9:  Michael    gonna        head  16
    ## 10:    Molly   dragon         age   6
    ## 11:    Molly      web programming   4
    ## 12:    Molly personal     project   4
    ## 13:    Peter       11          10   3
    ## 14:    Peter        2           3   3
    ## 15:    Peter      red      weapon   3
