require 'spec_helper'

describe UserActivity do
  before do
    allow(HTTParty).to receive_message_chain(:get, :body).and_return('PNG')
  end
  context 'hidden?' do
    context 'default' do
      let(:activity) { Fabricate(:user_activity) }
      it 'is not hidden' do
        expect(activity.hidden?).to be false
      end
    end
    context 'private' do
      context 'private and user is private' do
        let(:user) { Fabricate(:user, private_activities: false) }
        let(:activity) { Fabricate(:user_activity, user: user, private: true) }
        it 'is hidden' do
          expect(activity.hidden?).to be true
        end
      end
      context 'private but user is public' do
        let(:user) { Fabricate(:user, private_activities: true) }
        let(:activity) { Fabricate(:user_activity, user: user, private: true) }
        it 'is not hidden' do
          expect(activity.hidden?).to be false
        end
      end
      context 'public but user is private' do
        let(:user) { Fabricate(:user, private_activities: false) }
        let(:activity) { Fabricate(:user_activity, user: user, private: false) }
        it 'is hidden' do
          expect(activity.hidden?).to be false
        end
      end
    end
    context 'visibility' do
      context 'user has not set followers_only_activities' do
        let(:user) { Fabricate(:user, followers_only_activities: false) }
        context 'only_me' do
          let(:activity) { Fabricate(:user_activity, user: user, visibility: 'only_me') }
          it 'is hidden' do
            expect(activity.hidden?).to be true
          end
        end
        context 'followers_only' do
          let(:activity) { Fabricate(:user_activity, user: user, visibility: 'followers_only') }
          it 'is hidden' do
            expect(activity.hidden?).to be true
          end
        end
        context 'everyone' do
          let(:activity) { Fabricate(:user_activity, user: user, visibility: 'everyone') }
          it 'is not hidden' do
            expect(activity.hidden?).to be false
          end
        end
      end
      context 'user has set followers_only_activities' do
        let(:user) { Fabricate(:user, followers_only_activities: true) }
        context 'only_me' do
          let(:activity) { Fabricate(:user_activity, user: user, visibility: 'only_me') }
          it 'is hidden' do
            expect(activity.hidden?).to be true
          end
        end
        context 'followers_only' do
          let(:activity) { Fabricate(:user_activity, user: user, visibility: 'followers_only') }
          it 'is not hidden' do
            expect(activity.hidden?).to be false
          end
        end
        context 'everyone' do
          let(:activity) { Fabricate(:user_activity, user: user, visibility: 'everyone') }
          it 'is not hidden' do
            expect(activity.hidden?).to be false
          end
        end
      end
    end
  end
  context 'brag!' do
    let(:team) { Fabricate(:team) }
    let(:user) { Fabricate(:user, team: team) }
    let!(:activity) { Fabricate(:user_activity, user: user) }
    it 'sends a message to the subscribed channel' do
      expect(Discord::Messages).to receive(:send_message).with(
        user.channel_id,
        activity.to_discord
      ).and_return('id' => '1', 'channel_id' => '2')
      expect(activity.brag!).to eq(message_id: '1', channel_id: '2')
    end
  end
  context 'in time' do
    let(:tt) { Time.now }
    before do
      Timecop.freeze(tt)
    end
    context 'miles' do
      let(:team) { Fabricate(:team, units: 'mi') }
      let(:user) { Fabricate(:user, team: team) }
      let(:activity) { Fabricate(:user_activity, user: user) }
      it 'to_discord' do
        expect(activity.to_discord).to eq(
          embeds: [
            {
              title: activity.name,
              url: "https://www.strava.com/activities/#{activity.strava_id}",
              description: "<@#{activity.user.user_id}> on Tuesday, February 20, 2018 at 10:02 AM",
              image: {
                url: "https://strada.playplay.io/api/maps/#{activity.map.id}.png"
              },
              fields: [
                { inline: true, name: 'Type', value: 'Run 🏃' },
                { inline: true, name: 'Distance', value: '14.01mi' },
                { inline: true, name: 'Moving Time', value: '2h6m26s' },
                { inline: true, name: 'Elapsed Time', value: '2h8m6s' },
                { inline: true, name: 'Pace', value: '9m02s/mi' },
                { inline: true, name: 'Speed', value: '6.6mph' },
                { inline: true, name: 'Elevation', value: '475.4ft' },
                { inline: true, name: 'Weather', value: '70°F Rain' }
              ],
              timestamp: tt.utc.iso8601,
              author: {
                name: user.athlete.name,
                url: user.athlete.strava_url
              }
            }
          ]
        )
      end
      context 'with all fields' do
        before do
          team.activity_fields = ['All']
        end
        it 'to_discord' do
          expect(activity.to_discord).to eq(
            embeds: [
              {
                title: activity.name,
                url: "https://www.strava.com/activities/#{activity.strava_id}",
                description: "<@#{activity.user.user_id}> on Tuesday, February 20, 2018 at 10:02 AM",
                image: {
                  url: "https://strada.playplay.io/api/maps/#{activity.map.id}.png"
                },
                fields: [
                  { inline: true, name: 'Type', value: 'Run 🏃' },
                  { inline: true, name: 'Distance', value: '14.01mi' },
                  { inline: true, name: 'Moving Time', value: '2h6m26s' },
                  { inline: true, name: 'Elapsed Time', value: '2h8m6s' },
                  { inline: true, name: 'Pace', value: '9m02s/mi' },
                  { inline: true, name: 'Speed', value: '6.6mph' },
                  { inline: true, name: 'Elevation', value: '475.4ft' },
                  { inline: true, name: 'Max Speed', value: '20.8mph' },
                  { inline: true, name: 'Heart Rate', value: '140.3bpm' },
                  { inline: true, name: 'Max Heart Rate', value: '178.0bpm' },
                  { inline: true, name: 'PR Count', value: '3' },
                  { inline: true, name: 'Calories', value: '870.2' },
                  { inline: true, name: 'Weather', value: '70°F Rain' }
                ],
                timestamp: tt.utc.iso8601,
                author: {
                  name: user.athlete.name,
                  url: user.athlete.strava_url
                }
              }
            ]
          )
        end
      end
      context 'without an athlete' do
        before do
          user.athlete.destroy
        end
        it 'to_discord' do
          expect(activity.reload.to_discord).to eq(
            embeds: [
              {
                title: activity.name,
                url: "https://www.strava.com/activities/#{activity.strava_id}",
                description: "<@#{activity.user.user_id}> on Tuesday, February 20, 2018 at 10:02 AM",
                image: {
                  url: "https://strada.playplay.io/api/maps/#{activity.map.id}.png"
                },
                fields: [
                  { inline: true, name: 'Type', value: 'Run 🏃' },
                  { inline: true, name: 'Distance', value: '14.01mi' },
                  { inline: true, name: 'Moving Time', value: '2h6m26s' },
                  { inline: true, name: 'Elapsed Time', value: '2h8m6s' },
                  { inline: true, name: 'Pace', value: '9m02s/mi' },
                  { inline: true, name: 'Speed', value: '6.6mph' },
                  { inline: true, name: 'Elevation', value: '475.4ft' },
                  { inline: true, name: 'Weather', value: '70°F Rain' }
                ],
                timestamp: tt.utc.iso8601
              }
            ]
          )
        end
      end
    end
    context 'km' do
      let(:team) { Fabricate(:team, units: 'km') }
      let(:user) { Fabricate(:user, team: team) }
      let(:activity) { Fabricate(:user_activity, user: user) }
      it 'to_discord' do
        expect(activity.to_discord).to eq(
          embeds: [
            {
              title: activity.name,
              url: "https://www.strava.com/activities/#{activity.strava_id}",
              description: "<@#{activity.user.user_id}> on Tuesday, February 20, 2018 at 10:02 AM",
              image: {
                url: "https://strada.playplay.io/api/maps/#{activity.map.id}.png"
              },
              fields: [
                { inline: true, name: 'Type', value: 'Run 🏃' },
                { inline: true, name: 'Distance', value: '22.54km' },
                { inline: true, name: 'Moving Time', value: '2h6m26s' },
                { inline: true, name: 'Elapsed Time', value: '2h8m6s' },
                { inline: true, name: 'Pace', value: '5m37s/km' },
                { inline: true, name: 'Speed', value: '10.7km/h' },
                { inline: true, name: 'Elevation', value: '144.9m' },
                { inline: true, name: 'Weather', value: '21°C Rain' }
              ],
              timestamp: tt.utc.iso8601,
              author: {
                name: user.athlete.name,
                url: user.athlete.strava_url
              }
            }
          ]
        )
      end
    end
    context 'both' do
      let(:team) { Fabricate(:team, units: 'both') }
      let(:user) { Fabricate(:user, team: team) }
      let(:activity) { Fabricate(:user_activity, user: user) }
      it 'to_discord' do
        expect(activity.to_discord).to eq(
          embeds: [
            {
              title: activity.name,
              url: "https://www.strava.com/activities/#{activity.strava_id}",
              description: "<@#{activity.user.user_id}> on Tuesday, February 20, 2018 at 10:02 AM",
              image: {
                url: "https://strada.playplay.io/api/maps/#{activity.map.id}.png"
              },
              fields: [
                { inline: true, name: 'Type', value: 'Run 🏃' },
                { inline: true, name: 'Distance', value: '14.01mi 22.54km' },
                { inline: true, name: 'Moving Time', value: '2h6m26s' },
                { inline: true, name: 'Elapsed Time', value: '2h8m6s' },
                { inline: true, name: 'Pace', value: '9m02s/mi 5m37s/km' },
                { inline: true, name: 'Speed', value: '6.6mph 10.7km/h' },
                { inline: true, name: 'Elevation', value: '475.4ft 144.9m' },
                { inline: true, name: 'Weather', value: '70°F 21°C Rain' }
              ],
              timestamp: tt.utc.iso8601,
              author: {
                name: user.athlete.name,
                url: user.athlete.strava_url
              }
            }
          ]
        )
      end
    end
    context 'swim activity in yards' do
      let(:team) { Fabricate(:team) }
      let(:user) { Fabricate(:user, team: team) }
      let(:activity) { Fabricate(:swim_activity, user: user) }
      it 'to_discord' do
        expect(activity.to_discord).to eq(
          embeds: [
            {
              title: activity.name,
              url: "https://www.strava.com/activities/#{activity.strava_id}",
              description: "<@#{activity.user.user_id}> on Tuesday, February 20, 2018 at 10:02 AM",
              fields: [
                { inline: true, name: 'Type', value: 'Swim 🏊' },
                { inline: true, name: 'Distance', value: '2050yd' },
                { inline: true, name: 'Time', value: '37m' },
                { inline: true, name: 'Pace', value: '1m48s/100yd' },
                { inline: true, name: 'Speed', value: '1.9mph' }
              ],
              timestamp: tt.utc.iso8601,
              author: {
                name: user.athlete.name,
                url: user.athlete.strava_url
              }
            }
          ]
        )
      end
    end
    context 'swim activity in meters' do
      let(:team) { Fabricate(:team, units: 'km') }
      let(:user) { Fabricate(:user, team: team) }
      let(:activity) { Fabricate(:swim_activity, user: user) }
      it 'to_discord' do
        expect(activity.to_discord).to eq(
          embeds: [
            {
              title: activity.name,
              url: "https://www.strava.com/activities/#{activity.strava_id}",
              description: "<@#{activity.user.user_id}> on Tuesday, February 20, 2018 at 10:02 AM",
              fields: [
                { inline: true, name: 'Type', value: 'Swim 🏊' },
                { inline: true, name: 'Distance', value: '1874m' },
                { inline: true, name: 'Time', value: '37m' },
                { inline: true, name: 'Pace', value: '1m58s/100m' },
                { inline: true, name: 'Speed', value: '3.0km/h' }
              ],
              timestamp: tt.utc.iso8601,
              author: {
                name: user.athlete.name,
                url: user.athlete.strava_url
              }
            }
          ]
        )
      end
    end
    context 'swim activity in both' do
      let(:team) { Fabricate(:team, units: 'both') }
      let(:user) { Fabricate(:user, team: team) }
      let(:activity) { Fabricate(:swim_activity, user: user) }
      it 'to_discord' do
        expect(activity.to_discord).to eq(
          embeds: [
            {
              title: activity.name,
              url: "https://www.strava.com/activities/#{activity.strava_id}",
              description: "<@#{activity.user.user_id}> on Tuesday, February 20, 2018 at 10:02 AM",
              fields: [
                { inline: true, name: 'Type', value: 'Swim 🏊' },
                { inline: true, name: 'Distance', value: '2050yd 1874m' },
                { inline: true, name: 'Time', value: '37m' },
                { inline: true, name: 'Pace', value: '1m48s/100yd 1m58s/100m' },
                { inline: true, name: 'Speed', value: '1.9mph 3.0km/h' }
              ],
              timestamp: tt.utc.iso8601,
              author: {
                name: user.athlete.name,
                url: user.athlete.strava_url
              }
            }
          ]
        )
      end
    end
    context 'ride activities in kilometers/hour' do
      let(:team) { Fabricate(:team, units: 'km') }
      let(:user) { Fabricate(:user, team: team) }
      let(:activity) { Fabricate(:ride_activity, user: user) }
      it 'to_discord' do
        expect(activity.to_discord).to eq(
          embeds: [
            {
              title: activity.name,
              url: "https://www.strava.com/activities/#{activity.strava_id}",
              description: "<@#{activity.user.user_id}> on Tuesday, February 20, 2018 at 10:02 AM",
              fields: [
                { inline: true, name: 'Type', value: 'Ride 🚴' },
                { inline: true, name: 'Distance', value: '28.1km' },
                { inline: true, name: 'Moving Time', value: '1h10m7s' },
                { inline: true, name: 'Elapsed Time', value: '1h13m30s' },
                { inline: true, name: 'Pace', value: '2m30s/km' },
                { inline: true, name: 'Speed', value: '24.0km/h' }
              ],
              timestamp: tt.utc.iso8601,
              author: {
                name: user.athlete.name,
                url: user.athlete.strava_url
              }
            }
          ]
        )
      end
    end
    context 'ride activities in both' do
      let(:team) { Fabricate(:team, units: 'both') }
      let(:user) { Fabricate(:user, team: team) }
      let(:activity) { Fabricate(:ride_activity, user: user) }
      it 'to_discord' do
        expect(activity.to_discord).to eq(
          embeds: [
            {
              title: activity.name,
              url: "https://www.strava.com/activities/#{activity.strava_id}",
              description: "<@#{activity.user.user_id}> on Tuesday, February 20, 2018 at 10:02 AM",
              fields: [
                { inline: true, name: 'Type', value: 'Ride 🚴' },
                { inline: true, name: 'Distance', value: '17.46mi 28.1km' },
                { inline: true, name: 'Moving Time', value: '1h10m7s' },
                { inline: true, name: 'Elapsed Time', value: '1h13m30s' },
                { inline: true, name: 'Pace', value: '4m01s/mi 2m30s/km' },
                { inline: true, name: 'Speed', value: '14.9mph 24.0km/h' }
              ],
              timestamp: tt.utc.iso8601,
              author: {
                name: user.athlete.name,
                url: user.athlete.strava_url
              }
            }
          ]
        )
      end
    end
  end
  context 'maps' do
    context 'without maps' do
      let(:team) { Fabricate(:team, maps: 'off') }
      let(:user) { Fabricate(:user, team: team) }
      let(:activity) { Fabricate(:user_activity, user: user) }
      let(:embed) { activity.to_discord[:embeds].first }
      it 'to_discord' do
        expect(embed.keys).to_not include :image
        expect(embed.keys).to_not include :thumb
      end
    end
    context 'with thumbnail' do
      let(:team) { Fabricate(:team, maps: 'thumb') }
      let(:user) { Fabricate(:user, team: team) }
      let(:activity) { Fabricate(:user_activity, user: user) }
      let(:embed) { activity.to_discord[:embeds].first }
      it 'to_discord' do
        expect(embed.keys).to_not include :image
        expect(embed[:thumbnail][:url]).to eq "https://strada.playplay.io/api/maps/#{activity.map.id}.png"
      end
    end
  end
end
