require 'spec_helper'

describe Activity do
  describe '.attrs_from_strava' do
    let(:strava_response) do
      double(
        'StravaResponse',
        id: '123456789',
        name: 'Morning Run',
        distance: 5000.0,
        moving_time: 1800,
        elapsed_time: 1900,
        average_speed: 2.78,
        max_speed: 3.5,
        average_heartrate: 150.0,
        max_heartrate: 175.0,
        pr_count: 2,
        calories: 450.5,
        sport_type: 'Run',
        total_elevation_gain: 100.0,
        private: false,
        visibility: 'everyone',
        description: 'Great morning run!'
      )
    end

    it 'extracts all fields including calories and max_heartrate' do
      attrs = Activity.attrs_from_strava(strava_response)

      expect(attrs[:strava_id]).to eq('123456789')
      expect(attrs[:name]).to eq('Morning Run')
      expect(attrs[:distance]).to eq(5000.0)
      expect(attrs[:moving_time]).to eq(1800)
      expect(attrs[:elapsed_time]).to eq(1900)
      expect(attrs[:average_speed]).to eq(2.78)
      expect(attrs[:max_speed]).to eq(3.5)
      expect(attrs[:average_heartrate]).to eq(150.0)
      expect(attrs[:max_heartrate]).to eq(175.0)
      expect(attrs[:pr_count]).to eq(2)
      expect(attrs[:calories]).to eq(450.5)
      expect(attrs[:type]).to eq('Run')
      expect(attrs[:total_elevation_gain]).to eq(100.0)
      expect(attrs[:private]).to eq(false)
      expect(attrs[:visibility]).to eq('everyone')
      expect(attrs[:description]).to eq('Great morning run!')
    end

    it 'handles nil values gracefully' do
      strava_response_nil = double(
        'StravaResponse',
        id: '123456789',
        name: 'Morning Run',
        distance: 5000.0,
        moving_time: 1800,
        elapsed_time: 1900,
        average_speed: nil,
        max_speed: nil,
        average_heartrate: nil,
        max_heartrate: nil,
        pr_count: nil,
        calories: nil,
        sport_type: 'Run',
        total_elevation_gain: nil,
        private: false,
        visibility: 'everyone',
        description: nil
      )

      attrs = Activity.attrs_from_strava(strava_response_nil)

      expect(attrs[:calories]).to be_nil
      expect(attrs[:max_heartrate]).to be_nil
      expect(attrs[:average_heartrate]).to be_nil
      expect(attrs[:pr_count]).to be_nil
    end
  end

  describe '#pace_per_mile_s' do
    it 'rounds up 60 seconds' do
      expect(Activity.new(average_speed: 3.354).pace_per_mile_s).to eq '8m00s/mi'
    end
  end

  context 'access changes' do
    describe 'privacy changes' do
      context 'a private, bragged activity that was not posted to any channels' do
        let!(:activity) { Fabricate(:user_activity, private: true, bragged_at: Time.now.utc) }

        it 'resets bragged_at' do
          activity.update_attributes!(private: false)
          expect(activity.reload.bragged_at).to be_nil
        end
      end

      context 'a private, bragged activity a long time ago that was not posted to any channels' do
        let!(:activity) { Fabricate(:user_activity, private: true, bragged_at: 1.week.ago) }

        it 'does not reset bragged_at' do
          activity.update_attributes!(private: false)
          expect(activity.reload.bragged_at).not_to be_nil
        end
      end

      context 'a private, bragged activity that was posted to a channel' do
        let!(:activity) { Fabricate(:user_activity, private: true, bragged_at: Time.now.utc, channel_message: ChannelMessage.new(channel_id: 'c1')) }

        it 'does not reset bragged_at' do
          activity.update_attributes!(private: false)
          expect(activity.reload.bragged_at).not_to be_nil
        end
      end
    end

    describe 'visibility changes' do
      context 'bragged activity that was not posted to any channels' do
        let!(:activity) { Fabricate(:user_activity, visibility: 'only_me', bragged_at: Time.now.utc) }

        it 'resets bragged_at' do
          activity.update_attributes!(visibility: 'everyone')
          expect(activity.reload.bragged_at).to be_nil
        end
      end

      context 'bragged activity a long time ago that was not posted to any channels' do
        let!(:activity) { Fabricate(:user_activity, visibility: 'only_me', bragged_at: 1.week.ago) }

        it 'does not reset bragged_at' do
          activity.update_attributes!(visibility: 'everyone')
          expect(activity.reload.bragged_at).not_to be_nil
        end
      end

      context 'bragged activity that was posted to a channel' do
        let!(:activity) { Fabricate(:user_activity, visibility: 'only_me', bragged_at: Time.now.utc, channel_message: ChannelMessage.new(channel_id: 'c1')) }

        it 'does not reset bragged_at' do
          activity.update_attributes!(visibility: 'everyone')
          expect(activity.reload.bragged_at).not_to be_nil
        end
      end
    end
  end
end
