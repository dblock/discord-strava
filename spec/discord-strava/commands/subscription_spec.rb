require 'spec_helper'

describe DiscordStrava::Commands::Subscription do
  include_context 'discord command' do
    let(:args) { ['subscription'] }
  end
  shared_examples_for 'subscription' do
    context 'on trial' do
      before do
        team.update_attributes!(subscribed: false, subscribed_at: nil)
      end

      it 'displays subscribe message' do
        expect(response).to eq team.trial_message
      end
    end

    context 'with subscribed_at' do
      it 'displays subscription info' do
        customer_info = "Subscriber since #{team.subscribed_at.strftime('%B %d, %Y')}."
        expect(response).to eq customer_info
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

        before do
          team.update_attributes!(subscribed: true, stripe_customer_id: customer['id'])
        end

        context 'as guild owner' do
          before do
            allow_any_instance_of(User).to receive(:guild_owner?).and_return(true)
          end

          it 'displays subscription info' do
            card = customer.sources.first
            current_period_end = Time.at(customer.subscriptions.first.current_period_end).strftime('%B %d, %Y')
            customer_info = [
              "Customer since #{Time.at(customer.created).strftime('%B %d, %Y')}.",
              "Subscribed to Plan ($19.99), will auto-renew on #{current_period_end}.",
              "On file Visa card, #{card.name} ending with #{card.last4}, expires #{card.exp_month}/#{card.exp_year}.",
              team.update_cc_text
            ].join("\n")
            expect(response).to eq customer_info
          end

          context 'past due subscription' do
            before do
              customer.subscriptions.data.first['status'] = 'past_due'
              allow(Stripe::Customer).to receive(:retrieve).and_return(customer)
            end

            it 'displays subscription info' do
              card = customer.sources.first
              current_period_end = Time.at(customer.subscriptions.first.current_period_end).strftime('%B %d, %Y')
              customer_info = [
                "Customer since #{Time.at(customer.created).strftime('%B %d, %Y')}.",
                'Past Due subscription created November 03, 2016 to Plan ($19.99).',
                "On file Visa card, #{card.name} ending with #{card.last4}, expires #{card.exp_month}/#{card.exp_year}.",
                team.update_cc_text
              ].join("\n")
              expect(response).to eq customer_info
            end
          end
        end

        context 'as a regular user' do
          before do
            allow_any_instance_of(User).to receive(:guild_owner?).and_return(false)
          end

          it 'displays subscription info' do
            card = customer.sources.first
            current_period_end = Time.at(customer.subscriptions.first.current_period_end).strftime('%B %d, %Y')
            customer_info = [
              "Customer since #{Time.at(customer.created).strftime('%B %d, %Y')}.",
              "Subscribed to Plan ($19.99), will auto-renew on #{current_period_end}."
            ].join("\n")
            expect(response).to eq customer_info
          end
        end
      end
    end
  end

  context 'subscribed team' do
    let!(:team) { Fabricate(:team, subscribed: true, guild_owner_id: 'U007') }

    it_behaves_like 'subscription'
    context 'with another team' do
      let!(:team2) { Fabricate(:team) }

      it_behaves_like 'subscription'
    end
  end
end
