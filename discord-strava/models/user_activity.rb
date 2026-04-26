class UserActivity < Activity
  field :start_date, type: DateTime
  field :start_date_local, type: DateTime
  field :start_date_local_utc_offset, type: Integer
  field :timezone, type: String

  belongs_to :user, inverse_of: :activities
  embeds_one :map
  embeds_one :weather
  embeds_many :photos

  index(user_id: 1, start_date: 1)
  index(user_id: 1, bragged_at: 1, start_date: 1)
  index('map._id' => 1)

  before_validation :validate_team

  def hidden?
    (private? && !user.private_activities?) ||
      (visibility == 'only_me' && !user.private_activities?) ||
      (visibility == 'followers_only' && !user.followers_only_activities?)
  end

  def start_date_local_in_local_time
    start_date_local_utc_offset ? start_date_local.getlocal(start_date_local_utc_offset) : start_date_local
  end

  def start_date_local_s
    return unless start_date_local

    start_date_local_in_local_time.strftime('%A, %B %d, %Y at %I:%M %p')
  end

  def brag!
    return if bragged_at

    if hidden?
      logger.info "Skipping #{user}, #{self}, private."
      update_attributes!(bragged_at: Time.now.utc)
      nil
    else
      channel_id = user.channel_id

      allowed_types = team.channel_activity_types_for(channel_id)
      unless allowed_types.empty? || allowed_types.any? { |t| t.casecmp(type.to_s).zero? }
        logger.info "Skipping #{user} in #{channel_id}, activity type #{type} not in #{allowed_types}."
        update_attributes!(bragged_at: Time.now.utc)
        return nil
      end

      channel_user_limit = team.channel_max_activities_per_user_per_day_for(channel_id)
      if channel_user_limit
        user_count_today = Activity.where(
          team_id: team.id,
          user_id: user.id,
          :bragged_at.gte => team.now.beginning_of_day,
          'channel_message.channel_id' => channel_id
        ).count
        if user_count_today >= channel_user_limit
          logger.info "#{user} reached the per-channel daily activity limit of #{channel_user_limit} in #{channel_id}."
          return nil
        end
      end

      if team.max_activities_per_channel_per_day
        channel_count_today = Activity.where(
          team_id: team.id,
          :bragged_at.gte => team.now.beginning_of_day,
          'channel_message.channel_id' => channel_id
        ).count
        if channel_count_today >= team.max_activities_per_channel_per_day
          logger.info "Channel #{channel_id} reached the daily activity limit of #{team.max_activities_per_channel_per_day}."
          update_attributes!(bragged_at: Time.now.utc)
          return nil
        end
      end

      logger.info "Bragging about #{user}, #{self}."
      rc = user.inform!(to_discord(channel_id))
      update_attributes!(bragged_at: Time.now.utc, channel_message: rc)
      rc
    end
  rescue DiscordStrava::Error => e
    raise unless User::DISABLE_SYNC_ERRORS.include?(e.message)

    logger.warn "Bragging to #{user} failed, #{e.message}, disabling user sync."
    update_attributes!(bragged_at: Time.now.utc)
    user.update_attributes!(sync_activities: false)
    nil
  rescue StandardError => e
    logger.warn "Bragging to #{user} failed, #{e.message}."
    raise e
  end

  def rebrag!
    return unless channel_message

    logger.info "Rebragging about #{user}, #{self}."
    rc = user.update!(to_discord(channel_message.channel_id), channel_message)
    update_attributes!(channel_message: rc)
    rc
  rescue DiscordStrava::Error => e
    raise unless e.message == User::UNKNOWN_MESSAGE_ERROR

    logger.warn "Rebragging to #{user} failed, #{e.message}, clearing channel message."
    update_attributes!(channel_message: nil)
    nil
  end

  def unbrag!
    return unless channel_message

    logger.info "Unbragging about #{user}, #{self}."
    user.delete!(channel_message)
    update_attributes!(channel_message: nil)
    nil
  end

  def detailed_attrs_from_strava(response)
    {
      strava_id: response.id,
      name: response.name,
      calories: response.calories,
      distance: response.distance,
      moving_time: response.moving_time,
      elapsed_time: response.elapsed_time,
      average_speed: response.average_speed,
      max_speed: response.max_speed,
      average_heartrate: response.average_heartrate,
      max_heartrate: response.max_heartrate,
      pr_count: response.pr_count,
      type: response.sport_type,
      total_elevation_gain: response.total_elevation_gain,
      private: response.private,
      visibility: response.visibility,
      description: response.description,
      device: response.device_name,
      gear: response.gear&.name,
      start_date: response.start_date,
      start_date_local: response.start_date_local,
      start_date_local_utc_offset: response.start_date_local.utc_offset,
      timezone: response.timezone,
      photos: response.photos&.primary ? [Photo.summary_attrs_from_strava(response.photos&.primary)] : []
    }
  end

  def summary_attrs_from_strava(response)
    {
      strava_id: response.id,
      name: response.name,
      distance: response.distance,
      moving_time: response.moving_time,
      elapsed_time: response.elapsed_time,
      average_speed: response.average_speed,
      max_speed: response.max_speed,
      average_heartrate: response.average_heartrate,
      max_heartrate: response.max_heartrate,
      pr_count: response.pr_count,
      type: response.sport_type,
      total_elevation_gain: response.total_elevation_gain,
      private: response.private,
      visibility: response.visibility,
      start_date: response.start_date,
      start_date_local: response.start_date_local,
      start_date_local_utc_offset: response.start_date_local.utc_offset,
      timezone: response.timezone
    }
  end

  def attrs_from_strava(response)
    case response
    when Strava::Models::SummaryActivity
      summary_attrs_from_strava(response)
    when Strava::Models::DetailedActivity
      detailed_attrs_from_strava(response)
    else
      raise "Unexpected #{response.class}."
    end
  end

  def update_from_strava(response)
    assign_attributes(attrs_from_strava(response))
    map_response = Map.attrs_from_strava(response.map)
    map ? map.assign_attributes(map_response) : build_map(map_response)
    self
  end

  def self.create_from_strava!(user, response)
    activity = UserActivity.where(strava_id: response.id, team_id: user.team.id, user_id: user.id).first
    activity ||= UserActivity.new(strava_id: response.id, team_id: user.team.id, user_id: user.id)
    activity.update_from_strava(response)
    return unless activity.changed?

    activity.map.update!
    activity.update_weather!
    activity.save!
    activity
  end

  def to_discord_embed(channel_id = nil)
    result = {}

    if display_field?(ActivityFields::TITLE, channel_id) && display_field?(ActivityFields::URL, channel_id)
      result[:title] = name || strava_id
      result[:url] = strava_url
    elsif display_field?(ActivityFields::TITLE, channel_id)
      result[:title] = name || strava_id
    elsif display_field?(ActivityFields::URL, channel_id)
      result[:title] = strava_id
      result[:url] = strava_url
    end

    result_description = [
      if display_field?(ActivityFields::USER, channel_id) || display_field?(ActivityFields::DATE, channel_id)
        [
          if display_field?(ActivityFields::USER, channel_id)
            [user.discord_mention, display_field?(ActivityFields::MEDAL, channel_id) ? user.medal_s(type) : nil].compact.join(' ')
          end,
          display_field?(ActivityFields::DATE, channel_id) ? start_date_local_s : nil
        ].compact.join(' on ')
      end,
      display_field?(ActivityFields::DESCRIPTION, channel_id) && description && !description.blank? ? description : nil
    ].compact

    result[:description] = result_description.join("\n\n") unless result_description.none?

    if map&.has_image?
      maps = team.channel_maps_for(channel_id)
      if maps == 'full'
        result[:image] = { url: map.proxy_image_url }
      elsif maps == 'thumb'
        result[:thumbnail] = { url: map.proxy_image_url }
      end
    elsif display_field?(ActivityFields::PHOTOS, channel_id) && photos.any? && photos.first.has_image?
      result[:image] = { url: photos.first.image_url }
    end

    result_fields = discord_fields(channel_id)
    result[:fields] = result_fields if result_fields&.any?
    result[:timestamp] = Time.now.utc.iso8601
    result.merge!(user.athlete.to_discord) if user.athlete && display_field?(ActivityFields::ATHLETE, channel_id)
    result
  end

  def to_discord_embeds(channel_id = nil)
    embeds = [to_discord_embed(channel_id)]
    # photo may be displayed instead of the map already
    embeds.concat(photos.map(&:to_discord_embed)) if display_field?(ActivityFields::PHOTOS, channel_id) && photos.any? && map&.has_image?
    embeds
  end

  def to_s
    "id=#{strava_id}, name=#{name}, date=#{start_date_local&.iso8601}, distance=#{distance_s}, moving time=#{moving_time_in_hours_s}, pace=#{pace_s}, #{map}"
  end

  def validate_team
    return if team_id && user.team_id == team_id

    errors.add(:team, 'Activity must belong to the same team as the user.')
  end

  def finished_at
    Time.at(start_date.to_i + elapsed_time.to_i)
  end

  def start_latlng
    map&.start_latlng
  end

  def update_weather!
    return if weather.present?
    return unless start_latlng

    dt = (Time.now - finished_at).to_i

    weather_options = { lat: start_latlng[0], lon: start_latlng[1] }

    if dt > 5.days.to_i
      return # OneCall Api does not return data that old
    elsif dt > 9.hours.to_i
      weather_options.merge!(dt: finished_at, exclude: ['hourly'])
    else
      weather_options.merge!(exclude: %w[minutely hourly daily])
    end

    current_weather = OpenWeather::Client.new.one_call(weather_options).current
    unless current_weather
      logger.warn "Error getting weather at #{start_latlng.join(', ')} on #{finished_at.to_i} for #{user}, #{self}, none returned."
      return
    end

    current_weather.weather.each do |w|
      w.icon_uri = w.icon_uri.to_s
    end

    build_weather(current_weather.to_h) if current_weather
  rescue StandardError => e
    logger.warn "Error getting weather at #{start_latlng.join(', ')} on #{finished_at.to_i} for #{user}, #{self}, #{e.message}."
    NewRelic::Agent.notice_error(e, custom_params: { activity: to_s, user: user.to_s })
  end

  def weather_s(channel_id = nil)
    return unless weather.present?

    current_weather = OpenWeather::Models::OneCall::CurrentWeather.new(
      weather.attributes.except('_id', 'updated_at', 'created_at')
    )

    main = current_weather.weather&.first&.main

    case team.channel_temperature_for(channel_id)
    when 'c'
      ["#{current_weather.temp_c.to_i}°C", main].compact.join(' ')
    when 'f'
      ["#{current_weather.temp_f.to_i}°F", main].compact.join(' ')
    when 'both'
      [
        [
          "#{current_weather.temp_f.to_i}°F",
          "#{current_weather.temp_c.to_i}°C"
        ].join(ActivityMethods::UNIT_SEPARATOR),
        main
      ].compact.join(' ')
    end
  end
end
