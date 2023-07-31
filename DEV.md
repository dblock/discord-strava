## Development Environment

### Prerequisites

Ensure that you can build the project and run tests. You will need these.

- [MongoDB](https://docs.mongodb.com/manual/installation/)
- [Firefox](https://www.mozilla.org/firefox/new/)
- [Geckodriver](https://github.com/mozilla/geckodriver), download, `tar vfxz` and move to `/usr/local/bin`
- Ruby 3.2.1

```
bundle install
bundle exec rake
```

### Discord Developer Platform

Get familiar with the Discord Developer platform [here](https://discord.com/developers/docs/intro).

### Discord Server

Create a Discord Server by following the instructions [here](https://support.discord.com/hc/en-us/articles/204849977-How-do-I-create-a-server-).

### Discord App

Create a new Discord app [here](https://discord.com/developers/applications?new_application=true). This gives you an _application ID_ and a _public key_.

Choose _Bot_ on the left menu.

Check the _Requires OAuth2 Code Grant_ option.

Add the following _Permissions_.

* Send Messages
* Embed Links
* Use Slash Commands

Choose _OAuth2_.

Use _Reset Secret_ to get a new Discord client ID (`DISCORD_CLIENT_ID`), and a secret token (`DISCORD_SECRET_TOKEN`). Save those.

### Keys

Create a `.env` file from [.env.sample](.env.sample). Fill the Strava and Discord keys at a minimum.

### Start the Bot

```
$ foreman start

08:54:07 web.1  | started with pid 32503
08:54:08 web.1  | I, [2017-08-04T08:54:08.138999 #32503]  INFO -- : listening on addr=0.0.0.0:5000 fd=11
```

Navigate to [localhost:5000](http://localhost:5000).

### NGrok

Use ngrok to run an externally visible instance.

```
$ ngrok http 5000
```

Note the URL.

### Interactions URL

Set the Interactions Endpoint Url in your app configuration to `https://....ngrok-free.app/api/discord`. It should verify successfully when saved.