# Funbunn

Polls for new subreddit posts using `https://reddit.com/r/new/<subreddit>.json` and forwards it to a webhook (Currently supports Discord)

To run

1. grab the `build.zip` from the latest release and unzip it
2. Quickest way to get started is to run 

    WEBHOOK_ROUTE_CONFIG_PATH="<absolute path to config>.json" ./bin/poll


## Environment variables

* `STORE`  - decides how to store the state of the app. Options are
  - `inmemory` (default) - use in memory store
  - `disk` - writes state into disk. Requires `STORE_FILENAME` env var. 
  - `postgres` - use postgres. Requires `DATABASE_URL` env to be set

* `WEBHOOK_ROUTE_CONFIG_PATH` - absolute path of the config file
* `WEBHOOK_ROUTE_CONFIG_BASE64` - base64 representation of the config contents. Useful if you want to store the config file in secret env var


## Config example

config.json
```json
[
  {
    "webhook": "https://discord.com/webhook",
    "subreddit": "saskatoon"
  },
  {
    "webhook": "https://discord.com/webhook",
    "subreddit": "saskatchewan"
  }
]
```
