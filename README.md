
Text Analysis of a Discord Chat Group
=====================================

Thanks to the Editor
--------------------

A large thank you to [William Zhu](https://github.com/ZhuWilliam) for editing this poorly written document into something nice.

Data Acquisition
----------------

To get the data needed for analysis, there are two methods. First is the discord api's [Get Channel Message](https://discordapp.com/developers/docs/resources/channel#get-channel-messages) to manually retrieve, or a discord bot to do it for you. However, if you do not wish to setup a bot, you can also use the second method, bare api calls in python.

Big thanks to [DiscordArchiver](https://github.com/Jiiks/DiscordArchiver/blob/master/DiscordArchiver/Program.cs#L15) for the undocumented (and probably old api that may be discontinued on October 16, 2017) url parameter for the token.

After creating `discord_chat_dl.py` and running it with the token, the channel id, and the id of the last message, you can download all of the chat logs in a json format.

Data Import
-----------

``` r
library(jsonlite)

chat_json <- read_json('discord_chat_anonymized.json')
```

This imports the json chat log as an R list. However, the list is not uniform in fields across message entries as some messages have reactions, a feature introduced later in Discord's development that messages before the update do not have. This inconsistency prevents running the list into `data.table::rbindlist`, so I used an alternative. I extracted the relevant fields with [purrr](https://cran.r-project.org/web/packages/purrr/vignettes/other-langs.html) and then stitched it back together into a [data.table](https://cran.r-project.org/web/packages/data.table/vignettes/datatable-intro.html). I then checked the result with [dplyr's](https://cran.r-project.org/web/packages/dplyr/vignettes/dplyr.html) glimpse.

``` r
library(purrr)
library(lubridate)
library(data.table)
library(dplyr)

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

Data Analysis
-------------

### Word Tokenisation

To convert the `chat` data.table into a more convienient [tidy format](http://tidytextmining.com/tidytext.html), with one token per row, we can use [tidytext](https://cran.r-project.org/web/packages/tidytext/vignettes/tidytext.html). URLs, long digits, and common words can cause problems, but they can be filtered out with regex and tidytext's `stop_words`.

``` r
library(stringr)
library(tidytext)

chat[, message := str_replace(message, '(https?\\S+)|(d{4,})', '')]

words <- chat %>%
    unnest_tokens(word, message) %>%
    .[!data.table(stop_words), on = 'word', .(timestamp, username, word)] %>% # anti join
    .[, .N, .(username, word)] %>%
    setorder(-N)

glimpse(words)
```

    ## Observations: 56,564
    ## Variables: 3
    ## $ username <fctr> Benjamin, Wallace, Wallace, Benjamin, Benjamin, Benj...
    ## $ word     <chr> "lol", "im", "dont", "yeah", "1", "im", "lol", "1", "...
    ## $ N        <int> 4148, 2005, 1515, 1418, 1386, 1378, 1346, 1336, 1311,...

``` r
words[, head(.SD, 3), username]
```

    ##      username               word    N
    ##  1:  Benjamin                lol 4148
    ##  2:  Benjamin               yeah 1418
    ##  3:  Benjamin                  1 1386
    ##  4:   Wallace                 im 2005
    ##  5:   Wallace               dont 1515
    ##  6:   Wallace                lol 1346
    ##  7:   Michael                lol 1192
    ##  8:   Michael               yeah  514
    ##  9:   Michael                 uh  221
    ## 10:     Molly                lol  278
    ## 11:     Molly               yeah   78
    ## 12:     Molly             people   31
    ## 13:     Peter               yeah   37
    ## 14:     Peter             people   17
    ## 15:     Peter               guys   17
    ## 16:     Aiden              books    8
    ## 17:     Aiden                 cs    3
    ## 18:     Aiden                kms    2
    ## 19: Catherine            patrick    6
    ## 20: Catherine              phone    4
    ## 21: Catherine               fell    2
    ## 22:     RNBot             server    5
    ## 23:     RNBot 147952204735709184    5
    ## 24:     RNBot             rolled    5
    ## 25:     Henry                hes    1
    ## 26:     Henry             rocket    1
    ## 27:     Henry             league    1
    ## 28:    Antwon                 im    1
    ## 29:      LBot            lewdbot    1
    ## 30:      LBot              learn    1
    ##      username               word    N

### Bigram Tokenisation
