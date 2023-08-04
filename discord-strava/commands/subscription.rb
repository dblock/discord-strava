module DiscordStrava
  module Commands
    class Subscription < Discord::Commands::Command
      include DiscordStrava::Commands::Mixins::Subscribe
      include DiscordStrava::Loggable

      subscribe_command 'strada' => 'subscription' do |command|
        logger.info "SUBSCRIPTION: #{command}"
        subscription_info = []
        if command.team.active_stripe_subscription?
          subscription_info << command.team.stripe_customer_text
          subscription_info.concat(command.team.stripe_customer_subscriptions_info)
          if command.user.guild_owner?
            subscription_info.concat(command.team.stripe_customer_invoices_info)
            subscription_info.concat(command.team.stripe_customer_sources_info)
            subscription_info << command.team.update_cc_text
          end
        elsif command.team.subscribed && command.team.subscribed_at
          subscription_info << command.team.subscriber_text
        else
          subscription_info << command.team.trial_message
        end
        subscription_info.compact.join("\n")
      end
    end
  end
end
