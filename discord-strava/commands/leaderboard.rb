module DiscordStrava
  module Commands
    class Leaderboard < Discord::Commands::Command
      include DiscordStrava::Commands::Mixins::Subscribe
      include DiscordStrava::Loggable

      class << self
        include DiscordStrava::Commands::Mixins::ParseDate

        def parse_expression(expression, now: Time.now)
          result = { metric: 'distance' }
          return result if expression.nil?

          expression = expression.strip

          TeamLeaderboard::MEASURABLE_VALUES.each do |metric|
            next unless expression.match?(/^(#{Regexp.escape(metric.split('_').join(' '))}|#{Regexp.escape(metric)})(?:\s|$)/i)

            result[:metric] = metric
            expression = expression[metric.length..]&.strip
            break
          end

          expression = expression.strip

          result.merge(parse_date_expression(expression, now: now))
        end
      end

      subscribe_command 'strada' => 'leaderboard' do |command|
        metric_value = command.options.dig('leaderboard', 'args', 'metric', 'value')
        range_value = command.options.dig('leaderboard', 'args', 'range', 'value')
        combined_options = [metric_value, range_value].compact.join(' ')
        combined_options = command.team.default_leaderboard if combined_options.blank?
        range_options = Leaderboard.parse_expression(combined_options, now: command.team.now)
        logger.info "LEADERBOARD: #{command}, metric=#{range_options[:metric]}, range=#{range_options[:start_date]}..#{range_options[:end_date]}"
        command.team.leaderboard(
          range_options.merge(
            channel_id: command.channel_id
          )
        ).to_discord
      end
    end
  end
end
