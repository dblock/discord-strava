require 'spec_helper'

describe DiscordStrava::Commands::Stats do
  include_context 'discord command' do
    let(:args) { ['stats'] }
  end
  context 'stats' do
    it 'requires a subscription' do
      expect(response).to eq team.trial_message
    end

    context 'subscribed team' do
      let(:team) { Fabricate(:team, subscribed: true) }

      context 'channel' do
        it 'displays channel stats' do
          expect(response).to eq(team.stats(channel_id: 'channel').to_discord)
        end
      end
      # context 'dm' do
      #   let(:params) {
      #     {
      #       id: 'id',
      #       type: Discord::Interactions::Type::APPLICATION_COMMAND,
      #       version: 1,
      #       token: 'token',
      #       application_id: '1135347799840522240',
      #       guild_id: team.guild_id,
      #       user: {
      #         id: user.user_id,
      #         username: 'username'
      #       },
      #       data: {
      #         id: '1135549211878903849',
      #         name: 'strada',
      #         options: command_options
      #       },
      #       channel_id: '1136112917264224338',
      #       locale: 'en-US'
      #     }
      #   }
      #   it 'displays team stats' do
      #     expect(response).to eq(team.stats.to_discord)
      #   end
      # end
    end
  end
end
