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

    def http_method(method, path, options = {}, encoding = :json)
      raise 'Missing DISCORD_CLIENT_ID or DISCORD_CLIENT_SECRET.' unless ENV.key?('DISCORD_CLIENT_ID') && ENV.key?('DISCORD_CLIENT_SECRET')

      rc = ActiveSupport::HashWithIndifferentAccess.new(Faraday.new(url: 'https://discord.com/api') { |conn|
        conn.use Faraday::Response::RaiseError
        conn.request encoding
        conn.response :json
      }.send(method, path, options) { |request|
        request.headers['Authorization'] = "Bot #{ENV.fetch('DISCORD_SECRET_TOKEN', nil)}"
      }.body)
    end
  end
end
