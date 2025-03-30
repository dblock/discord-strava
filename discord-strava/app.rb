module DiscordStrava
  class App
    include DiscordStrava::Loggable

    def prepare!
      check_database!
      init_database!
      install_commands!
      purge_inactive_teams!
    end

    def self.instance
      @instance ||= new
    end

    def check_database!
      rc = Mongoid.default_client.command(ping: 1)
      return if rc&.ok?

      raise rc.documents.first['error'] || 'Unexpected error.'
    rescue StandardError => e
      warn "Error connecting to MongoDB: #{e.message}"
      raise e
    end

    def init_database!
      # create indexes
      ::Mongoid::Tasks::Database.create_indexes
      # silence loggers
      Mongoid.logger.level = Logger::INFO
      Mongo::Logger.logger.level = Logger::INFO
    end

    def install_commands!
      Discord::Commands.install!(
        File.expand_path(
          File.join(__dir__, 'commands/*.json')
        )
      )
    end

    def purge_inactive_teams!
      Team.purge!
    end

    def after_start!
      ::Async::Reactor.run do
        ensure_strava_webhook!
        logger.info 'Starting crons.'
        once_and_every 60 * 60 * 24 do
          check_access!
          check_subscribed_teams!
          check_stripe_subscribers!
          deactivate_asleep_teams!
          refresh_discord_tokens!
          check_trials!
          prune_activities!
          aggregate_stats!
        end
        once_and_every 60 * 60 do
          expire_subscriptions!
        end
        continuously 60 do |task, tt|
          users_brag_and_rebrag!(task, tt)
        end
      end
    end

    private

    def log_info_without_repeat(message)
      return if message == @log_message

      @log_message = message
      logger.info message
    end

    def once_and_every(tt, &)
      ::Async::Reactor.run do |task|
        loop do
          yield
        rescue StandardError => e
          logger.error e
          NewRelic::Agent.notice_error(e)
        ensure
          task.sleep tt
        end
      end
    end

    def continuously(tt, &)
      ::Async::Reactor.run do |task|
        loop do
          yield task, tt
        rescue StandardError => e
          logger.error e
          NewRelic::Agent.notice_error(e)
        ensure
          task.sleep tt
        end
      end
    end

    def ensure_strava_webhook!
      return if DiscordStrava::Service.localhost?

      logger.info 'Ensuring Strava webhook.'
      StravaWebhook.instance.ensure!
    rescue StandardError => e
      logger.warn "Error ensuring Strava webhook, #{e.message}."
      NewRelic::Agent.notice_error(e)
    end

    def check_trials!
      log_info_without_repeat "Checking trials for #{Team.active.trials.count} team(s)."
      Team.active.trials.each do |team|
        logger.info "Team #{team} has #{team.remaining_trial_days} trial days left."
        next unless team.remaining_trial_days > 0 && team.remaining_trial_days <= 3

        team.inform_trial!
      rescue StandardError => e
        logger.warn "Error checking team #{team} trial, #{e.message}."
        NewRelic::Agent.notice_error(e, custom_params: { team: team.to_s })
      end
    rescue StandardError => e
      logger.warn "Error checking trials, #{e.message}."
      NewRelic::Agent.notice_error(e)
    end

    def prune_activities!
      total = 0
      log_info_without_repeat "Pruning activities for #{Team.count} team(s)."
      Team.each do |team|
        total += team.prune_activities!
      rescue StandardError => e
        logger.warn "Error pruning team #{team}, #{e.message}."
        NewRelic::Agent.notice_error(e, custom_params: { team: team.to_s })
      end
      log_info_without_repeat "Pruned #{total}/#{Activity.count} activities."
    end

    def aggregate_stats!
      SystemStats.aggregate!
    end

    def check_access!
      log_info_without_repeat "Checking access for #{Team.active.count} team(s)."
      Team.active.each do |team|
        team.check_access!
      rescue StandardError => e
        backtrace = e.backtrace.join("\n")
        logger.warn "Error checking access for team #{team}, #{e.message}, #{backtrace}."
        NewRelic::Agent.notice_error(e, custom_params: { team: team.to_s })
      end
    end

    def refresh_discord_tokens!
      Team.active.each do |team|
        team.refresh_token!
      rescue StandardError => e
        backtrace = e.backtrace.join("\n")
        logger.warn "Error refreshing Discord token for team #{team}, #{e.message}, #{backtrace}."
        NewRelic::Agent.notice_error(e, custom_params: { team: team.to_s })
      end
    rescue StandardError => e
      logger.warn "Error refreshing Discord tokens, #{e.message}."
      NewRelic::Agent.notice_error(e)
    end

    def expire_subscriptions!
      log_info_without_repeat "Checking subscriptions for #{Team.active.count} team(s)."
      Team.active.each do |team|
        next unless team.subscription_expired?

        team.subscription_expired!
      rescue StandardError => e
        backtrace = e.backtrace.join("\n")
        logger.warn "Error in expire subscriptions cron for team #{team}, #{e.message}, #{backtrace}."
        NewRelic::Agent.notice_error(e, custom_params: { team: team.to_s })
      end
    rescue StandardError => e
      logger.warn "Error expiring subscriptions, #{e.message}."
      NewRelic::Agent.notice_error(e)
    end

    def users_brag_and_rebrag!(task, tt)
      log_info_without_repeat "Checking user activities for #{Team.active.count} team(s)."
      Team.no_timeout.active.each do |team|
        next if team.subscription_expired?
        next unless team.users.connected_to_strava.any?

        log_info_without_repeat "Checking user activities for #{team}, #{team.users.connected_to_strava.count} user(s)."

        begin
          team.users.connected_to_strava.each do |user|
            user.sync_and_brag!
            task.sleep tt
            user.rebrag!
            task.sleep tt
          rescue StandardError => e
            backtrace = e.backtrace.join("\n")
            logger.warn "Error in brag cron for user #{user}, #{e.message}, #{backtrace}."
            NewRelic::Agent.notice_error(e, custom_params: { user: user.to_s })
          end
        rescue StandardError => e
          backtrace = e.backtrace.join("\n")
          logger.warn "Error in brag cron for team #{team}, #{e.message}, #{backtrace}."
          NewRelic::Agent.notice_error(e, custom_params: { team: team.to_s })
        end
      end
    rescue StandardError => e
      logger.warn "Error checking user activities, #{e.message}."
      NewRelic::Agent.notice_error(e)
    end

    def deactivate_asleep_teams!
      log_info_without_repeat "Checking inactivity for #{Team.active.count} team(s)."
      Team.active.each do |team|
        next unless team.asleep?

        begin
          team.deactivate!
          purge_message = "Your subscription expired more than 2 weeks ago, deactivating. Reactivate at #{DiscordStrava::Service.url}. Your data will be purged in another 2 weeks."
          team.inform_everyone!(purge_message)
        rescue StandardError => e
          logger.warn "Error informing team #{team}, #{e.message}."
          NewRelic::Agent.notice_error(e, custom_params: { team: team.to_s })
        end
      end
    rescue StandardError => e
      logger.warn "Error checking team inactivity, #{e.message}."
      NewRelic::Agent.notice_error(e)
    end

    def check_subscribed_teams!
      logger.info "Checking Stripe subscriptions for #{Team.striped.count} team(s)."
      Team.striped.each do |team|
        customer = Stripe::Customer.retrieve(team.stripe_customer_id)
        if customer.subscriptions.none?
          logger.info "No active subscriptions for #{team} (#{team.stripe_customer_id}), downgrading."
          team.inform! 'Your subscription was canceled and your team has been downgraded. Thank you for being a customer!'
          team.update_attributes!(subscribed: false)
        else
          customer.subscriptions.each do |subscription|
            subscription_name = "#{subscription.plan.name} (#{ActiveSupport::NumberHelper.number_to_currency(subscription.plan.amount.to_f / 100)})"
            logger.info "Checking #{team} subscription to #{subscription_name}, #{subscription.status}."
            case subscription.status
            when 'past_due'
              logger.warn "Subscription for #{team} is #{subscription.status}, notifying."
              team.inform_everyone!("Your subscription to #{subscription_name} is past due. #{team.update_cc_text}")
            when 'canceled', 'unpaid'
              logger.warn "Subscription for #{team} is #{subscription.status}, downgrading."
              team.inform_everyone!("Your subscription to #{subscription.plan.name} (#{ActiveSupport::NumberHelper.number_to_currency(subscription.plan.amount.to_f / 100)}) was canceled and your team has been downgraded. Thank you for being a customer!")
              team.update_attributes!(subscribed: false)
            end
          end
        end
      rescue StandardError => e
        logger.warn "Error checking team #{team} subscription, #{e.message}."
        NewRelic::Agent.notice_error(e, custom_params: { team: team.to_s })
      end
    rescue StandardError => e
      logger.warn "Error checking Stripe subscriptions, #{e.message}."
      NewRelic::Agent.notice_error(e)
    end

    def check_stripe_subscribers!
      Stripe::Subscription.list(plan: 'strada-yearly').auto_paging_each do |subscription|
        customer = Stripe::Customer.retrieve(subscription.customer)
        metadata = customer.metadata

        team = Team.where(stripe_customer_id: subscription.customer).first
        team ||= Team.where(team_id: metadata.guild_id).first

        next if team&.subscribed? && team.active?

        if team
          if team.active?
            logger.warn "Re-associating customer_id for #{metadata.name} (#{metadata.guild_id}) with #{team}."
            team.update_attributes!(stripe_customer_id: subscription.customer, subscribed: true)
          elsif team.active_stripe_subscription
            logger.warn "Inactive team #{team} for #{metadata.name} (#{metadata.guild_id})."
            active_subscription = team.active_stripe_subscription
            active_subscription.delete(at_period_end: true)
            amount = ActiveSupport::NumberHelper.number_to_currency(active_subscription.plan.amount.to_f / 100)
            logger.warn "Successfully canceled auto-renew for #{active_subscription.plan.name} (#{amount}) for #{team}."
          else
            logger.warn "Inactive team #{team} for #{metadata.name} (#{metadata.guild_id}), no active subscription."
          end
        else
          logger.warn "Cannot find team for #{metadata.name} (#{metadata.guild_id}), contact #{customer.email}."
        end
      rescue StandardError => e
        logger.warn "Error checking customer #{subscription.customer}, #{e.message}."
        NewRelic::Agent.notice_error(e, custom_params: { customer: subscription.customer })
      end
    rescue StandardError => e
      logger.warn "Error checking Stripe subscribers, #{e.message}."
      NewRelic::Agent.notice_error(e)
    end
  end
end
