require 'spec_helper'

describe Activity do
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
