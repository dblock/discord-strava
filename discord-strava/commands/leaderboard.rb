module DiscordStrava
  module Commands
    class Leaderboard < Discord::Commands::Command
      include DiscordStrava::Commands::Mixins::Subscribe
      include DiscordStrava::Loggable

      subscribe_command 'strada' => 'leaderboard' do |command|
        metric = command.options.dig('leaderboard', 'args', 'metric', 'value') || 'distance'
        logger.info "LEADERBOARD: #{command}, metric=#{metric}"
        command.team.leaderboard(
          channel_id: command.channel_id,
          metric: metric
        ).to_discord
      end
    end
  end
end
