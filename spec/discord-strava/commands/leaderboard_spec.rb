require 'spec_helper'

describe DiscordStrava::Commands::Leaderboard do
  context 'leaderboard' do
    include_context 'discord command' do
      let(:args) { ['leaderboard'] }
    end

    let(:team) { Fabricate(:team, subscribed: true) }

    it 'returns leaderboard' do
      expect(response).to eq(
        'There are no activities with distance in this channel.'
      )
    end

    it 'includes channel' do
      expect_any_instance_of(Team).to receive(:leaderboard).with(channel_id: user.channel_id, metric: 'distance').and_call_original
      expect(response).to eq(
        'There are no activities with distance in this channel.'
      )
    end

    it 'does not include channel on a DM' do
      expect_any_instance_of(Team).to receive(:leaderboard).with(channel_id: user.channel_id, metric: 'distance').and_call_original
      expect(response).to eq(
        'There are no activities with distance in this channel.'
      )
    end
  end

  context 'leaderboard with options' do
    include_context 'discord command' do
      let(:args) { ['leaderboard', { 'metric' => 'elapsed_time' }] }
    end

    let(:team) { Fabricate(:team, subscribed: true) }

    it 'displays elapsed time leaderboard' do
      expect(response).to eq(
        'There are no activities with elapsed time in this channel.'
      )
    end
  end
end
