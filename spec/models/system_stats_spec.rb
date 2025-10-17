require 'spec_helper'

describe SystemStats do
  include_context 'team activation'

  let(:stats) { described_class.aggregate! }

  context 'aggregate!' do
    it 'creates a record' do
      expect { 2.times { described_class.aggregate! } }.to change(described_class, :count).by(2)
    end
  end

  context 'latest_or_aggregate!' do
    it 'creates one record' do
      expect { 2.times { described_class.latest_or_aggregate! } }.to change(described_class, :count).by(1)
    end

    it 'creates another record 24 hours later' do
      described_class.aggregate!
      Timecop.travel(Time.now + 1.day) do
        expect { described_class.latest_or_aggregate! }.to change(described_class, :count).by(1)
      end
      Timecop.travel(Time.now + 1.day + 1.hour) do
        expect { described_class.latest_or_aggregate! }.not_to change(described_class, :count)
      end
    end
  end

  context 'with no teams' do
    it 'zero' do
      expect(stats.teams_count).to eq 0
      expect(stats.active_teams_count).to eq 0
      expect(stats.connected_users_count).to eq 0
      expect(stats.total_distance_in_miles).to eq 0.0
      expect(stats.total_distance_in_miles_s).to be_nil
    end
  end

  context 'with a team' do
    let!(:team) { Fabricate(:team) }

    it 'one team' do
      expect(stats.teams_count).to eq 1
      expect(stats.active_teams_count).to eq 1
      expect(stats.connected_users_count).to eq 0
      expect(stats.total_distance_in_miles).to eq 0.0
      expect(stats.total_distance_in_miles_s).to be_nil
    end
  end

  context 'with activities' do
    let!(:team) { Fabricate(:team) }
    let!(:user1) { Fabricate(:user, team:) }
    let!(:user2) { Fabricate(:user, team:) }
    let!(:swim_activity) { Fabricate(:swim_activity, user: user2) }
    let!(:ride_activity1) { Fabricate(:ride_activity, user: user1) }
    let!(:ride_activity2) { Fabricate(:ride_activity, user: user1) }
    let!(:activity1) { Fabricate(:user_activity, user: user1) }
    let!(:activity2) { Fabricate(:user_activity, user: user1) }
    let!(:activity3) { Fabricate(:user_activity, user: user2) }

    it 'aggregates stats' do
      expect(stats.teams_count).to eq 1
      expect(stats.active_teams_count).to eq 1
      expect(stats.connected_users_count).to eq 0
      expect(stats.total_distance_in_miles).not_to eq 0
      expect(stats.total_distance_in_miles_s).to match(/\d+.\d+ miles/)
    end
  end
end
