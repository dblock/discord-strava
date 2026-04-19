module DiscordStrava
  module Commands
    class Stats < Discord::Commands::Command
      include DiscordStrava::Commands::Mixins::Subscribe
      include DiscordStrava::Loggable

      class << self
        include DiscordStrava::Commands::Mixins::ParseDate
      end

      subscribe_command 'strada' => 'stats' do |command|
        logger.info "STATS: #{command}"
        expression = command.options.dig('stats', 'args', 'range', 'value')
        stats_options = begin
          Stats.parse_date_expression(expression, now: command.team.now)
        rescue DiscordStrava::Error
          {}
        end
        stats_options[:channel_id] = command.channel_id
        logger.info "STATS: #{command.team}, dates=#{stats_options[:start_date]}..#{stats_options[:end_date]}, channel=#{command.channel_id}"
        command.team.stats(stats_options).to_discord
      end
    end
  end
end
