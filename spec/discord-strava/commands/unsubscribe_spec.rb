require 'spec_helper'

describe DiscordStrava::Commands::Unsubscribe do
  include_context 'discord command' do
    let(:args) { ['unsubscribe'] }
  end
  shared_examples_for 'unsubscribe' do
    context 'on trial' do
      before do
        team.update_attributes!(subscribed: false, subscribed_at: nil)
      end

      it 'displays all set message' do
        expect(response).to eq "You don't have a paid subscription, all set."
      end
    end

    context 'with subscribed_at' do
      before do
        team.update_attributes!(subscribed: true, subscribed_at: 1.year.ago)
      end

      it 'displays subscription info' do
        expect(response).to eq "You don't have a paid subscription, all set."
      end
    end

    context 'with a plan' do
      include_context 'stripe mock'
      before do
        stripe_helper.create_plan(id: 'discord-playplay-yearly', amount: 1999, name: 'Plan')
      end

      context 'a customer' do
        let!(:customer) do
          Stripe::Customer.create(
            source: stripe_helper.generate_card_token,
            plan: 'discord-playplay-yearly',
            email: 'foo@bar.com'
          )
        end
        let(:active_subscription) { team.active_stripe_subscription }
        let(:current_period_end) { Time.at(active_subscription.current_period_end).strftime('%B %d, %Y') }

        before do
          team.update_attributes!(
            subscribed: true,
            stripe_customer_id: customer['id'],
            guild_owner_id: activated_user.user_id
          )
        end

        context 'subscription that ends at period end' do
          before do
            active_subscription.delete(at_period_end: true)
          end

          context 'not a guild owner' do
            before do
              allow_any_instance_of(User).to receive(:guild_owner?).and_return(false)
            end

            it 'cannot unsubscribe' do
              expect(response).to eq 'Sorry, only a Discord admin can do that.'
            end
          end

          context 'guild owner' do
            before do
              allow_any_instance_of(User).to receive(:guild_owner?).and_return(true)
            end

            it 'displays that the subscription is already set to expire' do
              expect(response).to eq "Subscription to Plan ($19.99) is already set to expire on #{current_period_end}, and will not auto-renew."
            end
          end
        end

        context 'guild owner' do
          before do
            allow_any_instance_of(User).to receive(:guild_owner?).and_return(true)
          end

          it 'unsubscribes' do
            expect(response).to eq "Successfully canceled auto-renew to Plan ($19.99), will expire on #{current_period_end}, and will not auto-renew."
            team.reload
            expect(team.subscribed).to be true
            expect(team.stripe_customer_id).not_to be_nil
          end
        end

        context 'not a guild owner' do
          before do
            allow_any_instance_of(User).to receive(:guild_owner?).and_return(false)
          end

          it 'cannot unsubscribe' do
            expect(response).to eq 'Sorry, only a Discord admin can do that.'
          end
        end
      end
    end
  end

  context 'subscribed team' do
    let!(:team) { Fabricate(:team, subscribed: true) }
    let!(:activated_user) { Fabricate(:user, team:) }

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
