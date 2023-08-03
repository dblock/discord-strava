module DiscordStrava
  module Commands
    class Stats < Discord::Commands::Command
      include DiscordStrava::Commands::Mixins::Subscribe
      include DiscordStrava::Loggable

      subscribe_command 'strada' => 'stats' do |command|
        logger.info "STATS: #{command}"
        command.team.stats(
          channel_id: command.channel_id
        ).to_discord
      end
    end
  end
end
