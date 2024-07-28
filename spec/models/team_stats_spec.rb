require 'spec_helper'

describe TeamStats do
  let(:team) { Fabricate(:team) }

  context 'with no activities' do
    let(:stats) { team.stats }

    describe '#stats' do
      it 'aggregates stats' do
        expect(stats.count).to eq 0
      end
    end

    describe '#to_discord' do
      it 'defaults to no activities' do
        expect(stats.to_discord).to eq('There are no activities in this channel.')
      end
    end
  end

  context 'with activities' do
    let!(:user1) { Fabricate(:user, team: team) }
    let!(:user2) { Fabricate(:user, team: team) }
    let!(:swim_activity) { Fabricate(:swim_activity, user: user2) }
    let!(:ride_activity1) { Fabricate(:ride_activity, user: user1) }
    let!(:ride_activity2) { Fabricate(:ride_activity, user: user1) }
    let!(:activity1) { Fabricate(:user_activity, user: user1) }
    let!(:activity2) { Fabricate(:user_activity, user: user1) }
    let!(:activity3) { Fabricate(:user_activity, user: user2) }

    describe '#stats' do
      let(:stats) { team.stats }

      it 'returns stats sorted by count' do
        expect(stats.keys).to eq %w[Run Ride Swim]
        expect(stats.values.map(&:count)).to eq [3, 2, 1]
      end

      it 'aggregates stats' do
        expect(stats['Ride'].to_h).to eq(
          {
            distance: [ride_activity1, ride_activity2].map(&:distance).compact.sum,
            moving_time: [ride_activity1, ride_activity2].map(&:moving_time).compact.sum,
            elapsed_time: [ride_activity1, ride_activity2].map(&:elapsed_time).compact.sum,
            pr_count: 0,
            calories: 0,
            total_elevation_gain: 0
          }
        )
        expect(stats['Run'].to_h).to eq(
          {
            distance: [activity1, activity2, activity3].map(&:distance).compact.sum,
            moving_time: [activity1, activity2, activity3].map(&:moving_time).compact.sum,
            elapsed_time: [activity1, activity2, activity3].map(&:elapsed_time).compact.sum,
            pr_count: [activity1, activity2, activity3].map(&:pr_count).compact.sum,
            calories: [activity1, activity2, activity3].map(&:calories).compact.sum,
            total_elevation_gain: [activity1, activity2, activity3].map(&:total_elevation_gain).compact.sum
          }
        )
        expect(stats['Swim'].to_h).to eq(
          {
            distance: swim_activity.distance,
            moving_time: swim_activity.moving_time,
            elapsed_time: swim_activity.elapsed_time,
            pr_count: 0,
            calories: 0,
            total_elevation_gain: 0
          }
        )
      end

      context 'with activities from another team' do
        let!(:another_activity) { Fabricate(:user_activity, user: user1) }
        let!(:another_team_activity) { Fabricate(:user_activity, user: Fabricate(:user, team: Fabricate(:team))) }

        it 'does not include that activity' do
          expect(stats.values.map(&:count)).to eq [4, 2, 1]
        end
      end
    end

    describe '#to_discord' do
      let(:stats) { team.stats }

      it 'includes all activities' do
        expect(stats.to_discord[:embeds].count).to eq(3)
      end
    end
  end

  context 'with activities across multiple channels' do
    let!(:user1) { Fabricate(:user, team: team) }
    let!(:user2) { Fabricate(:user, team: team) }
    let!(:user_activity1) { Fabricate(:user_activity, user: user1, channel_message: { channel_id: 'c1', message_id: '1' }) }
    let!(:user_activity2) { Fabricate(:user_activity, user: user2, channel_message: { channel_id: 'c2', message_id: '1' }) }

    describe '#stats' do
      context 'all channels' do
        let!(:stats) { team.stats }
        let!(:activities) { [user_activity1, user_activity2] }

        it 'returns stats for all activities' do
          expect(stats['Run'].to_h).to eq(
            {
              distance: activities.map(&:distance).compact.sum,
              moving_time: activities.map(&:moving_time).compact.sum,
              elapsed_time: activities.map(&:elapsed_time).compact.sum,
              pr_count: activities.map(&:pr_count).compact.sum,
              calories: activities.map(&:calories).compact.sum,
              total_elevation_gain: activities.map(&:total_elevation_gain).compact.sum
            }
          )
        end
      end

      context 'a single channels' do
        let!(:stats) { team.stats(channel_id: 'c1') }
        let!(:activities) { [user_activity1] }

        it 'returns stats for all activities' do
          expect(stats['Run'].to_h).to eq(
            {
              distance: activities.map(&:distance).compact.sum,
              moving_time: activities.map(&:moving_time).compact.sum,
              elapsed_time: activities.map(&:elapsed_time).compact.sum,
              pr_count: activities.map(&:pr_count).compact.sum,
              calories: activities.map(&:calories).compact.sum,
              total_elevation_gain: activities.map(&:total_elevation_gain).compact.sum
            }
          )
        end
      end
    end
  end
end
