module Discord
  module Commands
    extend Server
    extend self

    def install!(path)
      Dir.glob(path) do |command|
        begin
          rc = post("applications/#{ENV['DISCORD_APPLICATION_ID']}/commands", File.read(command))
          Api::Middleware.logger.info "Installed global command=#{rc['name']} (#{rc['description']}), id=#{rc['id']}, version=#{rc['version']}"
        rescue Faraday::Error => e
          Api::Middleware.logger.error "Error installing #{File.basename(command)}: #{e.message} (#{e.response[:body]})."
        end
      end
    end
  end
end