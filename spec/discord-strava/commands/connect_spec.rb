require 'spec_helper'

describe DiscordStrava::Commands::Connect do
  include_context :discord_command do
    let(:args) { ['connect'] }
  end
  context 'connect' do
    it 'requires a subscription' do
      expect(response).to eq team.trial_message
    end
    context 'subscribed team' do
      let(:team) { Fabricate(:team, subscribed: true) }
      let(:url) { "https://www.strava.com/oauth/authorize?client_id=client-id&redirect_uri=https://strada.playplay.io/connect&response_type=code&scope=activity:read_all&state=#{user.id}" }
      it 'connects a user' do
        expect(response).to eq(
          {
            components: [{
              components: [{
                label: 'Connect!',
                style: 5,
                type: 2,
                url: url
              }],
              type: 1
            }],
            content: 'Please connect your Strava account.'
          }
        )
      end
    end
    context 'subscription expiration' do
      before do
        team.update_attributes!(created_at: 3.weeks.ago)
      end
      it 'prevents new connections' do
        expect(response).to eq "Your trial subscription has expired. Subscribe your team for $29.99 a year at https://strada.playplay.io/subscribe?guild_id=#{team.guild_id} to continue receiving Strava activities in Discord. Proceeds go to NYRR."
      end
    end
  end
end
