module DiscordStrava
  module Commands
    class Disconnect < Discord::Commands::Command
      include DiscordStrava::Commands::Mixins::Subscribe
      include DiscordStrava::Loggable

      subscribe_command 'strada' => 'disconnect' do |command|
        logger.info "DISCONNECT: #{command}, user=#{command.user}"
        command.user.disconnect!
      end
    end
  end
end
