require 'spec_helper'

describe Api::Endpoints::DiscordEndpoint do
  include Api::Test::EndpointTest

  context 'Ed25519 signature' do
    it 'X-Signature-Ed25519 is required' do
      post '/api/discord'
      expect(last_response.status).to eq 401
      response = JSON.parse(last_response.body)
      expect(response['error']).to eq 'Missing X-Signature-Ed25519'
    end

    it 'X-Signature-Timestamp is required' do
      header 'X-Signature-Ed25519', 'signature'
      post '/api/discord'
      expect(last_response.status).to eq 401
      response = JSON.parse(last_response.body)
      expect(response['error']).to eq 'Missing X-Signature-Timestamp'
    end

    it 'DISCORD_PUBLIC_KEY is required' do
      header 'X-Signature-Ed25519', 'signature'
      header 'X-Signature-Timestamp', 'ts'
      post '/api/discord'
      expect(last_response.status).to eq 401
      response = JSON.parse(last_response.body)
      expect(response['error']).to eq 'Missing DISCORD_PUBLIC_KEY'
    end

    context 'with signature' do
      before do
        ENV['DISCORD_PUBLIC_KEY'] = '3a2b26f5434477d6f9632324775d8821284b1b38d3ba760bc1dd0bd31a334ede'
      end

      after do
        ENV.delete('DISCORD_PUBLIC_KEY')
      end

      it 'verifies signature' do
        header 'X-Signature-Ed25519', 'e20cd950d46f99886a72ab9ac464d514f7dcd9a2ae1815360c44bf494ed0600bcc8b58427dd08a299c1c670a61ae6bcc2e391758f4b6fbea6b65374c54ee4e06'
        header 'X-Signature-Timestamp', 'timestamp'
        post '/api/discord', {
          id: 'id',
          type: Discord::Interactions::Type::PING,
          version: 1,
          token: 'token',
          application_id: 'application_id'
        }
        expect(last_response.status).to eq 201
        expect(JSON.parse(last_response.body)).to eq({ 'type' => 1 })
      end

      it 'rejects an invalid signature' do
        header 'X-Signature-Ed25519', 'x' * 128
        header 'X-Signature-Timestamp', 'timestamp'
        post '/api/discord', {
          id: 'id',
          type: Discord::Interactions::Type::PING,
          version: 1,
          token: 'token',
          application_id: 'application_id'
        }
        expect(last_response.status).to eq 401
        expect(JSON.parse(last_response.body)).to eq({ 'error' => '401 Unauthorized' })
      end
    end
  end

  context 'api' do
    before do
      ENV['DISCORD_PUBLIC_KEY'] = 'key'
      header 'X-Signature-Ed25519', 'signature'
      header 'X-Signature-Timestamp', 'timestamp'
      allow(Discord::Interactions::Signature).to receive(:verify!)
    end

    after do
      ENV.delete('DISCORD_PUBLIC_KEY')
    end

    context 'ping' do
      it 'receives pong' do
        post '/api/discord', {
          id: 'id',
          type: Discord::Interactions::Type::PING,
          version: 1,
          token: 'token',
          application_id: 'application_id'
        }
        expect(last_response.status).to eq 201
        expect(JSON.parse(last_response.body)).to eq({ 'type' => 1 })
      end
    end

    context 'unhandled interaction' do
      it 'receives unhandled error' do
        post '/api/discord', {
          id: 'id',
          type: Discord::Interactions::Type::MODAL_SUBMIT,
          version: 1,
          token: 'token',
          application_id: 'application_id'
        }
        expect(last_response.status).to eq 400
        expect(JSON.parse(last_response.body)).to eq({ 'error' => 'Unhandled Interaction' })
      end
    end

    context 'dm' do
      it 'receives DM message' do
        post '/api/discord', {
          id: 'id',
          type: Discord::Interactions::Type::APPLICATION_COMMAND,
          version: 1,
          token: 'token',
          application_id: '1135347799840522240',
          channel: {
            id: '1136112917264224338',
            type: 1
          },
          data: {
            id: '1135549211878903849',
            name: 'strada',
            options: [{
              name: 'connect',
              options: [],
              type: 1
            }],
            type: 1
          },
          channel_id: '1136112917264224338',
          locale: 'en-US',
          user: {
            id: '747821172036599899'
          }
        }
        expect(last_response.status).to eq 201
        expect(JSON.parse(last_response.body)).to eq(
          'data' => {
            'content' => 'Strada works best in a regular channnel.', 'flags' => 64
          },
          'type' => 4
        )
      end
    end

    context 'channel command' do
      let!(:team) { Fabricate(:team, guild_id: 'guild_id') }
      let!(:user) { Fabricate(:user, team:) }

      it 'receives response' do
        post '/api/discord', {
          id: 'id',
          type: Discord::Interactions::Type::APPLICATION_COMMAND,
          version: 1,
          token: 'token',
          application_id: '1135347799840522240',
          guild_id: 'guild_id',
          channel: {
            id: user.channel_id,
            type: 0
          },
          member: {
            user: {
              id: user.user_id,
              username: 'username'
            }
          },
          data: {
            id: '1135549211878903849',
            name: 'strada',
            options: [{
              name: 'connect',
              options: [],
              type: 1
            }],
            type: 1
          },
          channel_id: '1136112917264224338',
          locale: 'en-US'
        }
        expect(last_response.status).to eq 201
        expect(JSON.parse(last_response.body)).to eq(
          'type' => 4,
          'data' => {
            'components' => [{
              'components' => [{
                'label' => 'Connect!',
                'style' => 5,
                'type' => 2,
                'url' => "https://www.strava.com/oauth/authorize?client_id=client-id&redirect_uri=https://strada.playplay.io/connect&response_type=code&scope=activity:read_all&state=#{user.id}"
              }],
              'type' => 1
            }],
            'content' => 'Please connect your Strava account.',
            'flags' => 64
          }
        )
      end
    end
  end
end
