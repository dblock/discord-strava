module DiscordStrava
  module Commands
    class Subscription < Discord::Commands::Command
      include DiscordStrava::Commands::Mixins::Subscribe
      include DiscordStrava::Loggable

      subscribe_command 'strada' => 'subscription' do |command|
        logger.info "SUBSCRIPTION: #{command}"
        command.team.subscription_info(command.user.guild_owner?)
      end
    end
  end
end
