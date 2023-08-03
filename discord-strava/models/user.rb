class User
  include Mongoid::Document
  include Mongoid::Timestamps
  include StravaTokens
  include Brag

  field :channel_id, type: String
  field :user_id, type: String
  field :user_name, type: String
  field :activities_at, type: DateTime
  field :connected_to_strava_at, type: DateTime
  field :is_bot, type: Boolean, default: false
  field :is_owner, type: Boolean, default: false
  field :is_admin, type: Boolean, default: false
  field :private_activities, type: Boolean, default: false
  field :followers_only_activities, type: Boolean, default: true
  field :sync_activities, type: Boolean, default: true

  embeds_one :athlete
  index('athlete.athlete_id' => 1)

  belongs_to :team, index: true
  validates_presence_of :team

  has_many :activities, class_name: 'UserActivity', dependent: :destroy

  index({ team_id: 1, user_id: 1, channel_id: 1 }, unique: true)

  scope :connected_to_strava, -> { where(:access_token.ne => nil) }

  after_update :connected_to_strava_changed
  after_update :sync_activities_changed

  def connected_to_strava?
    !access_token.nil?
  end

  def connect_to_strava_url
    redirect_uri = "#{DiscordStrava::Service.url}/connect"
    "https://www.strava.com/oauth/authorize?client_id=#{ENV.fetch('STRAVA_CLIENT_ID', nil)}&redirect_uri=#{redirect_uri}&response_type=code&scope=activity:read_all&state=#{id}"
  end

  def inform!(message)
    logger.info "Posting '#{message}' for #{self} on #{channel_id}."
    rc = Discord::Messages.send_message(channel_id, message)

    {
      message_id: rc['id'],
      channel_id: rc['channel_id']
    }
  end

  def update!(message, channel_message)
    logger.info "Updating #{self}, message_id=#{channel_message.message_id}, channel_id=#{channel_message.channel_id} with #{message}."
    rc = Discord::Messages.update_message(channel_message.channel_id, channel_message.message_id, message)

    {
      message_id: rc['id'],
      channel_id: rc['channel_id']
    }
  end

  def to_s
    "user_id=#{user_id}, user_name=#{user_name}"
  end

  def discord_mention
    "<@#{user_id}>"
  end

  def connect!(code)
    response = get_access_token!(code)
    logger.debug "Connecting team=#{team}, user=#{self}, #{response}"
    raise 'Missing access_token in OAuth response.' unless response.access_token
    unless response.refresh_token
      raise 'Missing refresh_token in OAuth response.'
    end
    raise 'Missing expires_at in OAuth response.' unless response.expires_at

    create_athlete(Athlete.attrs_from_strava(response.athlete))
    update_attributes!(
      token_type: response.token_type,
      access_token: response.access_token,
      refresh_token: response.refresh_token,
      token_expires_at: Time.at(response.expires_at),
      connected_to_strava_at: DateTime.now.utc
    )
    logger.info "Connected team=#{team}, user=#{self}, athlete_id=#{athlete.athlete_id}"
    dm! "Your Strava account has been successfully connected.\nI won't post any private activities, use `/strada set private on` to toggle that, and `/strada help` for other options."
    inform! "New Strava account connected for #{discord_mention}."
  end

  def disconnect_from_strava
    if access_token
      logger.info "Disconnected team=#{team}, user=#{self}"
      reset_access_tokens!(connected_to_strava_at: nil)
      'Your Strava account has been successfully disconnected.'
    else
      'Your Strava account is not connected.'
    end
  end

  def disconnect!
    disconnect_from_strava
  end

  def connect_to_strava(message = 'Please connect your Strava account.')
    {
      content: message,
      components: [{
        type: 1,
        components: [{
          type: 2,
          label: 'Connect!',
          style: 5,
          url: connect_to_strava_url
        }]
      }]
    }
  end

  def dm_connect!(message = 'Please connect your Strava account.')
    dm!(connect_to_strava(message))
  end

  def dm!(message)
    rc = Discord::Messages.send_dm(user_id, message)

    {
      message_id: rc['id'],
      channel_id: rc['channel_id']
    }
  end

  def brag!
    brag_new_activities!
  end

  def rebrag!
    rebrag_last_activity!
  end

  def brag_new_activities!
    activity = activities.unbragged.asc(:start_date).first
    return unless activity

    update_attributes!(activities_at: activity.start_date) if activities_at.nil? || (activities_at < activity.start_date)
    result = activity.brag!
    return unless result

    result.merge(activity: activity)
  end

  # updates activity details, brings in description, etc.
  def rebrag_last_activity!
    activity = latest_bragged_activity
    return unless activity

    rebrag_activity!(activity)
  end

  def rebrag_activity!(activity)
    with_strava_error_handler do
      detailed_activity = strava_client.activity(activity.strava_id)

      activity = UserActivity.create_from_strava!(self, detailed_activity)
      return unless activity
      return unless activity.bragged_at

      result = activity.rebrag!
      return unless result

      result.merge(activity: activity)
    end
  end

  def sync_new_strava_activities!
    dt = activities_at || latest_activity_start_date || before_connected_to_strava_at || created_at
    options = {}
    options[:after] = dt.to_i unless dt.nil?
    sync_strava_activities!(options)
  end

  def sync_strava_activity!(strava_id)
    detailed_activity = strava_client.activity(strava_id)
    return if detailed_activity['private'] && !private_activities?
    if detailed_activity.athlete.id.to_s != athlete.athlete_id
      raise "Activity athlete ID #{detailed_activity.athlete.id} does not match #{athlete.athlete_id}."
    end

    UserActivity.create_from_strava!(self, detailed_activity) || activities.where(strava_id: detailed_activity.id).first
  rescue Strava::Errors::Fault => e
    handle_strava_error e
  end

  def athlete_clubs_to_discord
    clubs = team.clubs.where(channel_id: channel_id).to_a
    if connected_to_strava?
      strava_client.athlete_clubs do |row|
        strava_id = row.id.to_s
        next if clubs.detect { |club| club.strava_id == strava_id }

        clubs << Club.new(Club.attrs_from_strava(row).merge(team: team))
      end
    end
    club_options = clubs.sort_by(&:strava_id).map do |club|
      club.connect_to_discord
    end
    if club_options.empty?
      { content: 'Not connected to any clubs.' }
    else
      result = {
        content: 'Choose a club.',
        components: [
          {
            type: 1,
            components: [
              {
                type: 3,
                custom_id: 'club',
                placeholder: 'Choose a club.',
                min_values: 1,
                max_values: 1,
                options: club_options
              }
            ]
          }
        ]
      }
      p result
      result
    end
  end

  def activated_user?
    team.guild_owner_id && team.guild_owner_id == user_id
  end

  def team_admin?
    activated_user? || is_admin? || is_owner?
  end

  private

  # includes some of the most recent activities
  def before_connected_to_strava_at(tt = 8.hours)
    dt = connected_to_strava_at
    dt -= tt if dt
    dt
  end

  def latest_bragged_activity(dt = 12.hours)
    activities.bragged.where(:start_date.gt => Time.now - dt).desc(:start_date).first
  end

  def latest_activity_start_date
    activities.desc(:start_date).first&.start_date
  end

  def sync_strava_activities!(options = {})
    return unless sync_activities?

    strava_client.athlete_activities(options) do |activity|
      UserActivity.create_from_strava!(self, activity)
    end
  rescue Strava::Errors::Fault => e
    handle_strava_error e
  end

  def handle_strava_error(e)
    if e.message =~ /Authorization Error/
      logger.warn "Error for #{self}, #{e.message}, authorization error."
      dm_connect! 'There was an authorization problem with Strava. Make sure that you leave the "View data about your private activities" box checked when reconnecting your Strava account.'
      reset_access_tokens!(connected_to_strava_at: nil)
    elsif e.errors&.first && e.errors.first['field'] == 'refresh_token' && e.errors.first['code'] == 'invalid'
      logger.warn "Error for #{self}, #{e.message}, refresh token was invalid."
      dm_connect! 'There was a re-authorization problem with Strava. Make sure that you leave the "View data about your private activities" box checked when reconnecting your Strava account.'
      reset_access_tokens!(connected_to_strava_at: nil)
    else
      logger.error "#{e.class.name}: #{e.message}\n  #{backtrace}"
    end
    raise e
  end

  def connected_to_strava_changed
    return unless connected_to_strava_at? && connected_to_strava_at_changed?

    activities.destroy_all
    set activities_at: nil
  end

  def sync_activities_changed
    return unless sync_activities? && sync_activities_changed?

    activities.destroy_all
    set activities_at: Time.now.utc
  end
end
