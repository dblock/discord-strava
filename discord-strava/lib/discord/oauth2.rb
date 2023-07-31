module Discord
  module OAuth2
    extend Server
    extend self

    def exchange_code(code)
      rc = post(
        'oauth2/token', {
          client_id: ENV.fetch('DISCORD_CLIENT_ID', nil),
          client_secret: ENV.fetch('DISCORD_CLIENT_SECRET', nil),
          code: code,
          grant_type: 'authorization_code',
          redirect_uri: ENV.fetch('URL', nil),
          scope: 'bot'
        }, :url_encoded
      )

      {
        token: rc['access_token'],
        token_expires_at: Time.now.utc + rc['expires_in'],
        refresh_token: rc['refresh_token'],
        guild_id: rc['guild']['id'],
        guild_name: rc['guild']['name'],
        guild_owner_id: rc['guild']['owner_id']
      }
    end

    def refresh_token(token)
      rc = post(
        'oauth2/token', {
          client_id: ENV.fetch('DISCORD_CLIENT_ID', nil),
          client_secret: ENV.fetch('DISCORD_CLIENT_SECRET', nil),
          grant_type: 'refresh_token',
          refresh_token: token
        }, :url_encoded
      )

      {
        token: rc['access_token'],
        token_expires_at: Time.now.utc + rc['expires_in'],
        refresh_token: rc['refresh_token']
      }
    end
  end
end
