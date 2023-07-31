module DiscordStrava
  module Commands
    class Connect < Discord::Commands::Command
      include DiscordStrava::Commands::Mixins::Subscribe
      include DiscordStrava::Loggable

      subscribe_command 'strada' => 'connect' do |command|
        logger.info "CONNECT: #{command}, #{command.user}"
        command.user.connect_to_strava
      end
    end
  end
end
