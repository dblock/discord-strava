require 'spec_helper'

describe DiscordStrava::Commands::Help do
  include_context :discord_command do
    let(:args) { ['help'] }
  end
  context 'subscribed team' do
    let!(:team) { Fabricate(:team, subscribed: true) }
    it 'help' do
      expect(response).to eq DiscordStrava::Commands::Help::HELP
    end
  end
  context 'non-subscribed team after trial' do
    let!(:team) { Fabricate(:team, created_at: 2.weeks.ago) }
    it 'help' do
      expect(response).to eq([
        DiscordStrava::Commands::Help::HELP,
        team.trial_message
      ].join("\n"))
    end
  end
  context 'non-subscribed team during trial' do
    let!(:team) { Fabricate(:team, created_at: 1.day.ago) }
    it 'help' do
      expect(response).to eq([
        DiscordStrava::Commands::Help::HELP,
        team.trial_message
      ].join("\n"))
    end
  end
end
