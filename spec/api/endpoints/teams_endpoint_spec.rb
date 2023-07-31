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
      before do
        oauth_access = {
          'bot' => {
            'bot_access_token' => 'token',
            'bot_user_id' => 'bot_user_id'
          },
          'access_token' => 'access_token',
          'user_id' => 'guild_owner_id',
          'guild_id' => 'guild_id',
          'team_name' => 'team_name'
        }
        ENV['DISCORD_APPLICATION_ID'] = 'client_id'
        ENV['DISCORD_SECRET_TOKEN'] = 'client_secret'
        allow_any_instance_of(Discord::Web::Client).to receive(:conversations_open).with(
          users: 'guild_owner_id'
        ).and_return(
          'channel' => {
            'id' => 'C1'
          }
        )
        allow_any_instance_of(Discord::Web::Client).to receive(:oauth_access).with(
          hash_including(
            code: 'code',
            client_id: 'client_id',
            client_secret: 'client_secret'
          )
        ).and_return(oauth_access)
      end
      after do
        ENV.delete('DISCORD_APPLICATION_ID')
        ENV.delete('DISCORD_SECRET_TOKEN')
      end
      it 'creates a team' do
        expect_any_instance_of(Discord::Web::Client).to receive(:chat_postMessage).with(
          text: "Welcome to Strada!\nInvite <@bot_user_id> to a channel to publish activities to it.\nType \"*connect*\" to connect your Strava account.\"\n",
          channel: 'C1',
          as_user: true
        )
        expect(DiscordStrava::Service.instance).to receive(:start!)
        expect {
          team = client.teams._post(code: 'code')
          expect(team.guild_id).to eq 'guild_id'
          expect(team.guild_name).to eq 'team_name'
          team = Team.find(team.id)
          expect(team.token).to eq 'token'
          expect(team.bot_user_id).to eq 'bot_user_id'
          expect(team.guild_owner_id).to eq 'guild_owner_id'
        }.to change(Team, :count).by(1)
      end
      it 'reactivates a deactivated team' do
        expect_any_instance_of(Discord::Web::Client).to receive(:chat_postMessage).with(
          text: "Welcome to Strada!\nInvite <@bot_user_id> to a channel to publish activities to it.\nType \"*connect*\" to connect your Strava account.\"\n",
          channel: 'C1',
          as_user: true
        )
        expect(DiscordStrava::Service.instance).to receive(:start!)
        existing_team = Fabricate(:team, token: 'token', active: false)
        expect {
          team = client.teams._post(code: 'code')
          expect(team.guild_id).to eq existing_team.guild_id
          expect(team.guild_name).to eq existing_team.guild_name
          expect(team.active).to be true
          team = Team.find(team.id)
          expect(team.token).to eq 'token'
          expect(team.active).to be true
          expect(team.bot_user_id).to eq 'bot_user_id'
          expect(team.guild_owner_id).to eq 'guild_owner_id'
        }.to_not change(Team, :count)
      end
      it 'reactivates a team deactivated on discord' do
        expect_any_instance_of(Discord::Web::Client).to receive(:chat_postMessage).with(
          text: "Welcome to Strada!\nInvite <@bot_user_id> to a channel to publish activities to it.\nType \"*connect*\" to connect your Strava account.\"\n",
          channel: 'C1',
          as_user: true
        )
        expect(DiscordStrava::Service.instance).to receive(:start!)
        existing_team = Fabricate(:team, token: 'token')
        expect {
          expect_any_instance_of(Team).to receive(:ping!) { raise Discord::Web::Api::Errors::DiscordError, 'invalid_auth' }
          team = client.teams._post(code: 'code')
          expect(team.guild_id).to eq existing_team.guild_id
          expect(team.guild_name).to eq existing_team.guild_name
          expect(team.active).to be true
          team = Team.find(team.id)
          expect(team.token).to eq 'token'
          expect(team.active).to be true
          expect(team.bot_user_id).to eq 'bot_user_id'
          expect(team.guild_owner_id).to eq 'guild_owner_id'
        }.to_not change(Team, :count)
      end
      it 'returns a useful error when team already exists' do
        expect_any_instance_of(Discord::Web::Client).to receive(:chat_postMessage).with(
          text: "Welcome to Strada!\nInvite <@bot_user_id> to a channel to publish activities to it.\nType \"*connect*\" to connect your Strava account.\"\n",
          channel: 'C1',
          as_user: true
        )
        expect_any_instance_of(Team).to receive(:ping_if_active!)
        existing_team = Fabricate(:team, token: 'token')
        expect { client.teams._post(code: 'code') }.to raise_error Faraday::ClientError do |e|
          json = JSON.parse(e.response[:body])
          expect(json['message']).to eq "Team #{existing_team.guild_name} is already registered."
        end
      end
      it 'reactivates a deactivated team with a different code' do
        expect_any_instance_of(Discord::Web::Client).to receive(:chat_postMessage).with(
          text: "Welcome to Strada!\nInvite <@bot_user_id> to a channel to publish activities to it.\nType \"*connect*\" to connect your Strava account.\"\n",
          channel: 'C1',
          as_user: true
        )
        expect(DiscordStrava::Service.instance).to receive(:start!)
        existing_team = Fabricate(:team, api: true, token: 'old', guild_id: 'guild_id', active: false)
        expect {
          team = client.teams._post(code: 'code')
          expect(team.guild_id).to eq existing_team.guild_id
          expect(team.guild_name).to eq existing_team.guild_name
          expect(team.active).to be true
          team = Team.find(team.id)
          expect(team.token).to eq 'token'
          expect(team.active).to be true
          expect(team.bot_user_id).to eq 'bot_user_id'
          expect(team.guild_owner_id).to eq 'guild_owner_id'
        }.to_not change(Team, :count)
      end
      context 'with mailchimp settings' do
        before do
          DiscordStrava::Mailchimp.configure do |config|
            config.mailchimp_api_key = 'api-key'
            config.mailchimp_list_id = 'list-id'
          end
        end
        after do
          DiscordStrava::Mailchimp.config.reset!
        end

        let(:list) { double(Mailchimp::List, members: double(Mailchimp::List::Members)) }

        it 'subscribes to the mailing list' do
          expect_any_instance_of(Discord::Web::Client).to receive(:chat_postMessage).with(
            text: "Welcome to Strada!\nInvite <@bot_user_id> to a channel to publish activities to it.\nType \"*connect*\" to connect your Strava account.\"\n",
            channel: 'C1',
            as_user: true
          )

          expect(DiscordStrava::Service.instance).to receive(:start!)

          allow_any_instance_of(Discord::Web::Client).to receive(:users_info).with(
            user: 'guild_owner_id'
          ).and_return(
            user: {
              profile: {
                email: 'user@example.com',
                first_name: 'First',
                last_name: 'Last'
              }
            }
          )

          allow_any_instance_of(Mailchimp::Client).to receive(:lists).with('list-id').and_return(list)

          expect(list.members).to receive(:where).with(email_address: 'user@example.com').and_return([])

          expect(list.members).to receive(:create_or_update).with(
            email_address: 'user@example.com',
            merge_fields: {
              'FNAME' => 'First',
              'LNAME' => 'Last',
              'BOT' => 'Strada'
            },
            status: 'pending',
            name: nil,
            tags: %w[strada trial],
            unique_email_id: 'guild_id-guild_owner_id'
          )

          client.teams._post(code: 'code')
        end
        after do
          ENV.delete('MAILCHIMP_API_KEY')
          ENV.delete('MAILCHIMP_LIST_ID')
        end
      end
    end
  end
end
