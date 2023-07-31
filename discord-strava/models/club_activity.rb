class ClubActivity < Activity
  field :athlete_name, type: String
  field :fetched_at, type: DateTime
  field :first_sync, type: Boolean, default: false

  belongs_to :club, inverse_of: :activities

  index(club_id: 1)

  before_validation :validate_team

  def brag!
    if bragged_at?
      logger.info "Already bragged about #{club}, #{self}"
      nil
    elsif first_sync?
      update_attributes!(bragged_at: Time.now.utc)
      logger.info "Skipping first sync about #{club} in #{club.channel_id}, #{self}"
      nil
    elsif bragged_in?(club.channel_id)
      update_attributes!(bragged_at: Time.now.utc)
      logger.info "Already bragged about #{club} in #{club.channel_id}, #{self}"
      nil
    elsif privately_bragged?
      update_attributes!(bragged_at: Time.now.utc)
      logger.info "Found a privately bragged activity about #{club} in #{club.channel_id}, #{self}"
      nil
    else
      logger.info "Bragging about #{club}, #{self}"
      message_with_channel = to_discord.merge(channel: club.channel_id, as_user: true)
      logger.info "Posting '#{message_with_channel.to_json}' to #{club.team} on ##{club.channel_name}."
      channel_message = club.team.discord_client.chat_postMessage(message_with_channel)
      if channel_message
        channel_message = { ts: channel_message['ts'], channel: club.channel_id }
      end
      update_attributes!(bragged_at: Time.now.utc, channel_message: channel_message)
      channel_message
    end
  rescue StandardError => e
    # TODO: inform admin of failure to post to channel
    raise e
  end

  def self.attrs_from_strava(response)
    Activity.attrs_from_strava(response).merge(
      strava_id: Digest::MD5.hexdigest(response.to_s),
      athlete_name: [response.athlete.firstname, response.athlete.lastname].compact.join(' '),
      average_speed: response.moving_time.positive? ? response.distance / response.moving_time : 0
    )
  end

  def to_discord_embed
    result = {}
    result[:title] = name
    result[:url] = club.strava_url
    result[:description] = "#{athlete_name}, #{club.name}"
    fields = discord_fields
    result[:fields] = fields if fields
    result[:thumbnail] = { url: club.logo }
    result[:timestamp] = Time.now.utc.iso8601
    result
  end

  def validate_team
    return if team_id && club.team_id == team_id

    errors.add(:team, 'Activity must belong to the same team as the club.')
  end
end
