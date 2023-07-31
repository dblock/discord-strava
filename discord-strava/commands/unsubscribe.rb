module DiscordStrava
  module Commands
    class Unsubscribe < Discord::Commands::Command
      include DiscordStrava::Commands::Mixins::Subscribe
      include DiscordStrava::Loggable

      subscribe_command 'strada' => 'unsubscribe' do |command|
        if !command.team.stripe_customer_id
          logger.info "UNSUBSCRIBE: #{command}, unsubscribe failed, no subscription"
          "You don't have a paid subscription, all set."
        elsif command.user.team_admin? && command.team.active_stripe_subscription?
          subscription_id = 'TODO' # match['expression']
          active_subscription = command.team.active_stripe_subscription
          if active_subscription && active_subscription.id == subscription_id
            active_subscription.delete(at_period_end: true)
            amount = ActiveSupport::NumberHelper.number_to_currency(active_subscription.plan.amount.to_f / 100)
            logger.info "UNSUBSCRIBE: #{command}, user=#{command.user}, canceled #{subscription_id}"
            "Successfully canceled auto-renew for #{active_subscription.plan.name} (#{amount})."
          elsif subscription_id
            logger.info "UNSUBSCRIBE: #{command}, user=#{command.user}, cannot find a subscription \"#{subscription_id}\""
            "Sorry, I cannot find a subscription with \"#{subscription_id}\"."
          else
            logger.info "UNSUBSCRIBE: #{command}, user=#{command.user}"
            command.team.stripe_customer_subscriptions_info(true)
          end
        else
          logger.info "UNSUBSCRIBE: #{command}, user=#{command.user} unsubscribe failed, not admin"
          "Sorry, only an admin can do that."
        end
      end
    end
  end
end
