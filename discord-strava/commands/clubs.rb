module DiscordStrava
  module Commands
    class Clubs < Discord::Commands::Command
      include DiscordStrava::Commands::Mixins::Subscribe
      include DiscordStrava::Loggable

      subscribe_command 'strada' => 'clubs' do |command|
        logger.info "CLUBS: #{command}, #{command.user}"
        command.user.athlete_clubs_to_discord
      end
    end
  end
end
