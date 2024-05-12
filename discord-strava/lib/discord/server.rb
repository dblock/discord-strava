module Discord
  module Server
    def get(path, encoding = :json)
      http_method(:get, path, {}, encoding)
    end

    def post(path, options = {}, encoding = :json)
      http_method(:post, path, options, encoding)
    end

    def patch(path, options = {}, encoding = :json)
      http_method(:patch, path, options, encoding)
    end

    def delete(path, options = {}, encoding = :json)
      http_method(:delete, path, options, encoding)
    end

    def http_method(method, path, options = {}, encoding = :json)
      raise 'Missing DISCORD_CLIENT_ID or DISCORD_CLIENT_SECRET.' unless ENV.key?('DISCORD_CLIENT_ID') && ENV.key?('DISCORD_CLIENT_SECRET')

      rc = ActiveSupport::HashWithIndifferentAccess.new(Faraday.new(url: 'https://discord.com/api') { |conn|
        conn.use Faraday::Response::RaiseError
        conn.request encoding
        conn.response :json
      }.send(method, path, options) { |request|
        request.headers['Authorization'] = "Bot #{ENV.fetch('DISCORD_SECRET_TOKEN', nil)}"
      }.body)
    rescue Faraday::Error => e
      handle_error(e)
    end

    private

    def handle_error(e)
      message = e.response[:body]['message']
      code = e.response[:body]['code']
      if message && code
        raise DiscordStrava::Error, "#{message} (#{code}, #{e.response[:status]})"
      else
        raise DiscordStrava::Error, "#{e} (#{e.response[:body]})"
      end
    end
  end
end
