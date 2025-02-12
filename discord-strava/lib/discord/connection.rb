module Discord
  module Connection
    def authorization_header
      [token_type, token].compact.join(' ')
    end

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
      conn = Faraday.new(url: 'https://discord.com/api') do |f|
        f.use Faraday::Response::RaiseError
        f.request encoding
        f.response :json
      end

      response = conn.send(method, path, options) do |request|
        request.headers['Authorization'] = authorization_header
      end

      ActiveSupport::HashWithIndifferentAccess.new(response.body)
    rescue Faraday::Error => e
      handle_error(e)
    end

    private

    def handle_error(e)
      message = e.response[:body]['message']
      code = e.response[:body]['code']
      raise DiscordStrava::Error, "#{message} (#{code}, #{e.response[:status]})" if message && code

      raise DiscordStrava::Error, "#{e} (#{e.response[:body]})"
    end
  end
end
