class TeamLeaderboard
  include ActiveModel::Model

  class Row
    include ActivityMethods
    extend Forwardable

    attr_accessor :type, :team, :field, :value, :user, :rank

    def initialize(options = {})
      @team = options[:team]
      @type = options[:type]
      @field = options[:field]
      @value = options[:value]
      @user = options[:user]
      @rank = options[:rank]
    end

    def to_s
      ["#{rank}:", user.user_name, emoji, send("#{field.gsub(' ', '_')}_s")].join(' ').to_s
    end

    alias count_s value
    alias pr_count_s value
    alias total_elevation_gain value
    alias moving_time value
    alias elapsed_time value

    alias elevation_s total_elevation_gain_s
    alias time_s moving_time_in_hours_s
    alias moving_time_s moving_time_in_hours_s
    alias elapsed_time_s elapsed_time_in_hours_s

    def method_missing(method, *args)
      if method.to_s == field
        value
      else
        super
      end
    end
  end

  MEASURABLE_VALUES = %w[
    count distance moving_time elapsed_time elevation pr_count calories
  ].freeze

  attr_accessor :team, :metric, :channel_id

  def initialize(team, options = {})
    @team = team
    @metric = options[:metric]
    @channel_id = options[:channel_id]
  end

  def aggreate_options
    aggreate_options = { team_id: team.id, _type: 'UserActivity' }
    aggreate_options.merge!('channel_message.channel_id' => channel_id) if channel_id
    aggreate_options
  end

  def aggregate!
    @aggregate ||= begin
      raise DiscordStrava::Error, "Missing value. Expected one of #{MEASURABLE_VALUES.or}." unless metric && !metric.blank?
      raise DiscordStrava::Error, "Invalid value: #{metric}. Expected one of #{MEASURABLE_VALUES.or}." unless MEASURABLE_VALUES.map(&:downcase).include?(metric.downcase)

      UserActivity.collection.aggregate(
        [
          { '$match': aggreate_options },
          {
            '$group' => {
              _id: { user_id: '$user_id', type: '$type' },
              metric => { '$sum' => metric == 'count' ? 1 : "$#{metric}" }
            }
          },
          {
            '$setWindowFields': {
              sortBy: { metric => -1 },
              output: {
                rank: { '$denseRank': {} }
              }
            }
          }
        ]
      )
    end
  end

  def find(user_id, activity_type)
    position = aggregate!.find_index do |row|
      row[:_id][:user_id] == user_id && row[:_id][:type] == activity_type
    end
    position && position >= 0 ? position + 1 : nil
  end

  def to_discord
    top = aggregate!.map { |row|
      next unless row[metric] > 0

      Row.new(
        team: team,
        user: team.users.find(row[:_id][:user_id]),
        type: row[:_id][:type],
        field: metric,
        value: row[metric],
        rank: row[:rank]
      ).to_s
    }.compact
    top.any? ? top.join("\n") : "There are no activities with #{metric.split('_').join(' ')} in this channel."
  end
end