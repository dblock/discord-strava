module DiscordStrava
  module Commands
    class Leaderboard < Discord::Commands::Command
      include DiscordStrava::Commands::Mixins::Subscribe
      include DiscordStrava::Loggable

      class << self
        def parse_year(date_time)
          return unless date_time.match?(/^\d{2,4}$/)

          year = date_time.to_i
          year += 2000 if year < 100
          Time.new(year, 1, 1)
        end

        def parse_date(date_time, guess = :first)
          if year = Leaderboard.parse_year(date_time)
            year
          else
            parsed = Chronic.parse(date_time, context: :past, guess: false)
            if parsed.is_a?(Chronic::Span)
              parsed.send(guess)
            elsif parsed.is_a?(Time)
              parsed
            else
              raise DiscordStrava::Error, "Sorry, I don't understand '#{date_time}'."
            end
          end
        end

        def parse_expression(expression)
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

          if expression.match?(/^between(\s)/i)
            expression = expression[('between'.length)..]&.strip
            dates = expression.strip.split(/\s+and\s+/)
            raise DiscordStrava::Error, "Sorry, I don't understand '#{expression}'." unless dates.length == 2

            result[:start_date] = Leaderboard.parse_date(dates[0], :first)
            result[:end_date] = Leaderboard.parse_date(dates[1], :last)
          else
            if expression.match?(/^since(\s)/i)
              expression = expression[('since'.length)..]&.strip
              result[:end_date] = Time.now
            end

            if expression.blank?
              # pass
            elsif year = Leaderboard.parse_year(expression)
              result[:start_date] = year
              result[:end_date] ||= year.end_of_year
            else
              parsed = Chronic.parse(expression, context: :past, guess: false)
              if parsed.is_a?(Chronic::Span)
                result[:start_date] = parsed.first
                result[:end_date] ||= parsed.last
              elsif parsed.is_a?(Time)
                result[:start_date] = parsed
              else
                raise DiscordStrava::Error, "Sorry, I don't understand '#{expression}'."
              end
            end
          end

          result
        end
      end

      subscribe_command 'strada' => 'leaderboard' do |command|
        metric_value = command.options.dig('leaderboard', 'args', 'metric', 'value')
        range_value = command.options.dig('leaderboard', 'args', 'range', 'value')
        combined_options = [metric_value, range_value].compact.join(' ')
        combined_options = command.team.default_leaderboard if combined_options.blank?
        range_options = Leaderboard.parse_expression(combined_options)
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
