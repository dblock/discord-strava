module DiscordStrava
  module Commands
    module Mixins
      module Subscribe
        extend ActiveSupport::Concern

        module ClassMethods
          def subscribe_command(*values, &)
            command(*values) do |command|
              if Stripe.api_key && command.team.reload.subscription_expired?
                logger.info "#{command}, subscribed feature required"
                command.team.trial_message
              else
                yield command
              end
            end
          end
        end
      end
    end
  end
end
