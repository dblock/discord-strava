module Discord
  class Client
    include Connection

    attr_reader :token_type, :token

    def initialize(token_type, token)
      raise 'Missing token type or token.' unless token_type && token

      @token_type = token_type
      @token = token
    end

    def info(guild_id)
      get("guilds/#{guild_id}")
    end

    def create_dm(recipient_id)
      post(
        'users/@me/channels', {
          recipient_id:
        }
      )
    end

    def send_message(channel_id, message)
      post("channels/#{channel_id}/messages", message.is_a?(String) ? { content: message } : message)
    end

    def update_message(channel_id, message_id, message)
      patch("channels/#{channel_id}/messages/#{message_id}", message.is_a?(String) ? { content: message } : message)
    end

    def delete_message(channel_id, message_id)
      delete("channels/#{channel_id}/messages/#{message_id}")
    end

    def send_dm(recipient_id, message)
      channel = create_dm(recipient_id)
      send_message(channel['id'], message)
    end

    def exchange_code(code)
      rc = post(
        'oauth2/token', {
          client_id: ENV.fetch('DISCORD_CLIENT_ID', nil),
          client_secret: ENV.fetch('DISCORD_CLIENT_SECRET', nil),
          code:,
          grant_type: 'authorization_code',
          redirect_uri: ENV.fetch('URL', nil),
          scope: 'identify+bot'
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
