require 'spec_helper'

describe DiscordStrava::Commands::Disconnect do
  context 'self' do
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
          let(:user) { Fabricate(:user, team:, access_token: 'token', token_type: 'Bearer') }

          it 'disconnects a user' do
            expect_any_instance_of(User).to receive(:refresh_access_token!)
            expect_any_instance_of(Strava::Api::Client).to receive(:deauthorize).and_return(Hashie::Mash.new(access_token: 'token'))
            expect(response).to eq 'Strava account successfully disconnected.'
            user.reload
            expect(user.access_token).to be_nil
            expect(user.connected_to_strava_at).to be_nil
            expect(user.token_type).to be_nil
          end
        end

        context 'disconnected user' do
          let(:user) { Fabricate(:user, team:) }

          it 'fails to disconnect a user' do
            expect(response).to eq 'Strava account is not connected.'
          end
        end
      end

      context 'unsubscribed team' do
        context 'connected user' do
          let(:user) { Fabricate(:user, team:, access_token: 'token', token_type: 'Bearer') }

          it 'requires a subscription' do
            expect_any_instance_of(User).not_to receive(:refresh_access_token!)
            expect_any_instance_of(Strava::Api::Client).not_to receive(:deauthorize)
            expect(response).to include 'Your trial subscription has expired.'
          end
        end
      end
    end
  end

  context 'another connected user' do
    let(:another_user) { Fabricate(:user, team:, access_token: 'token', token_type: 'Bearer', connected_to_strava_at: Time.now.utc) }

    include_context 'discord command' do
      let(:args) { ['disconnect', { 'user' => another_user.user_id }] }
    end

    context 'subscribed team' do
      let(:team) { Fabricate(:team, subscribed: true) }

      context 'disconnect' do
        context 'admin' do
          before do
            allow_any_instance_of(User).to receive(:guild_owner?).and_return(true)
          end

          it 'disconnects the user' do
            expect_any_instance_of(User).to receive(:refresh_access_token!)
            expect_any_instance_of(Strava::Api::Client).to receive(:deauthorize).and_return(Hashie::Mash.new(access_token: 'token'))
            expect(response).to eq "Strava account for user #{another_user.discord_mention} successfully disconnected."
            another_user.reload
            expect(another_user.access_token).to be_nil
            expect(another_user.connected_to_strava_at).to be_nil
            expect(another_user.token_type).to be_nil
          end
        end

        context 'not an admin' do
          before do
            allow_any_instance_of(User).to receive(:guild_owner?).and_return(false)
          end

          it 'does not disconnect the user' do
            expect_any_instance_of(User).not_to receive(:refresh_access_token!)
            expect_any_instance_of(Strava::Api::Client).not_to receive(:deauthorize)
            expect(response).to eq 'Sorry, only a Discord admin can disconnect other users.'
            another_user.reload
            expect(another_user.access_token).not_to be_nil
            expect(another_user.connected_to_strava_at).not_to be_nil
            expect(another_user.token_type).not_to be_nil
          end
        end
      end
    end
  end

  context 'an invalid user' do
    let(:another_user) { Fabricate(:user, team:, access_token: 'token', token_type: 'Bearer', connected_to_strava_at: Time.now.utc) }

    include_context 'discord command' do
      let(:args) { ['disconnect', { 'user' => 'invalid' }] }
    end

    context 'subscribed team' do
      let(:team) { Fabricate(:team, subscribed: true) }

      context 'disconnect' do
        context 'admin' do
          before do
            allow_any_instance_of(User).to receive(:guild_owner?).and_return(true)
          end

          it 'cannot disconnect the user' do
            expect_any_instance_of(User).not_to receive(:refresh_access_token!)
            expect_any_instance_of(Strava::Api::Client).not_to receive(:deauthorize)
            expect(response).to eq 'I cannot find the user <@invalid>, sorry.'
            another_user.reload
            expect(another_user.access_token).not_to be_nil
            expect(another_user.connected_to_strava_at).not_to be_nil
            expect(another_user.token_type).not_to be_nil
          end
        end
      end
    end
  end

  context 'a user in another team' do
    let(:another_user) { Fabricate(:user, team: Fabricate(:team), access_token: 'token', token_type: 'Bearer', connected_to_strava_at: Time.now.utc) }

    include_context 'discord command' do
      let(:args) { ['disconnect', { 'user' => another_user.user_id }] }
    end

    context 'subscribed team' do
      let(:team) { Fabricate(:team, subscribed: true) }

      context 'disconnect' do
        context 'admin' do
          before do
            allow_any_instance_of(User).to receive(:guild_owner?).and_return(true)
          end

          it 'cannot disconnect the user' do
            expect_any_instance_of(User).not_to receive(:refresh_access_token!)
            expect_any_instance_of(Strava::Api::Client).not_to receive(:deauthorize)
            expect(response).to eq "I cannot find the user #{another_user.discord_mention}, sorry."
            another_user.reload
            expect(another_user.access_token).not_to be_nil
            expect(another_user.connected_to_strava_at).not_to be_nil
            expect(another_user.token_type).not_to be_nil
          end
        end
      end
    end
  end
end
