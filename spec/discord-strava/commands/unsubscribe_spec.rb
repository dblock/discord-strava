require 'spec_helper'

describe DiscordStrava::Commands::Unsubscribe do
  let(:app) { DiscordStrava::Server.new(team: team) }
  let(:client) { app.send(:client) }
  shared_examples_for 'unsubscribe' do
    context 'on trial' do
      before do
        team.update_attributes!(subscribed: false, subscribed_at: nil)
      end
      it 'displays all set message' do
        expect(message: "#{DiscordRubyBot.config.user} unsubscribe").to respond_with_discord_message "You don't have a paid subscription, all set."
      end
    end
    context 'with subscribed_at' do
      before do
        team.update_attributes!(subscribed: true, subscribed_at: 1.year.ago)
      end
      it 'displays subscription info' do
        expect(message: "#{DiscordRubyBot.config.user} unsubscribe").to respond_with_discord_message "You don't have a paid subscription, all set."
      end
    end
    context 'with a plan' do
      include_context :stripe_mock
      before do
        stripe_helper.create_plan(id: 'discord-playplay-yearly', amount: 2999, name: 'Plan')
      end
      context 'a customer' do
        let!(:customer) do
          Stripe::Customer.create(
            source: stripe_helper.generate_card_token,
            plan: 'discord-playplay-yearly',
            email: 'foo@bar.com'
          )
        end
        let(:activated_user) { Fabricate(:user) }
        before do
          team.update_attributes!(
            subscribed: true,
            stripe_customer_id: customer['id'],
            guild_owner_id: activated_user.user_id
          )
        end
        let(:active_subscription) { team.active_stripe_subscription }
        let(:current_period_end) { Time.at(active_subscription.current_period_end).strftime('%B %d, %Y') }
        it 'displays subscription info' do
          customer_info = [
            "Subscribed to Plan ($29.99), will auto-renew on #{current_period_end}.",
            "Send `unsubscribe #{active_subscription.id}` to unsubscribe."
          ].join("\n")
          expect(message: "#{DiscordRubyBot.config.user} unsubscribe", user: activated_user.user_name).to respond_with_discord_message customer_info
        end
        it 'cannot unsubscribe with an invalid subscription id' do
          expect(message: "#{DiscordRubyBot.config.user} unsubscribe xyz", user: activated_user.user_name).to respond_with_discord_message 'Sorry, I cannot find a subscription with "xyz".'
        end
        it 'unsubscribes' do
          expect(message: "#{DiscordRubyBot.config.user} unsubscribe #{active_subscription.id}", user: activated_user.user_name).to respond_with_discord_message 'Successfully canceled auto-renew for Plan ($29.99).'
          team.reload
          expect(team.subscribed).to be true
          expect(team.stripe_customer_id).to_not be nil
        end
        context 'not an admin' do
          let!(:user) { Fabricate(:user, team: team) }
          before do
            expect(User).to receive(:find_create_or_update_by_discord_id!).and_return(user)
          end
          it 'cannot unsubscribe' do
            expect(message: "#{DiscordRubyBot.config.user} unsubscribe xyz").to respond_with_discord_message "Sorry, only <@#{activated_user.user_id}> or a Discord admin can do that."
          end
        end
      end
    end
  end
  context 'subscribed team' do
    let!(:team) { Fabricate(:team, subscribed: true) }
    let!(:activated_user) { Fabricate(:user, team: team) }
    before do
      team.update_attributes!(guild_owner_id: activated_user.user_id)
    end
    it_behaves_like 'unsubscribe'
    context 'with another team' do
      let!(:team2) { Fabricate(:team) }
      it_behaves_like 'unsubscribe'
    end
  end
end
