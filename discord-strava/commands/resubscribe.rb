module DiscordStrava
  module Commands
    class Resubscribe < Discord::Commands::Command
      include DiscordStrava::Commands::Mixins::Subscribe
      include DiscordStrava::Loggable

      subscribe_command 'strada' => 'resubscribe' do |command|
        if !command.team.stripe_customer_id
          logger.info "RESUBSCRIBE: #{command}, resubscribe failed, no subscription"
          "You don't have a paid subscription. #{command.team.subscribe_text}"
        elsif command.user.guild_owner?
          active_subscription = command.team.active_stripe_subscription
          if active_subscription&.cancel_at_period_end
            active_subscription.delete(at_period_end: false)
            amount = ActiveSupport::NumberHelper.number_to_currency(active_subscription.plan.amount.to_f / 100)
            logger.info "RESUBSCRIBE: #{command}, user=#{command.user}, auto-renew #{active_subscription.id}"
            current_period_end = Time.at(active_subscription.current_period_end).strftime('%B %d, %Y')
            "Subscription to #{active_subscription.plan.name} (#{amount}) will now auto-renew on #{current_period_end}."
          elsif active_subscription
            logger.info "RESUBSCRIBE: #{command}, user=#{command.user}, already renewing"
            amount = ActiveSupport::NumberHelper.number_to_currency(active_subscription.plan.amount.to_f / 100)
            current_period_end = Time.at(active_subscription.current_period_end).strftime('%B %d, %Y')
            "Subscription to #{active_subscription.plan.name} (#{amount}) will continue to auto-renew on #{current_period_end}."
          else
            logger.info "RESUBSCRIBE: #{command}, user=#{command.user}"
            "You don't have a paid subscription. #{command.team.subscribe_text}"
          end
        else
          logger.info "RESUBSCRIBE: #{command}, user=#{command.user} resubscribe failed, not admin"
          'Sorry, only a Discord admin can do that.'
        end
      end
    end
  end
end
