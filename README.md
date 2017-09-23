
Text Analysis of a Discord Chat Group
=====================================

Data Acquisition
----------------

To get the data needed for the analysis, there is the [discord api Get Channel Message](https://discordapp.com/developers/docs/resources/channel#get-channel-messages) that one can use or one can try and find a discord bot to do it for you. That requires some setup of the bot so I chose to do bare api calls in python instead. Thanks to [DiscordArchiver](https://github.com/Jiiks/DiscordArchiver/blob/master/DiscordArchiver/Program.cs#L15) for the undocumented (probably old api that may be discontinued on October 16, 2017) url parameter for the token.

After creating `discord_chat_dl.py` and running it with my token, the channel id, and the id of the last message (not included), I downloaded all the chat logs in json. I have also manually anonymized the usernames.

Data Import
-----------

``` r
library(jsonlite)

chat_json <- read_json('discord_chat_anonymized.json')
```

This imports the json chat log as a and R list. However, the list is not uniform in fields across message entries as some messages have reactions or are missing the field entriely. This prevents running the R json list into `data.table::rbindlist` to quickly convert convert the json into a data.frame like structure for processing. Therefore I extracted the relavent fields with [purrr](https://cran.r-project.org/web/packages/purrr/vignettes/other-langs.html) and then stiched it back together into a [data.table](https://cran.r-project.org/web/packages/data.table/vignettes/datatable-intro.html). I did not use a [tibble](https://cran.r-project.org/web/packages/tibble/vignettes/tibble.html) because I am trying to get familiar with data.table. The initial code in `discord_chat_analysis.R` uses tibbles and dplyr if you want to see that. Then I checked the result with [dplyr's](https://cran.r-project.org/web/packages/dplyr/vignettes/dplyr.html) glimpse.

``` r
library(purrr)
library(lubridate)
library(data.table)
library(dplyr)

timestamps <- map(chat_json, ~.x$timestamp) %>% unlist() %>% ymd_hms()
usernames <- map(chat_json, ~.x$author$username) %>% unlist() %>% as.factor()
messages <- map(chat_json, ~.x$content) %>% unlist()

chat <- data.table(timestamap = timestamps, username = usernames, message = messages)

glimpse(chat)
```

    ## Observations: 245,977
    ## Variables: 3
    ## $ timestamap <dttm> 2017-09-12 08:03:34, 2017-09-12 08:03:17, 2017-09-...
    ## $ username   <fctr> Benjamin, Benjamin, Benjamin, Benjamin, Wallace, B...
    ## $ message    <chr> "although the rate limits are probably the most *ra...

Data Anlysis
------------

### Text Tokenization

The first step in analyisis is to convert the `chat` data.table into a more convienient [tidy format](http://tidytextmining.com/tidytext.html) with one token per row. This will be done with [tidytext](https://cran.r-project.org/web/packages/tidytext/vignettes/tidytext.html). I will also filter out urls and long digits I discovered later along with anti joining with tidytext's `stop_words`.

``` r
library(magrittr) # for %<>% (originator of %>%)
library(stringr)
library(tidytext)

chat[, message := str_replace(message, '(https?\\S+)|(d{4,})', '')]

words <- chat %>%
    unnest_tokens(word, message) %>%
    .[!data.table(stop_words), on = "word"] %>% # anti join
    .[, .N, .(username, word)] %>%
    .[order(-N)]

glimpse(words)
```

    ## Observations: 56,564
    ## Variables: 3
    ## $ username <fctr> Benjamin, Wallace, Wallace, Benjamin, Benjamin, Benj...
    ## $ word     <chr> "lol", "im", "dont", "yeah", "1", "im", "lol", "1", "...
    ## $ N        <int> 4148, 2005, 1515, 1418, 1386, 1378, 1346, 1336, 1311,...
