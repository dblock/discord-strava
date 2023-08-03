require 'spec_helper'

describe Api::Endpoints::TeamsEndpoint do
  include Api::Test::EndpointTest

  context 'teams' do
    subject do
      client.teams
    end
    it 'lists no teams' do
      expect(subject.to_a.size).to eq 0
    end
    context 'with teams' do
      let!(:team1) { Fabricate(:team, api: false) }
      let!(:team2) { Fabricate(:team, api: true) }
      it 'lists teams with api enabled' do
        expect(subject.to_a.size).to eq 1
        expect(subject.first.id).to eq team2.id.to_s
      end
    end
  end

  context 'team' do
    it 'requires code' do
      expect { client.teams._post }.to raise_error Faraday::ClientError do |e|
        json = JSON.parse(e.response[:body])
        expect(json['message']).to eq 'Invalid parameters.'
        expect(json['type']).to eq 'param_error'
      end
    end

    context 'register' do
      let(:oauth_access) do
        {
          'access_token' => 'access_token',
          'expires_in' => 24 * 60 * 60,
          'refresh_token' => 'refresh_token',
          'guild' => {
            'id' => 'guild_id',
            'name' => 'guild_name',
            'owner_id' => 'guild_owner_id'
          }
        }
      end
      before do
        ENV['DISCORD_CLIENT_ID'] = 'client_id'
        ENV['DISCORD_CLIENT_SECRET'] = 'client_secret'
        allow(Discord::OAuth2).to receive(:post).with('oauth2/token', hash_including(code: 'code'), :url_encoded).and_return(oauth_access)
      end
      after do
        ENV.delete('DISCORD_CLIENT_ID')
        ENV.delete('DISCORD_CLIENT_SECRET')
      end
      it 'creates a team' do
        expect_any_instance_of(Team).to receive(:activated!)
        expect(DiscordStrava::Service.instance).to receive(:start!)
        expect {
          team = client.teams._post(code: 'code', guild_id: 'guild_id', permissions: '1234567')
          expect(team.guild_id).to eq 'guild_id'
          expect(team.guild_name).to eq 'guild_name'
          team = Team.find(team.id)
          expect(team.token).to eq 'access_token'
          expect(team.refresh_token).to eq 'refresh_token'
          expect(team.guild_owner_id).to eq 'guild_owner_id'
        }.to change(Team, :count).by(1)
      end
      it 'reactivates a deactivated team' do
        allow_any_instance_of(Team).to receive(:activated!)
        expect(DiscordStrava::Service.instance).to receive(:start!)
        Fabricate(:team, token: 'access_token', guild_id: 'guild_id', active: false)
        expect {
          team = client.teams._post(code: 'code', guild_id: 'this is just a hint', permissions: '1234567')
          expect(team.guild_id).to eq 'guild_id'
          expect(team.guild_name).to eq 'guild_name'
          expect(team.active).to be true
          team = Team.find(team.id)
          expect(team.token).to eq 'access_token'
          expect(team.refresh_token).to eq 'refresh_token'
          expect(team.active).to be true
          expect(team.guild_owner_id).to eq 'guild_owner_id'
        }.to_not change(Team, :count)
      end
      it 'reactivates a team deactivated on discord with the same access token' do
        allow_any_instance_of(Team).to receive(:activated!)
        expect(DiscordStrava::Service.instance).to receive(:start!)
        Fabricate(:team, token: 'access_token')
        expect {
          expect_any_instance_of(Team).to receive(:ping!) { raise 'error' }
          team = client.teams._post(code: 'code', guild_id: 'guild_id', permissions: '1234567')
          expect(team.guild_id).to eq 'guild_id'
          expect(team.guild_name).to eq 'guild_name'
          expect(team.active).to be true
          team = Team.find(team.id)
          expect(team.token).to eq 'access_token'
          expect(team.active).to be true
          expect(team.guild_owner_id).to eq 'guild_owner_id'
        }.to_not change(Team, :count)
      end
      it 'reactivates a team deactivated on discord with the same guild id' do
        allow_any_instance_of(Team).to receive(:activated!)
        expect(DiscordStrava::Service.instance).to receive(:start!)
        Fabricate(:team, guild_id: 'guild_id')
        expect {
          expect_any_instance_of(Team).to receive(:ping!) { raise 'error' }
          team = client.teams._post(code: 'code', guild_id: 'guild_id', permissions: '1234567')
          expect(team.guild_id).to eq 'guild_id'
          expect(team.guild_name).to eq 'guild_name'
          expect(team.active).to be true
          team = Team.find(team.id)
          expect(team.token).to eq 'access_token'
          expect(team.active).to be true
          expect(team.guild_owner_id).to eq 'guild_owner_id'
        }.to_not change(Team, :count)
      end
      it 'returns a useful error when team already exists' do
        allow_any_instance_of(Team).to receive(:activated!)
        expect_any_instance_of(Team).to receive(:ping_if_active!)
        Fabricate(:team, token: 'access_token')
        expect { client.teams._post(code: 'code', guild_id: 'guild_id', permissions: '1234567') }.to raise_error Faraday::ClientError do |e|
          json = JSON.parse(e.response[:body])
          expect(json['message']).to eq "Team \"guild_name\" is already registered. You're all set."
        end
      end
      it 'reactivates a deactivated team with a different code' do
        allow_any_instance_of(Team).to receive(:activated!)
        expect(DiscordStrava::Service.instance).to receive(:start!)
        existing_team = Fabricate(:team, api: true, token: 'old', guild_id: 'guild_id', active: false)
        expect {
          team = client.teams._post(code: 'code', guild_id: 'guild_id', permissions: '1234567')
          expect(team.guild_id).to eq existing_team.guild_id
          expect(team.guild_name).to eq 'guild_name'
          expect(team.active).to be true
          team = Team.find(team.id)
          expect(team.token).to eq 'access_token'
          expect(team.active).to be true
          expect(team.guild_owner_id).to eq 'guild_owner_id'
        }.to_not change(Team, :count)
      end
    end
  end
end
