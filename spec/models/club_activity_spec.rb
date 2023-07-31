require 'spec_helper'

describe ClubActivity do
  context 'hidden?' do
    context 'default' do
      let(:activity) { Fabricate(:club_activity) }
      it 'is not hidden' do
        expect(activity.hidden?).to be false
      end
    end
  end
  context 'brag!' do
    let(:team) { Fabricate(:team) }
    let(:club) { Fabricate(:club, team: team) }
    let!(:activity) { Fabricate(:club_activity, club: club) }
    it 'sends a message to the subscribed channel' do
      expect(club.team.discord_client).to receive(:chat_postMessage).with(
        activity.to_discord.merge(
          channel: club.channel_id,
          as_user: true
        )
      ).and_return('ts' => 1)
      expect(activity.brag!).to eq([ts: 1, channel: club.channel_id])
    end
    it 'warns if the bot leaves the channel' do
      expect {
        expect_any_instance_of(Logger).to receive(:warn).with(/not_in_channel/)
        expect(club.team.discord_client).to receive(:chat_postMessage) {
          raise Discord::Web::Api::Errors::DiscordError, 'not_in_channel'
        }
        expect(activity.brag!).to be nil
      }.to_not change(Club, :count)
    end
    it 'warns if the account goes inactive' do
      expect {
        expect {
          expect_any_instance_of(Logger).to receive(:warn).with(/account_inactive/)
          expect(club.team.discord_client).to receive(:chat_postMessage) {
            raise Discord::Web::Api::Errors::DiscordError, 'account_inactive'
          }
          expect(activity.brag!).to be nil
        }.to_not change(Club, :count)
      }.to_not change(ClubActivity, :count)
    end
    it 'informs admin on restricted_action' do
      expect {
        expect_any_instance_of(Logger).to receive(:warn).with(/restricted_action/)
        expect(club.team).to receive(:inform_admin!).with(text: "I wasn't allowed to post into <##{club.channel_id}> because of a Discord workspace preference, please contact your Discord admin.")
        expect(club.team.discord_client).to receive(:chat_postMessage) {
          raise Discord::Web::Api::Errors::DiscordError, 'restricted_action'
        }
        expect(activity.brag!).to be nil
      }.to_not change(Club, :count)
    end
    it 'informs admin on is_archived channel' do
      expect {
        expect_any_instance_of(Logger).to receive(:warn).with(/is_archived/)
        expect(club.team).to receive(:inform_admin!).with(text: "I couldn't post an activity from #{club.name} into <##{club.channel_id}> because the channel was archived, please reconnect that club in a different channel.")
        expect(club.team.discord_client).to receive(:chat_postMessage) {
          raise Discord::Web::Api::Errors::DiscordError, 'is_archived'
        }
        expect(activity.brag!).to be nil
      }.to_not change(Club, :count)
      expect(club.reload.sync_activities).to be false
    end
    context 'having already bragged a user activity in the channel' do
      let!(:user_activity) do
        Fabricate(:user_activity,
                  team: club.team,
                  distance: activity.distance,
                  moving_time: activity.moving_time,
                  elapsed_time: activity.elapsed_time,
                  total_elevation_gain: activity.total_elevation_gain,
                  map: nil,
                  bragged_at: Time.now.utc,
                  channel_messages: [
                    ChannelMessage.new(channel: club.channel_id)
                  ])
      end
      it 'does not re-brag the activity' do
        expect(club.team.discord_client).to_not receive(:chat_postMessage)
        expect {
          expect(activity.brag!).to be nil
        }.to change(club.activities.unbragged, :count).by(-1)
        expect(activity.bragged_at).to_not be_nil
      end
    end
    context 'having a private user activity' do
      let!(:user_activity) do
        Fabricate(:user_activity,
                  team: club.team,
                  distance: activity.distance,
                  moving_time: activity.moving_time,
                  elapsed_time: activity.elapsed_time,
                  total_elevation_gain: activity.total_elevation_gain,
                  map: nil,
                  private: true)
      end
      context 'unbragged' do
        it 'rebrags the activity' do
          expect(club.team.discord_client).to receive(:chat_postMessage).with(
            activity.to_discord.merge(
              channel: club.channel_id,
              as_user: true
            )
          ).and_return('ts' => 1)
          expect(activity.brag!).to eq([ts: 1, channel: club.channel_id])
        end
      end
      context 'bragged recently' do
        before do
          user_activity.set(bragged_at: Time.now.utc)
        end
        it 'does not rebrag the activity' do
          expect(club.team.discord_client).to_not receive(:chat_postMessage)
          expect {
            expect(activity.brag!).to be nil
          }.to change(club.activities.unbragged, :count).by(-1)
          expect(activity.bragged_at).to_not be_nil
        end
      end
      context 'bragged a long time ago' do
        before do
          user_activity.set(bragged_at: Time.now.utc - 1.month)
        end
        it 'rebrags the activity' do
          expect(club.team.discord_client).to receive(:chat_postMessage).with(
            activity.to_discord.merge(
              channel: club.channel_id,
              as_user: true
            )
          ).and_return('ts' => 1)
          expect(activity.brag!).to eq([ts: 1, channel: club.channel_id])
        end
      end
    end
  end
  context 'miles' do
    let(:team) { Fabricate(:team, units: 'mi') }
    let(:club) { Fabricate(:club, team: team) }
    let(:activity) { Fabricate(:club_activity, club: club) }
    it 'to_discord' do
      expect(activity.to_discord).to eq(
        attachments: [
          {
            fallback: "#{activity.name} by #{activity.athlete_name} via #{club.name}, 14.01mi 2h6m26s 9m02s/mi",
            title: activity.name,
            url: club.strava_url,
            text: "#{activity.athlete_name}, #{club.name}",
            fields: [
              { name: 'Type', value: 'Run 🏃' },
              { name: 'Distance', value: '14.01mi' },
              { name: 'Moving Time', value: '2h6m26s' },
              { name: 'Elapsed Time', value: '2h8m6s' },
              { name: 'Pace', value: '9m02s/mi' },
              { name: 'Speed', value: '6.6mph' },
              { name: 'Elevation', value: '475.4ft' }
            ],
            thumb_url: club.logo
          }
        ]
      )
    end
  end
  context 'km' do
    let(:team) { Fabricate(:team, units: 'km') }
    let(:club) { Fabricate(:club, team: team) }
    let(:activity) { Fabricate(:club_activity, club: club) }
    it 'to_discord' do
      expect(activity.to_discord).to eq(
        attachments: [
          {
            fallback: "#{activity.name} by #{activity.athlete_name} via #{club.name}, 22.54km 2h6m26s 5m37s/km",
            title: activity.name,
            url: club.strava_url,
            text: "#{activity.athlete_name}, #{club.name}",
            fields: [
              { name: 'Type', value: 'Run 🏃' },
              { name: 'Distance', value: '22.54km' },
              { name: 'Moving Time', value: '2h6m26s' },
              { name: 'Elapsed Time', value: '2h8m6s' },
              { name: 'Pace', value: '5m37s/km' },
              { name: 'Speed', value: '10.7km/h' },
              { name: 'Elevation', value: '144.9m' }
            ],
            thumb_url: club.logo
          }
        ]
      )
    end
  end
  context 'both' do
    let(:team) { Fabricate(:team, units: 'both') }
    let(:club) { Fabricate(:club, team: team) }
    let(:activity) { Fabricate(:club_activity, club: club) }
    it 'to_discord' do
      expect(activity.to_discord).to eq(
        attachments: [
          {
            fallback: "#{activity.name} by #{activity.athlete_name} via #{club.name}, 14.01mi 22.54km 2h6m26s 9m02s/mi 5m37s/km",
            title: activity.name,
            url: club.strava_url,
            text: "#{activity.athlete_name}, #{club.name}",
            fields: [
              { name: 'Type', value: 'Run 🏃' },
              { name: 'Distance', value: '14.01mi 22.54km' },
              { name: 'Moving Time', value: '2h6m26s' },
              { name: 'Elapsed Time', value: '2h8m6s' },
              { name: 'Pace', value: '9m02s/mi 5m37s/km' },
              { name: 'Speed', value: '6.6mph 10.7km/h' },
              { name: 'Elevation', value: '475.4ft 144.9m' }
            ],
            thumb_url: club.logo
          }
        ]
      )
    end
  end
  context 'fields' do
    let(:club) { Fabricate(:club, team: team) }
    let(:activity) { Fabricate(:club_activity, club: club) }
    context 'none' do
      let(:team) { Fabricate(:team, activity_fields: ['None']) }
      it 'to_discord' do
        expect(activity.to_discord).to eq(
          attachments: [
            {
              fallback: "#{activity.name} by #{activity.athlete_name} via #{club.name}, 14.01mi 2h6m26s 9m02s/mi",
              title: activity.name,
              url: club.strava_url,
              text: "#{activity.athlete_name}, #{club.name}",
              thumb_url: club.logo
            }
          ]
        )
      end
    end
    context 'some' do
      let(:team) { Fabricate(:team, activity_fields: %w[Pace Elevation Type]) }
      it 'to_discord' do
        expect(activity.to_discord).to eq(
          attachments: [
            {
              fallback: "#{activity.name} by #{activity.athlete_name} via #{club.name}, 14.01mi 2h6m26s 9m02s/mi",
              title: activity.name,
              url: club.strava_url,
              text: "#{activity.athlete_name}, #{club.name}",
              fields: [
                { name: 'Pace', value: '9m02s/mi' },
                { name: 'Elevation', value: '475.4ft' },
                { name: 'Type', value: 'Run 🏃' }
              ],
              thumb_url: club.logo
            }
          ]
        )
      end
    end
  end
end
