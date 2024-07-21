module DiscordStrava
  module Commands
    class Unsubscribe < Discord::Commands::Command
      include DiscordStrava::Commands::Mixins::Subscribe
      include DiscordStrava::Loggable

      subscribe_command 'strada' => 'unsubscribe' do |command|
        if !command.team.stripe_customer_id
          logger.info "UNSUBSCRIBE: #{command}, unsubscribe failed, no subscription"
          "You don't have a paid subscription, all set."
        elsif command.user.guild_owner?
          active_subscription = command.team.active_stripe_subscription
          if active_subscription && !active_subscription.cancel_at_period_end
            active_subscription.delete(at_period_end: true)
            logger.info "UNSUBSCRIBE: #{command}, user=#{command.user}, canceled #{active_subscription.id}"
            amount = ActiveSupport::NumberHelper.number_to_currency(active_subscription.plan.amount.to_f / 100)
            current_period_end = Time.at(active_subscription.current_period_end).strftime('%B %d, %Y')
            "Successfully canceled auto-renew to #{active_subscription.plan.name} (#{amount}), will expire on #{current_period_end}, and will not auto-renew."
          elsif active_subscription
            logger.info "UNSUBSCRIBE: #{command}, user=#{command.user}, already canceled #{active_subscription.id}"
            amount = ActiveSupport::NumberHelper.number_to_currency(active_subscription.plan.amount.to_f / 100)
            current_period_end = Time.at(active_subscription.current_period_end).strftime('%B %d, %Y')
            "Subscription to #{active_subscription.plan.name} (#{amount}) is already set to expire on #{current_period_end}, and will not auto-renew."
          else
            logger.info "UNSUBSCRIBE: #{command}, user=#{command.user}"
            "You don't have a paid subscription. #{command.team.subscribe_text}"
          end
        else
          logger.info "UNSUBSCRIBE: #{command}, user=#{command.user} unsubscribe failed, not admin"
          'Sorry, only a Discord admin can do that.'
        end
      end
    end
  end
end
