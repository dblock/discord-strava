require 'spec_helper'

describe Api::Endpoints::SubscriptionsEndpoint do
  include Api::Test::EndpointTest

  context 'subcriptions' do
    it 'requires stripe parameters' do
      expect { client.subscriptions._post }.to raise_error Faraday::ClientError do |e|
        json = JSON.parse(e.response[:body])
        expect(json['message']).to eq 'Invalid parameters.'
        expect(json['type']).to eq 'param_error'
      end
    end
    context 'subscribed team' do
      let!(:team) { Fabricate(:team, subscribed: true, stripe_customer_id: 'customer_id') }
      it 'fails to create a subscription' do
        expect {
          client.subscriptions._post(
            guild_id: team.guild_id,
            stripe_token: 'token',
            stripe_token_type: 'card',
            stripe_email: 'foo@bar.com'
          )
        }.to raise_error Faraday::ClientError do |e|
          json = JSON.parse(e.response[:body])
          expect(json['error']).to eq 'Already Subscribed'
        end
      end
    end
    context 'non-subscribed team with a customer_id' do
      let!(:team) { Fabricate(:team, stripe_customer_id: 'customer_id') }
      it 'fails to create a subscription' do
        expect {
          client.subscriptions._post(
            guild_id: team.guild_id,
            stripe_token: 'token',
            stripe_token_type: 'card',
            stripe_email: 'foo@bar.com'
          )
        }.to raise_error Faraday::ClientError do |e|
          json = JSON.parse(e.response[:body])
          expect(json['error']).to eq 'Customer Already Registered'
        end
      end
    end
    context 'existing team' do
      let!(:team) { Fabricate(:team) }
      it 'creates a subscription' do
        expect(Stripe::Customer).to receive(:create).with(
          source: 'token',
          plan: 'strada-yearly',
          email: 'foo@bar.com',
          metadata: {
            id: team._id,
            guild_id: team.guild_id,
            name: team.guild_name,
            domain: team.domain
          }
        ).and_return('id' => 'customer_id')
        expect_any_instance_of(Team).to receive(:inform!).once
        expect_any_instance_of(Team).to receive(:inform_guild_owner!).once
        client.subscriptions._post(
          guild_id: team.guild_id,
          stripe_token: 'token',
          stripe_token_type: 'card',
          stripe_email: 'foo@bar.com'
        )
        team.reload
        expect(team.subscribed).to be true
        expect(team.subscribed_at).to_not be nil
        expect(team.stripe_customer_id).to eq 'customer_id'
      end
    end
  end
end
