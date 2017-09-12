import sys
import time
import requests
import json

api_endpoint = 'https://discordapp.com/api/channels/{}/messages'
message_limit = 100 # 1 - 100 by discord api

def main():
    if(sys.argv[1] == '-h' or sys.argv[1] == '--help' or len(sys.argv) == 1):
        print_help()
    else:
        global api_endpoint
        api_endpoint = api_endpoint.format(sys.argv[2])
        json_log_list = dl_chat()
        with open('discord_chat.json', 'w') as f:
            json.dump(json_log_list, f, indent=4)

def print_help():
    print('Usage: {} [token] [channelId] [lastMessageId]'.format(sys.argv[0]))

def dl_chat():
    params = {'token': sys.argv[1], 'before': sys.argv[3], 'limit': message_limit}
    r = requests.get(api_endpoint, params=params)
    json_log_list = r.json()
    while is_good_response(r) and len(r.json()) > 0:
        params['before'] = get_next_message_id(r)
        r = requests.get(api_endpoint, params=params)
        # is_rate_limited should block long enough
        # could be an if but might as well double check
        while is_rate_limited(r):
            print('\nrate limited\n')
            r = requests.get(api_endpoint, params=params)
        json_log_list += r.json()
        print('list length is {:d} and http status is {:d}'.format(len(json_log_list), r.status_code))
    return json_log_list

def is_good_response(response):
    """not at the end of the messages and http status good/rate limited?"""
    return ((response.status_code == requests.codes.ok or
            response.status_code == requests.codes.too_many_requests) and
            len(response.json()) == message_limit)

def is_rate_limited(response):
    """blocks for necessary ammount as well"""
    # -1 if globaly rate limited (but not used) (handled by too many requests status)
    remaining_requests = response.headers.get('X-RateLimit-Remaining', -1)
    if remaining_requests == 0:
        time.sleep(response.headers['Retry-After'])
        return True
    elif response.status_code == requests.codes.too_many_requests:
        time.sleep(response.json()['retry_after'])
        return True
    return False

def get_next_message_id(response):
    """get's the next message id (most earliest)
    assumes there is at least one message
    which the while loop ensures"""
    # messages should be in reverse chronological order so next id is the last message
    return response.json()[-1]['id']

if __name__ == '__main__':
    main()
