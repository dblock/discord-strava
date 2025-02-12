require 'spec_helper'

describe UserActivity do
  include_context 'team activation'

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
        let(:activity) { Fabricate(:user_activity, user:, private: true) }

        it 'is hidden' do
          expect(activity.hidden?).to be true
        end
      end

      context 'private but user is public' do
        let(:user) { Fabricate(:user, private_activities: true) }
        let(:activity) { Fabricate(:user_activity, user:, private: true) }

        it 'is not hidden' do
          expect(activity.hidden?).to be false
        end
      end

      context 'public but user is private' do
        let(:user) { Fabricate(:user, private_activities: false) }
        let(:activity) { Fabricate(:user_activity, user:, private: false) }

        it 'is hidden' do
          expect(activity.hidden?).to be false
        end
      end
    end

    context 'visibility' do
      context 'user has not set followers_only_activities' do
        let(:user) { Fabricate(:user, followers_only_activities: false) }

        context 'only_me' do
          let(:activity) { Fabricate(:user_activity, user:, visibility: 'only_me') }

          it 'is hidden' do
            expect(activity.hidden?).to be true
          end
        end

        context 'followers_only' do
          let(:activity) { Fabricate(:user_activity, user:, visibility: 'followers_only') }

          it 'is hidden' do
            expect(activity.hidden?).to be true
          end
        end

        context 'everyone' do
          let(:activity) { Fabricate(:user_activity, user:, visibility: 'everyone') }

          it 'is not hidden' do
            expect(activity.hidden?).to be false
          end
        end
      end

      context 'user has set followers_only_activities' do
        let(:user) { Fabricate(:user, followers_only_activities: true) }

        context 'only_me' do
          let(:activity) { Fabricate(:user_activity, user:, visibility: 'only_me') }

          it 'is hidden' do
            expect(activity.hidden?).to be true
          end
        end

        context 'followers_only' do
          let(:activity) { Fabricate(:user_activity, user:, visibility: 'followers_only') }

          it 'is not hidden' do
            expect(activity.hidden?).to be false
          end
        end

        context 'everyone' do
          let(:activity) { Fabricate(:user_activity, user:, visibility: 'everyone') }

          it 'is not hidden' do
            expect(activity.hidden?).to be false
          end
        end
      end
    end
  end

  context 'brag!' do
    let(:team) { Fabricate(:team) }
    let(:user) { Fabricate(:user, team:) }
    let!(:activity) { Fabricate(:user_activity, user:) }

    it 'sends a message to the subscribed channel' do
      expect(Discord::Bot.instance).to receive(:send_message).with(
        user.channel_id,
        activity.to_discord
      ).and_return('id' => '1', 'channel_id' => '2')
      expect(activity.brag!).to eq(message_id: '1', channel_id: '2')
    end

    it 'disables user sync on access error' do
      expect(Discord::Bot.instance).to receive(:send_message).with(
        user.channel_id,
        activity.to_discord
      ).and_raise(Faraday::ForbiddenError.new('forbidden'))
      expect { activity.brag! }.to raise_error(Faraday::ForbiddenError)
      expect(activity.bragged_at).not_to be_nil
      expect(user.reload.sync_activities).to be false
    end
  end

  context 'unbrag!' do
    let(:team) { Fabricate(:team) }
    let(:user) { Fabricate(:user, team:) }

    context 'a bragged message' do
      let!(:activity) { Fabricate(:user_activity, user:, channel_message: Fabricate(:channel_message)) }

      it 'deletes a previously sent message' do
        expect(Discord::Bot.instance).to receive(:delete_message).with(
          activity.channel_message.channel_id,
          activity.channel_message.message_id
        ).and_return('id' => '1', 'channel_id' => '2')
        expect(activity.unbrag!).to be_nil
        expect(activity.channel_message).to be_nil
      end

      it 'ignores a previously delete message' do
        allow(Discord::Bot.instance).to receive(:delete_message)
        2.times { expect(activity.unbrag!).to be_nil }
        expect(activity.channel_message).to be_nil
      end
    end

    context 'an unbragged message' do
      let!(:activity) { Fabricate(:user_activity, user:) }

      it 'ignores a previously delete message' do
        expect(Discord::Bot.instance).not_to receive(:delete_message)
        expect(activity.unbrag!).to be_nil
      end
    end
  end

  context 'in time' do
    let!(:tt) { Time.now }

    before do
      Timecop.freeze(tt)
    end

    context 'miles' do
      let(:team) { Fabricate(:team, units: 'mi') }
      let(:user) { Fabricate(:user, team:) }
      let(:activity) { Fabricate(:user_activity, user:) }

      it 'to_discord' do
        expect(activity.to_discord).to eq(
          {
            embeds: [
              {
                title: activity.name,
                url: "https://www.strava.com/activities/#{activity.strava_id}",
                description: "<@#{activity.user.user_id}> 🥇 on Tuesday, February 20, 2018 at 10:02 AM\n\nGreat run!",
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
          }
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
                description: "<@#{activity.user.user_id}> 🥇 on Tuesday, February 20, 2018 at 10:02 AM\n\nGreat run!",
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

      context 'with none fields' do
        before do
          team.activity_fields = ['None']
        end

        it 'to_discord' do
          expect(activity.to_discord).to eq(
            embeds: [
              {
                title: activity.name,
                url: "https://www.strava.com/activities/#{activity.strava_id}",
                description: "<@#{activity.user.user_id}> 🥇 on Tuesday, February 20, 2018 at 10:02 AM\n\nGreat run!",
                image: {
                  url: "https://strada.playplay.io/api/maps/#{activity.map.id}.png"
                },
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

      context 'with all header fields' do
        before do
          team.activity_fields = %w[Title Url User Medal Description Date Athlete]
        end

        it 'to_discord' do
          expect(activity.to_discord).to eq(
            embeds: [
              {
                title: activity.name,
                url: "https://www.strava.com/activities/#{activity.strava_id}",
                description: "<@#{activity.user.user_id}> 🥇 on Tuesday, February 20, 2018 at 10:02 AM\n\nGreat run!",
                image: {
                  url: "https://strada.playplay.io/api/maps/#{activity.map.id}.png"
                },
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

      context 'with all header fields and medal' do
        before do
          team.activity_fields = %w[Title Url User Medal Description Date Athlete]
        end

        it 'to_discord' do
          expect(activity.to_discord).to eq(
            embeds: [
              {
                title: activity.name,
                url: "https://www.strava.com/activities/#{activity.strava_id}",
                description: "<@#{activity.user.user_id}> 🥇 on Tuesday, February 20, 2018 at 10:02 AM\n\nGreat run!",
                image: {
                  url: "https://strada.playplay.io/api/maps/#{activity.map.id}.png"
                },
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

      context 'ranked second' do
        before do
          team.activity_fields = %w[Title Url User Medal Description Date Athlete]
          Fabricate(:user_activity, user: Fabricate(:user, team: team), distance: activity.distance + 1)
        end

        it 'to_discord' do
          expect(activity.to_discord).to eq(
            embeds: [
              {
                title: activity.name,
                url: "https://www.strava.com/activities/#{activity.strava_id}",
                description: "<@#{activity.user.user_id}> 🥈 on Tuesday, February 20, 2018 at 10:02 AM\n\nGreat run!",
                image: {
                  url: "https://strada.playplay.io/api/maps/#{activity.map.id}.png"
                },
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

      context 'without athlete' do
        before do
          team.activity_fields = %w[Title Url User Description Date]
        end

        it 'to_discord' do
          expect(activity.to_discord).to eq(
            embeds: [
              {
                title: activity.name,
                url: "https://www.strava.com/activities/#{activity.strava_id}",
                description: "<@#{activity.user.user_id}> on Tuesday, February 20, 2018 at 10:02 AM\n\nGreat run!",
                image: {
                  url: "https://strada.playplay.io/api/maps/#{activity.map.id}.png"
                },
                timestamp: tt.utc.iso8601
              }
            ]
          )
        end
      end

      context 'without user' do
        before do
          team.activity_fields = %w[Title Url Description Date]
        end

        it 'to_discord' do
          expect(activity.to_discord).to eq(
            embeds: [
              {
                title: activity.name,
                url: "https://www.strava.com/activities/#{activity.strava_id}",
                description: "Tuesday, February 20, 2018 at 10:02 AM\n\nGreat run!",
                image: {
                  url: "https://strada.playplay.io/api/maps/#{activity.map.id}.png"
                },
                timestamp: tt.utc.iso8601
              }
            ]
          )
        end
      end

      context 'without description' do
        before do
          team.activity_fields = %w[Title Url User Date]
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
                timestamp: tt.utc.iso8601
              }
            ]
          )
        end
      end

      context 'without date' do
        before do
          team.activity_fields = %w[Title Url Description]
        end

        it 'to_discord' do
          expect(activity.to_discord).to eq(
            embeds: [
              {
                title: activity.name,
                url: "https://www.strava.com/activities/#{activity.strava_id}",
                description: 'Great run!',
                image: {
                  url: "https://strada.playplay.io/api/maps/#{activity.map.id}.png"
                },
                timestamp: tt.utc.iso8601
              }
            ]
          )
        end
      end

      context 'without url' do
        before do
          team.activity_fields = %w[Title]
        end

        it 'to_discord' do
          expect(activity.to_discord).to eq(
            {
              embeds: [
                {
                  title: activity.name,
                  image: {
                    url: "https://strada.playplay.io/api/maps/#{activity.map.id}.png"
                  },
                  timestamp: tt.utc.iso8601
                }
              ]
            }
          )
        end
      end

      context 'without title' do
        before do
          team.activity_fields = %w[Url]
        end

        it 'to_discord' do
          expect(activity.to_discord).to eq(
            {
              embeds: [
                {
                  title: activity.strava_id.to_s,
                  url: "https://www.strava.com/activities/#{activity.strava_id}",
                  image: {
                    url: "https://strada.playplay.io/api/maps/#{activity.map.id}.png"
                  },
                  timestamp: tt.utc.iso8601
                }
              ]
            }
          )
        end
      end

      context 'without an athlete' do
        before do
          user.athlete.destroy
        end

        it 'to_discord' do
          expect(activity.reload.to_discord).to eq(
            {
              embeds: [
                {
                  title: activity.name,
                  url: "https://www.strava.com/activities/#{activity.strava_id}",
                  description: "<@#{activity.user.user_id}> 🥇 on Tuesday, February 20, 2018 at 10:02 AM\n\nGreat run!",
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
            }
          )
        end
      end

      context 'with a zero speed' do
        before do
          activity.update_attributes!(average_speed: 0.0)
        end

        it 'to_discord' do
          expect(activity.reload.to_discord).to eq(
            {
              embeds: [
                {
                  title: activity.name,
                  url: "https://www.strava.com/activities/#{activity.strava_id}",
                  description: "<@#{activity.user.user_id}> 🥇 on Tuesday, February 20, 2018 at 10:02 AM\n\nGreat run!",
                  image: {
                    url: "https://strada.playplay.io/api/maps/#{activity.map.id}.png"
                  },
                  fields: [
                    { inline: true, name: 'Type', value: 'Run 🏃' },
                    { inline: true, name: 'Distance', value: '14.01mi' },
                    { inline: true, name: 'Moving Time', value: '2h6m26s' },
                    { inline: true, name: 'Elapsed Time', value: '2h8m6s' },
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
            }
          )
        end
      end
    end

    context 'km' do
      let(:team) { Fabricate(:team, units: 'km') }
      let(:user) { Fabricate(:user, team:) }
      let(:activity) { Fabricate(:user_activity, user:) }

      it 'to_discord' do
        expect(activity.to_discord).to eq(
          {
            embeds: [
              {
                title: activity.name,
                url: "https://www.strava.com/activities/#{activity.strava_id}",
                description: "<@#{activity.user.user_id}> 🥇 on Tuesday, February 20, 2018 at 10:02 AM\n\nGreat run!",
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
          }
        )
      end
    end

    context 'both' do
      let(:team) { Fabricate(:team, units: 'both') }
      let(:user) { Fabricate(:user, team:) }
      let(:activity) { Fabricate(:user_activity, user:) }

      it 'to_discord' do
        expect(activity.to_discord).to eq(
          {
            embeds: [
              {
                title: activity.name,
                url: "https://www.strava.com/activities/#{activity.strava_id}",
                description: "<@#{activity.user.user_id}> 🥇 on Tuesday, February 20, 2018 at 10:02 AM\n\nGreat run!",
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
          }
        )
      end
    end

    context 'swim activity in yards' do
      let(:team) { Fabricate(:team) }
      let(:user) { Fabricate(:user, team:) }
      let(:activity) { Fabricate(:swim_activity, user:) }

      it 'to_discord' do
        expect(activity.to_discord).to eq(
          {
            embeds: [
              {
                title: activity.name,
                url: "https://www.strava.com/activities/#{activity.strava_id}",
                description: "<@#{activity.user.user_id}> 🥇 on Tuesday, February 20, 2018 at 10:02 AM",
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
          }
        )
      end
    end

    context 'swim activity in meters' do
      let(:team) { Fabricate(:team, units: 'km') }
      let(:user) { Fabricate(:user, team:) }
      let(:activity) { Fabricate(:swim_activity, user:) }

      it 'to_discord' do
        expect(activity.to_discord).to eq(
          {
            embeds: [
              {
                title: activity.name,
                url: "https://www.strava.com/activities/#{activity.strava_id}",
                description: "<@#{activity.user.user_id}> 🥇 on Tuesday, February 20, 2018 at 10:02 AM",
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
          }
        )
      end
    end

    context 'swim activity in both' do
      let(:team) { Fabricate(:team, units: 'both') }
      let(:user) { Fabricate(:user, team:) }
      let(:activity) { Fabricate(:swim_activity, user:) }

      it 'to_discord' do
        expect(activity.to_discord).to eq(
          {
            embeds: [
              {
                title: activity.name,
                url: "https://www.strava.com/activities/#{activity.strava_id}",
                description: "<@#{activity.user.user_id}> 🥇 on Tuesday, February 20, 2018 at 10:02 AM",
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
          }
        )
      end
    end

    context 'ride activities in kilometers/hour' do
      let(:team) { Fabricate(:team, units: 'km') }
      let(:user) { Fabricate(:user, team:) }
      let(:activity) { Fabricate(:ride_activity, user:) }

      it 'to_discord' do
        expect(activity.to_discord).to eq(
          {
            embeds: [
              {
                title: activity.name,
                url: "https://www.strava.com/activities/#{activity.strava_id}",
                description: "<@#{activity.user.user_id}> 🥇 on Tuesday, February 20, 2018 at 10:02 AM",
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
          }
        )
      end
    end

    context 'ride activities in both' do
      let(:team) { Fabricate(:team, units: 'both') }
      let(:user) { Fabricate(:user, team:) }
      let(:activity) { Fabricate(:ride_activity, user:) }

      it 'to_discord' do
        expect(activity.to_discord).to eq(
          {
            embeds: [
              {
                title: activity.name,
                url: "https://www.strava.com/activities/#{activity.strava_id}",
                description: "<@#{activity.user.user_id}> 🥇 on Tuesday, February 20, 2018 at 10:02 AM",
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
          }
        )
      end
    end

    context 'alpine ski activity' do
      let(:team) { Fabricate(:team) }
      let(:user) { Fabricate(:user, team: team) }
      let(:activity) { Fabricate(:alpine_ski_activity, user: user) }

      it 'to_discord' do
        expect(activity.to_discord).to eq(
          {
            embeds: [
              {
                title: activity.name,
                url: "https://www.strava.com/activities/#{activity.strava_id}",
                description: "<@#{activity.user.user_id}> 🥇 on Wednesday, January 29, 2025 at 09:07 AM",
                fields: [
                  { inline: true, name: 'Type', value: 'Alpine Ski ⛷️' },
                  { inline: true, name: 'Distance', value: '14.35mi' },
                  { inline: true, name: 'Moving Time', value: '1h15m54s' },
                  { inline: true, name: 'Elapsed Time', value: '5h40m27s' }
                ],
                timestamp: tt.utc.iso8601,
                author: {
                  name: user.athlete.name,
                  url: user.athlete.strava_url
                }
              }
            ]
          }
        )
      end
    end
  end

  context 'map' do
    context 'with a summary polyline' do
      let(:activity) { Fabricate(:user_activity) }

      it 'start_latlng' do
        expect(activity.start_latlng).to eq([37.82822, -122.26348])
      end
    end

    context 'with a blank summary polyline' do
      let(:map) { Fabricate.build(:map, summary_polyline: '') }
      let(:activity) { Fabricate(:user_activity, map:) }

      it 'start_latlng' do
        expect(activity.start_latlng).to be_nil
      end
    end
  end

  context 'maps' do
    context 'without maps' do
      let(:team) { Fabricate(:team, maps: 'off') }
      let(:user) { Fabricate(:user, team:) }
      let(:activity) { Fabricate(:user_activity, user:) }
      let(:embed) { activity.to_discord[:embeds].first }

      it 'to_discord' do
        expect(embed.keys).not_to include :image
        expect(embed.keys).not_to include :thumbnail
      end
    end

    context 'with an empty polyline' do
      let(:team) { Fabricate(:team, maps: 'thumb') }
      let(:user) { Fabricate(:user, team:) }
      let(:activity) { Fabricate(:user_activity, user:, map: { summary_polyline: '' }) }
      let(:embed) { activity.to_discord[:embeds].first }

      it 'to_discord' do
        expect(embed.keys).not_to include :image
        expect(embed.keys).not_to include :thumbnail
      end

      it 'does not insert an empty point to the decoded polyline' do
        expect(activity.map.decoded_summary_polyline).to be_nil
      end

      it 'does not have an image' do
        expect(activity.map.has_image?).to be false
        expect(activity.map.image_url).to be_nil
        expect(activity.map.proxy_image_url).to be_nil
      end
    end

    context 'with thumbnail' do
      let(:team) { Fabricate(:team, maps: 'thumb') }
      let(:user) { Fabricate(:user, team:) }
      let(:activity) { Fabricate(:user_activity, user:) }
      let(:embed) { activity.to_discord[:embeds].first }

      it 'to_discord' do
        expect(embed.keys).not_to include :image
        expect(embed[:thumbnail][:url]).to eq "https://strada.playplay.io/api/maps/#{activity.map.id}.png"
      end

      it 'decodes polyline points' do
        expect(activity.map.decoded_summary_polyline.size).to eq 123
        expect(activity.map.decoded_summary_polyline.all? { |p| p[0] && p[1] }).to be true
      end

      it 'has an image' do
        expect(activity.map.has_image?).to be true
        expect(activity.map.image_url).to start_with 'https://maps.googleapis.com/maps/api/staticmap?maptype=roadmap&path='
        expect(activity.map.proxy_image_url).to eq "https://strada.playplay.io/api/maps/#{activity.map.id}.png"
      end
    end
  end

  describe 'create_from_strava!' do
    let(:user) { Fabricate(:user) }
    let(:detailed_activity) do
      Strava::Models::Activity.new(
        JSON.parse(
          File.read(
            File.join(__dir__, '../fabricators/activity.json')
          )
        )
      )
    end

    it 'creates an activity' do
      expect {
        UserActivity.create_from_strava!(user, detailed_activity)
      }.to change(UserActivity, :count).by(1)
    end

    context 'created activity' do
      let(:activity) { UserActivity.create_from_strava!(user, detailed_activity) }
      let(:formatted_time) { 'Wednesday, March 28, 2018 at 07:51 PM' }

      it 'has the correct time zone data' do
        expect(detailed_activity.start_date_local.strftime('%A, %B %d, %Y at %I:%M %p')).to eq formatted_time
        expect(detailed_activity.start_date_local.utc_offset).to eq(-14_400)
      end

      it 'stores the correct time zone' do
        expect(activity.start_date_local_in_local_time.utc_offset).to eq(-14_400)
        expect(activity.start_date_local_s).to eq formatted_time
      end

      it 'preserves the correct time zone across reloads' do
        expect(activity.reload.start_date_local_s).to eq formatted_time
        expect(activity.start_date_local_in_local_time.utc_offset).to eq(-14_400)
      end
    end

    context 'with another existing activity' do
      let!(:activity) { Fabricate(:user_activity, user:) }

      it 'creates another activity' do
        expect {
          UserActivity.create_from_strava!(user, detailed_activity)
        }.to change(UserActivity, :count).by(1)
        expect(user.reload.activities.count).to eq 2
      end
    end

    context 'with an existing activity' do
      let!(:activity) { UserActivity.create_from_strava!(user, detailed_activity) }

      it 'does not create another activity' do
        expect {
          UserActivity.create_from_strava!(user, detailed_activity)
        }.not_to change(UserActivity, :count)
      end

      it 'does not cause a save without changes' do
        expect_any_instance_of(UserActivity).not_to receive(:save!)
        UserActivity.create_from_strava!(user, detailed_activity)
      end

      it 'updates an existing activity' do
        activity.update_attributes!(name: 'Original')
        UserActivity.create_from_strava!(user, detailed_activity)
        expect(activity.reload.name).to eq 'First Time Breaking 14'
      end

      context 'concurrently' do
        before do
          expect(UserActivity).to receive(:where).with(
            strava_id: detailed_activity.id, team_id: user.team.id, user_id: user.id
          ).and_return([])
          allow(UserActivity).to receive(:where).and_call_original
        end

        it 'does not create a duplicate activity' do
          expect {
            expect {
              UserActivity.create_from_strava!(user, detailed_activity)
            }.to raise_error(Mongo::Error::OperationFailure)
          }.not_to change(UserActivity, :count)
        end
      end
    end
  end

  context 'with photos' do
    let!(:tt) { Time.now }
    let(:fixture) { 'spec/fabricators/ride_activity.json' }
    let(:detailed_activity) { Strava::Models::Activity.new(JSON.parse(File.read(fixture))) }
    let(:team) { Fabricate(:team) }
    let(:user) { Fabricate(:user, team:) }
    let(:activity) { UserActivity.create_from_strava!(user, detailed_activity) }

    before do
      Timecop.freeze(tt)
    end

    it 'to_discord' do
      expect(activity.to_discord).to eq(
        embeds: [
          {
            title: activity.name,
            url: "https://www.strava.com/activities/#{activity.strava_id}",
            description: "<@#{activity.user.user_id}> 🥇 on Friday, February 16, 2018 at 06:52 AM",
            image: {
              url: "https://strada.playplay.io/api/maps/#{activity.map.id}.png"
            },
            fields: [
              { inline: true, name: 'Type', value: 'Ride 🚴' },
              { inline: true, name: 'Distance', value: '17.46mi' },
              { inline: true, name: 'Moving Time', value: '1h10m7s' },
              { inline: true, name: 'Elapsed Time', value: '1h13m30s' },
              { inline: true, name: 'Pace', value: '4m01s/mi' },
              { inline: true, name: 'Speed', value: '14.9mph' },
              { inline: true, name: 'Elevation', value: '1692.9ft' }
            ],
            timestamp: tt.utc.iso8601,
            author: {
              name: user.athlete.name,
              url: user.athlete.strava_url
            }
          },
          {
            image: {
              url: 'https://dgtzuqphqg23d.cloudfront.net/Bv93zv5t_mr57v0wXFbY_JyvtucgmU5Ym6N9z_bKeUI-128x96.jpg'
            }
          }
        ]
      )
    end

    context 'without a map' do
      before do
        activity.update_attributes!(map: nil)
      end

      it 'to_discord' do
        expect(activity.to_discord).to eq(
          embeds: [
            {
              title: activity.name,
              url: "https://www.strava.com/activities/#{activity.strava_id}",
              description: "<@#{activity.user.user_id}> 🥇 on Friday, February 16, 2018 at 06:52 AM",
              image: {
                url: 'https://dgtzuqphqg23d.cloudfront.net/Bv93zv5t_mr57v0wXFbY_JyvtucgmU5Ym6N9z_bKeUI-128x96.jpg'
              },
              fields: [
                { inline: true, name: 'Type', value: 'Ride 🚴' },
                { inline: true, name: 'Distance', value: '17.46mi' },
                { inline: true, name: 'Moving Time', value: '1h10m7s' },
                { inline: true, name: 'Elapsed Time', value: '1h13m30s' },
                { inline: true, name: 'Pace', value: '4m01s/mi' },
                { inline: true, name: 'Speed', value: '14.9mph' },
                { inline: true, name: 'Elevation', value: '1692.9ft' }
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
end
