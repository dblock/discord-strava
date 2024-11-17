class TeamStats
  extend Forwardable

  attr_reader :team, :stats, :options

  def initialize(team, options = {})
    @team = team
    @options = options.dup
    aggregate!
  end

  def_delegators :@stats, :each, :[], :count, :size, :keys, :values, :any?, :map

  def to_discord
    if any?
      {
        embeds: values.map(&:to_discord_embed)
      }
    else
      'There are no activities in this channel.'
    end
  end

  private

  def aggreate_options
    aggreate_options = { team_id: team.id }
    aggreate_options.merge!('channel_message.channel_id' => options[:channel_id]) if options.key?(:channel_id)
    aggreate_options
  end

  def aggregate!
    @stats = Activity.collection.aggregate(
      [
        { '$match' => aggreate_options },
        {
          '$group' => {
            _id: { type: { '$ifNull' => ['$type', 'unknown'] } },
            count: { '$sum' => 1 },
            distance: { '$sum' => '$distance' },
            elapsed_time: { '$sum' => '$elapsed_time' },
            moving_time: { '$sum' => '$moving_time' },
            pr_count: { '$sum' => '$pr_count' },
            calories: { '$sum' => '$calories' },
            total_elevation_gain: { '$sum' => '$total_elevation_gain' }
          }
        },
        { '$sort' => { count: -1 } }
      ]
    ).map { |row|
      type = row['_id']['type']
      [type, ActivitySummary.new(
        team:,
        type:,
        count: row['count'],
        athlete_count: team.activities.where(type:).distinct(:user_id).count,
        stats: Hashie::Mash.new(row.except('_id').except('count'))
      )]
    }.to_h
  end
end
