require 'spec_helper'

describe DiscordStrava::Commands::Connect do
  let!(:team) { Fabricate(:team, created_at: 2.weeks.ago) }
  let(:app) { DiscordStrava::Server.new(team: team) }
  let(:client) { app.send(:client) }
  let(:message_hook) { DiscordRubyBot::Hooks::Message.new }
  context 'connect' do
    it 'requires a subscription' do
      expect(message: "#{DiscordRubyBot.config.user} connect").to respond_with_discord_message(team.trial_message)
    end
    context 'subscribed team' do
      let(:team) { Fabricate(:team, subscribed: true) }
      let(:user) { Fabricate(:user, team: team) }
      let(:url) { "https://www.strava.com/oauth/authorize?client_id=client-id&redirect_uri=https://strada.playplay.io/connect&response_type=code&scope=activity:read_all&state=#{user.id}" }
      it 'connects a user' do
        expect(User).to receive(:find_create_or_update_by_discord_id!).and_return(user)
        expect(user).to receive(:dm!).with(
          text: 'Please connect your Strava account.',
          attachments: [{
            fallback: "Please connect your Strava account at #{url}.",
            actions: [{
              type: 'button',
              text: 'Click Here',
              url: url
            }]
          }]
        )
        message_hook.call(client, Hashie::Mash.new(channel: 'channel', user: DiscordRubyBot.config.user, text: "#{DiscordRubyBot.config.user} connect"))
      end
    end
  end
  context 'subscription expiration' do
    before do
      team.update_attributes!(created_at: 3.weeks.ago)
    end
    it 'prevents new connections' do
      expect(message: "#{DiscordRubyBot.config.user} connect").to respond_with_discord_message(
        "Your trial subscription has expired. Subscribe your team for $29.99 a year at https://strada.playplay.io/subscribe?guild_id=#{team.guild_id} to continue receiving Strava activities in Discord. Proceeds go to NYRR."
      )
    end
  end
end
