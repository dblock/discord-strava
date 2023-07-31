module Discord
  module Server
    def post(path, options = {}, encoding=:json)
      http_method(:post, path, options, encoding)
    end

    def patch(path, options = {}, encoding=:json)
      http_method(:patch, path, options, encoding)
    end

    def http_method(method, path, options = {}, encoding=:json)
      raise 'Missing DISCORD_CLIENT_ID or DISCORD_CLIENT_SECRET.' unless ENV.key?('DISCORD_CLIENT_ID') && ENV.key?('DISCORD_CLIENT_SECRET')
      
      rc = Faraday.new(url: 'https://discord.com/api') { |conn|
        conn.use Faraday::Response::RaiseError
        conn.request encoding
        conn.response :json
      }.send(method, path, options) do |request|
        request.headers["Authorization"] = "Bot #{ENV['DISCORD_SECRET_TOKEN']}"
      end.body
    end
  end
end
