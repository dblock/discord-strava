class Team
  include Mongoid::Document
  include Mongoid::Timestamps

  SORT_ORDERS = ['created_at', '-created_at', 'updated_at', '-updated_at'].freeze

  scope :active, -> { where(active: true) }

  field :guild_id, type: String
  field :guild_name, type: String
  field :guild_owner_id, type: String

  field :token, type: String
  field :token_expires_at, type: DateTime
  field :refresh_token, type: String
  field :permissions, type: Integer

  field :active, type: Mongoid::Boolean, default: true

  field :api, type: Boolean, default: false

  field :units, type: String, default: 'mi'
  validates_inclusion_of :units, in: %w[mi km both]

  field :activity_fields, type: Array, default: ['Default']
  validates :activity_fields, array: { presence: true, inclusion: { in: ActivityFields.values } }

  field :maps, type: String, default: 'full'
  validates_inclusion_of :maps, in: MapTypes.values

  field :stripe_customer_id, type: String
  field :subscribed, type: Boolean, default: false
  field :subscribed_at, type: DateTime
  field :subscription_expired_at, type: DateTime

  field :trial_informed_at, type: DateTime

  scope :api, -> { where(api: true) }
  scope :striped, -> { where(subscribed: true, :stripe_customer_id.ne => nil) }
  scope :trials, -> { where(subscribed: false) }

  has_many :users, dependent: :destroy
  has_many :activities

  validates_uniqueness_of :token, message: 'has already been used'
  validates_presence_of :token
  validates_presence_of :guild_id

  before_validation :update_subscribed_at
  before_validation :update_subscription_expired_at
  after_update :subscribed!
  after_save :activated!
  before_destroy :destroy_subscribed_team

  def refresh_token!
    update_attributes!(Discord::OAuth2.refresh_token(refresh_token))
    logger.info "Refreshed token for team #{self}, expires on #{token_expires_at}."
  rescue Faraday::Error => e
    logger.warn "Error refreshing token for team #{self}, #{e.message} (#{e.response[:body]})."
    NewRelic::Agent.notice_error(e, custom_params: { team: to_s })
  end

  def deactivate!
    update!(active: false)
  end

  def activate!(token)
    update!(active: true, token: token)
  end

  def to_s
    {
      _id: _id,
      guild_id: guild_id,
      guild_name: guild_name
    }.map { |k, v|
      "#{k}=#{v}" if v
    }.compact.join(', ')
  end

  def ping!
    # raise NotImplementedError
  end

  def ping_if_active!
    return unless active?

    ping!
  rescue StandardError => e
    logger.warn "Active team #{self} ping, #{e.message}, deactivating."
    deactivate!
  end

  def tags
    [
      subscribed? ? 'subscribed' : 'trial',
      stripe_customer_id? ? 'paid' : nil
    ].compact
  end

  def units_s
    case units
    when 'mi'
      'miles, feet, yards, and degrees Fahrenheit'
    when 'km'
      'kilometers, meters, and degrees Celcius'
    when 'both'
      'both units'
    else
      raise ArgumentError
    end
  end

  def maps_s
    case maps
    when 'off'
      'not displayed'
    when 'full'
      'displayed in full'
    when 'thumb'
      'displayed as thumbnails'
    else
      raise ArgumentError
    end
  end

  def activity_fields_s
    case activity_fields
    when ['All']
      'all displayed if available'
    when ['Default']
      'set to default'
    when ['None']
      'not displayed'
    else
      activity_fields.and
    end
  end

  def asleep?(dt = 2.weeks)
    return false unless subscription_expired?

    time_limit = Time.now - dt
    created_at <= time_limit
  end

  # returns DM channel
  def inform_guild_owner!(message)
    return unless guild_owner_id

    rc = Discord::Messages.send_dm(guild_owner_id, message)

    {
      message_id: rc['id'],
      channel_id: rc['channel_id']
    }
  end

  def inform_system!(message)
    system_channel_id = guild_info[:system_channel_id]
    return unless system_channel_id

    rc = Discord::Messages.send_message(system_channel_id, message)

    {
      message_id: rc['id'],
      channel_id: rc['channel_id']
    }
  end

  def inform_everyone!(message)
    inform_system!(message)
    inform_guild_owner!(message)
  end

  def subscription_info(guild_owner = true)
    subscription_info = []
    if stripe_subcriptions&.any?
      subscription_info << stripe_customer_text
      subscription_info.concat(stripe_customer_subscriptions_info)
      if guild_owner
        subscription_info.concat(stripe_customer_invoices_info)
        subscription_info.concat(stripe_customer_sources_info)
        subscription_info << update_cc_text
      end
    elsif subscribed && subscribed_at
      subscription_info << subscriber_text
    else
      subscription_info << trial_message
    end
    subscription_info.compact.join("\n")
  end

  def subscription_expired!
    return unless subscription_expired?
    return if subscription_expired_at

    inform_everyone!(subscribe_text)
    update_attributes!(subscription_expired_at: Time.now.utc)
  end

  def subscription_expired?
    return false if subscribed?

    time_limit = Time.now - 2.weeks
    created_at < time_limit
  end

  def update_cc_text
    "Update your credit card info at #{DiscordStrava::Service.url}/update_cc?guild_id=#{guild_id}."
  end

  def subscribed_text
    <<~EOS.freeze
      Your team has been subscribed. Proceeds go to NYRR. Thank you!
      Follow https://twitter.com/playplayio for news and updates.
    EOS
  end

  def trial_ends_at
    raise 'Team is subscribed.' if subscribed?

    created_at + 2.weeks
  end

  def remaining_trial_days
    raise 'Team is subscribed.' if subscribed?

    [0, (trial_ends_at.to_date - Time.now.utc.to_date).to_i].max
  end

  def trial_message
    [
      remaining_trial_days.zero? ? 'Your trial subscription has expired.' : "Your trial subscription expires in #{remaining_trial_days} day#{remaining_trial_days == 1 ? '' : 's'}.",
      subscribe_text
    ].join(' ')
  end

  def inform_trial!
    return if subscribed? || subscription_expired?
    return if trial_informed_at && (Time.now.utc < trial_informed_at + 7.days)

    inform_everyone!(trial_message)
    update_attributes!(trial_informed_at: Time.now.utc)
  end

  def stripe_customer
    return unless stripe_customer_id

    @stripe_customer ||= Stripe::Customer.retrieve(stripe_customer_id)
  end

  def stripe_customer_text
    "Customer since #{Time.at(stripe_customer.created).strftime('%B %d, %Y')}."
  end

  def subscriber_text
    return unless subscribed_at

    "Subscriber since #{subscribed_at.strftime('%B %d, %Y')}."
  end

  def subscribe_text
    "Subscribe your team for $19.99 a year at #{DiscordStrava::Service.url}/subscribe?guild_id=#{guild_id} to continue receiving Strava activities in Discord. Proceeds go to NYRR."
  end

  def stripe_customer_subscriptions_info
    stripe_customer.subscriptions.map do |subscription|
      amount = ActiveSupport::NumberHelper.number_to_currency(subscription.plan.amount.to_f / 100)
      current_period_end = Time.at(subscription.current_period_end).strftime('%B %d, %Y')
      if subscription.status == 'active'
        [
          "Subscribed to #{subscription.plan.name} (#{amount}), will#{subscription.cancel_at_period_end ? ' not' : ''} auto-renew on #{current_period_end}."
        ].compact.join("\n")
      else
        "#{subscription.status.titleize} subscription created #{Time.at(subscription.created).strftime('%B %d, %Y')} to #{subscription.plan.name} (#{amount})."
      end
    end
  end

  def stripe_customer_invoices_info
    stripe_customer.invoices.map do |invoice|
      amount = ActiveSupport::NumberHelper.number_to_currency(invoice.amount_due.to_f / 100)
      "Invoice for #{amount} on #{Time.at(invoice.date).strftime('%B %d, %Y')}, #{invoice.paid ? 'paid' : 'unpaid'}."
    end
  end

  def stripe_customer_sources_info
    stripe_customer.sources.map do |source|
      "On file #{source.brand} #{source.object}, #{source.name} ending with #{source.last4}, expires #{source.exp_month}/#{source.exp_year}."
    end
  end

  def stripe_subcriptions
    return unless stripe_customer

    stripe_customer.subscriptions
  end

  def active_stripe_subscription?
    !active_stripe_subscription.nil?
  end

  def active_stripe_subscription
    return unless stripe_customer

    stripe_customer.subscriptions.detect do |subscription|
      subscription.status == 'active' && !subscription.cancel_at_period_end
    end
  end

  def stats(options = {})
    TeamStats.new(self, options)
  end

  def self.purge!(dt = 2.weeks.ago)
    # destroy teams inactive for two weeks
    Team.where(active: false, :updated_at.lte => dt).each do |team|
      logger.info "Destroying #{team}, inactive since #{team.updated_at}."
      team.destroy
    rescue StandardError => e
      logger.warn "Error destroying #{team}, #{e.message}."
    end
  end

  private

  def destroy_subscribed_team
    raise 'cannot destroy a subscribed team' if subscribed?
  end

  def subscribed!
    return unless subscribed? && subscribed_changed?

    inform_everyone!(subscribed_text)
  end

  def activated_text
    <<~EOS
      Welcome to Strada!
      Type */strada connect* to connect your Strava account to a Discord channel."
    EOS
  end

  def activated!
    return unless active? && active_changed?

    inform_activated!
  end

  def guild_info
    @guild_info ||= Discord::Guilds.info(guild_id)
  end

  def inform_activated!
    return unless ENV.key?('DISCORD_CLIENT_ID') # tests

    inform_system!(activated_text)
  end

  def update_subscribed_at
    return unless subscribed? && subscribed_changed?

    self.subscribed_at = subscribed? ? DateTime.now.utc : nil
  end

  def update_subscription_expired_at
    return unless subscribed? && subscription_expired_at?

    self.subscription_expired_at = nil
  end
end
