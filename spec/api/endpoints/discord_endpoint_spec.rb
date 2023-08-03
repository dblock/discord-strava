require 'spec_helper'

describe Api::Endpoints::DiscordEndpoint do
  include Api::Test::EndpointTest

  context 'with a SLACK_VERIFICATION_TOKEN' do
    let(:token) { 'discord-verification-token' }
    let(:team) { Fabricate(:team) }
    before do
      ENV['SLACK_VERIFICATION_TOKEN'] = token
    end
    context 'interactive buttons' do
      let(:user) { Fabricate(:user, team: team, access_token: 'token', token_expires_at: Time.now + 1.day) }
      it 'returns an error with a non-matching verification token' do
        post '/api/discord/action', payload: {
          actions: [{ name: 'strava_id', value: '43749' }],
          channel: { id: 'C1', name: 'runs' },
          user: { id: user.user_id },
          team: { id: team.guild_id },
          callback_id: 'invalid-callback',
          token: 'invalid-token'
        }.to_json
        expect(last_response.status).to eq 401
        response = JSON.parse(last_response.body)
        expect(response['error']).to eq 'Message token is not coming from Discord.'
      end
      it 'returns invalid callback id' do
        post '/api/discord/action', payload: {
          actions: [{ name: 'strava_id', value: 'id' }],
          channel: { id: 'C1', name: 'runs' },
          user: { id: user.user_id },
          team: { id: team.guild_id },
          callback_id: 'invalid-callback',
          token: token
        }.to_json
        expect(last_response.status).to eq 404
        response = JSON.parse(last_response.body)
        expect(response['error']).to eq 'Callback invalid-callback is not supported.'
      end
    end
    context 'slash commands' do
      let(:user) { Fabricate(:user, team: team) }
      context 'stats' do
        it 'returns team stats' do
          post '/api/discord/command',
               command: '/strada',
               text: 'stats',
               channel_id: 'channel',
               channel_name: 'channel_name',
               user_id: user.user_id,
               guild_id: team.guild_id,
               token: token
          expect(last_response.status).to eq 201
          response = JSON.parse(last_response.body)
          expect(response).to eq(
            'text' => 'There are no activities in this channel.',
            'user' => user.user_id,
            'channel' => 'channel'
          )
        end
        it 'calls stats with channel' do
          expect_any_instance_of(Team).to receive(:stats).with(channel_id: 'channel_id')
          post '/api/discord/command',
               command: '/strada',
               text: 'stats',
               channel_id: 'channel_id',
               channel_name: 'channel_name',
               user_id: user.user_id,
               guild_id: team.guild_id,
               token: token
        end
        it 'calls stats without channel on a DM' do
          expect_any_instance_of(Team).to receive(:stats).with({})
          post '/api/discord/command',
               command: '/strada',
               text: 'stats',
               channel_id: 'DM',
               channel_name: 'channel_name',
               user_id: user.user_id,
               guild_id: team.guild_id,
               token: token
        end
      end
      it 'returns an error with a non-matching verification token' do
        post '/api/discord/command',
             command: '/strada',
             text: 'clubs',
             channel_id: 'C1',
             channel_name: 'channel_1',
             user_id: 'user_id',
             guild_id: 'guild_id',
             token: 'invalid-token'
        expect(last_response.status).to eq 401
        response = JSON.parse(last_response.body)
        expect(response['error']).to eq 'Message token is not coming from Discord.'
      end
      it 'provides a connect link' do
        post '/api/discord/command',
             command: '/strada',
             text: 'connect',
             channel_id: 'channel',
             channel_name: 'channel_1',
             user_id: user.user_id,
             guild_id: team.guild_id,
             token: token
        expect(last_response.status).to eq 201
        url = "https://www.strava.com/oauth/authorize?client_id=client-id&redirect_uri=https://strada.playplay.io/connect&response_type=code&scope=activity:read_all&state=#{user.id}"
        expect(last_response.body).to eq({
          text: 'Please connect your Strava account.',
          attachments: [{
            fallback: "Please connect your Strava account at #{url}.",
            actions: [{
              type: 'button',
              text: 'Click Here',
              url: url
            }]
          }],
          user: user.user_id,
          channel: 'channel'
        }.to_json)
      end
      it 'attempts to disconnect' do
        post '/api/discord/command',
             command: '/strada',
             text: 'disconnect',
             channel_id: 'channel',
             channel_name: 'channel_name',
             user_id: user.user_id,
             guild_id: team.guild_id,
             token: token
        expect(last_response.status).to eq 201
        expect(last_response.body).to eq({
          text: 'Your Strava account is not connected.',
          user: user.user_id,
          channel: 'channel'
        }.to_json)
      end
    end
    context 'discord events' do
      let(:user) { Fabricate(:user, team: team) }
      it 'returns an error with a non-matching verification token' do
        post '/api/discord/event',
             type: 'url_verification',
             challenge: 'challenge',
             token: 'invalid-token'
        expect(last_response.status).to eq 401
        response = JSON.parse(last_response.body)
        expect(response['error']).to eq 'Message token is not coming from Discord.'
      end
      it 'performs event challenge' do
        post '/api/discord/event',
             type: 'url_verification',
             challenge: 'challenge',
             token: token
        expect(last_response.status).to eq 201
        response = JSON.parse(last_response.body)
        expect(response).to eq('challenge' => 'challenge')
      end
    end
    after do
      ENV.delete('SLACK_VERIFICATION_TOKEN')
    end
  end
  context 'with a dev discord verification token' do
    let(:token) { 'discord-verification-token' }
    let(:team) { Fabricate(:team) }
    before do
      ENV['SLACK_VERIFICATION_TOKEN_DEV'] = token
    end
    after do
      ENV.delete('SLACK_VERIFICATION_TOKEN_DEV')
    end
    context 'discord events' do
      let(:user) { Fabricate(:user, team: team) }
      it 'returns an error with a non-matching verification token' do
        post '/api/discord/event',
             type: 'url_verification',
             challenge: 'challenge',
             token: 'invalid-token'
        expect(last_response.status).to eq 401
        response = JSON.parse(last_response.body)
        expect(response['error']).to eq 'Message token is not coming from Discord.'
      end
      it 'performs event challenge' do
        post '/api/discord/event',
             type: 'url_verification',
             challenge: 'challenge',
             token: token
        expect(last_response.status).to eq 201
        response = JSON.parse(last_response.body)
        expect(response).to eq('challenge' => 'challenge')
      end
    end
  end
end
