require 'spec_helper'

describe DiscordStrava::Commands::Disconnect do
  include_context 'discord command' do
    let(:args) { ['disconnect'] }
  end
  context 'disconnect' do
    it 'requires a subscription' do
      expect(response).to eq team.trial_message
    end

    context 'subscribed team' do
      let(:team) { Fabricate(:team, subscribed: true) }

      context 'connected user' do
        let(:user) { Fabricate(:user, team: team, access_token: 'token', token_type: 'Bearer') }

        it 'disconnects a user' do
          expect(response).to eq 'Your Strava account has been successfully disconnected.'
          user.reload
          expect(user.access_token).to be_nil
          expect(user.connected_to_strava_at).to be_nil
          expect(user.token_type).to be_nil
        end
      end

      context 'disconnected user' do
        let(:user) { Fabricate(:user, team: team) }

        it 'fails to disconnect a user' do
          expect(response).to eq 'Your Strava account is not connected.'
        end
      end
    end
  end
end
