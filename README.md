
Text Analysis of a Discord Chat Group
=====================================

Data Acquisition
----------------

To get the data needed for the analysis, there is the [discord api Get Channel Message](https://discordapp.com/developers/docs/resources/channel#get-channel-messages) that one can use or one can try and find a discord bot to do it for you. That requires some setup of the bot so I chose to do bare api calls in python instead. Thanks to [DiscordArchiver](https://github.com/Jiiks/DiscordArchiver/blob/master/DiscordArchiver/Program.cs#L15) for the undocumented (probably old api that may be discontinued on October 16, 2017) url parameter for the token.

After creating `discord_chat_dl.py` and running it with my token, the channel id, and the id of the last message (not included), I downloaded all the chat logs in json. I have also manually anonymized the usernames.
