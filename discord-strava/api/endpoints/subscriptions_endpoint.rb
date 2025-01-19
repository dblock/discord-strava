module Api
  module Endpoints
    class SubscriptionsEndpoint < Grape::API
      format :json

      namespace :subscriptions do
        desc 'Subscribe to discord-strava.'
        params do
          requires :stripe_token, type: String
          requires :stripe_token_type, type: String
          requires :stripe_email, type: String
          requires :guild_id, type: String
        end
        post do
          team = Team.where(guild_id: params[:guild_id]).first || error!('Team Not Found', 404)
          Api::Middleware.logger.info "Creating a subscription for team #{team}."
          error!('Already Subscribed', 400) if team.subscribed?
          error!('Customer Already Registered', 400) if team.stripe_customer_id
          customer = Stripe::Customer.create(
            source: params[:stripe_token],
            plan: 'strada-yearly',
            email: params[:stripe_email],
            metadata: {
              id: team._id,
              guild_id: team.guild_id,
              name: team.guild_name
            }
          )
          Api::Middleware.logger.info "Subscription for team #{team} created, stripe_customer_id=#{customer['id']}, active=#{team.active}."
          team.update_attributes!(subscribed: true, active: true, subscribed_at: Time.now.utc, stripe_customer_id: customer['id'])
          present team, with: Api::Presenters::TeamPresenter
        end
      end
    end
  end
end
