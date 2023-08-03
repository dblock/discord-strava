require 'spec_helper'

describe DiscordStrava::Commands::Set do
  let!(:team) { Fabricate(:team, created_at: 2.weeks.ago) }
  let(:app) { DiscordStrava::Server.new(team: team) }
  let(:client) { app.send(:client) }
  let(:user) { Fabricate(:user, team: team) }
  before do
    allow(User).to receive(:find_create_or_update_by_discord_id!).and_return(user)
  end
  context 'settings' do
    it 'requires a subscription' do
      expect(message: "#{DiscordRubyBot.config.user} set units km").to respond_with_discord_message(team.trial_message)
    end
    context 'subscribed team' do
      let(:team) { Fabricate(:team, subscribed: true) }
      it 'errors on invalid setting' do
        expect(message: "#{DiscordRubyBot.config.user} set whatever").to respond_with_discord_message(
          'Invalid setting whatever, type `help` for instructions.'
        )
      end
      it 'shows current settings' do
        expect(message: "#{DiscordRubyBot.config.user} set").to respond_with_discord_message([
          "Activities for team #{team.guild_name} display *miles, feet, yards, and degrees Fahrenheit*.",
          'Activity fields are *set to default*.',
          "Maps for team #{team.guild_name} are *displayed in full*.",
          'Your activities will sync.',
          'Your private activities will not be posted.',
          'Your followers only activities will be posted.'
        ].join("\n"))
      end
      context 'sync' do
        it 'shows default value of sync' do
          expect(message: "#{DiscordRubyBot.config.user} set sync").to respond_with_discord_message(
            'Your activities will sync.'
          )
        end
        it 'shows current value of sync set to true' do
          user.update_attributes!(sync_activities: true)
          expect(message: "#{DiscordRubyBot.config.user} set sync").to respond_with_discord_message(
            'Your activities will sync.'
          )
        end
        it 'sets sync to false' do
          user.update_attributes!(sync_activities: true)
          expect(message: "#{DiscordRubyBot.config.user} set sync false").to respond_with_discord_message(
            'Your activities will no longer sync.'
          )
          expect(user.reload.sync_activities).to be false
        end
        context 'with sync set to false' do
          before do
            user.update_attributes!(sync_activities: false)
          end
          it 'sets sync to true' do
            expect(message: "#{DiscordRubyBot.config.user} set sync true").to respond_with_discord_message(
              'Your activities will now sync.'
            )
            expect(user.reload.sync_activities).to be true
          end
          context 'with prior activities' do
            before do
              allow_any_instance_of(User).to receive(:inform!).and_return({ message_id: 'id', channel_id: 'C1' })
              2.times { Fabricate(:user_activity, user: user) }
              user.brag!
            end
            it 'resets all activities' do
              expect {
                expect {
                  expect(message: "#{DiscordRubyBot.config.user} set sync true").to respond_with_discord_message(
                    'Your activities will now sync.'
                  )
                }.to change(user.activities, :count).by(-2)
              }.to change(user, :activities_at)
            end
          end
        end
      end
      context 'private' do
        it 'shows current value of private' do
          expect(message: "#{DiscordRubyBot.config.user} set private").to respond_with_discord_message(
            'Your private activities will not be posted.'
          )
        end
        it 'shows current value of private set to true' do
          user.update_attributes!(private_activities: true)
          expect(message: "#{DiscordRubyBot.config.user} set private").to respond_with_discord_message(
            'Your private activities will be posted.'
          )
        end
        it 'sets private to false' do
          user.update_attributes!(private_activities: true)
          expect(message: "#{DiscordRubyBot.config.user} set private false").to respond_with_discord_message(
            'Your private activities will no longer be posted.'
          )
          expect(user.reload.private_activities).to be false
        end
        it 'sets private to true' do
          expect(message: "#{DiscordRubyBot.config.user} set private true").to respond_with_discord_message(
            'Your private activities will now be posted.'
          )
          expect(user.reload.private_activities).to be true
        end
      end
      context 'followers only' do
        it 'shows current value of followers_only' do
          expect(message: "#{DiscordRubyBot.config.user} set followers").to respond_with_discord_message(
            'Your followers only activities will be posted.'
          )
        end
        it 'shows current value of followers only set to false' do
          user.update_attributes!(followers_only_activities: false)
          expect(message: "#{DiscordRubyBot.config.user} set followers").to respond_with_discord_message(
            'Your followers only activities will not be posted.'
          )
        end
        it 'sets followers only to false' do
          user.update_attributes!(followers_only_activities: true)
          expect(message: "#{DiscordRubyBot.config.user} set followers false").to respond_with_discord_message(
            'Your followers only activities will no longer be posted.'
          )
          expect(user.reload.followers_only_activities).to be false
        end
        it 'sets followers only to true' do
          user.update_attributes!(followers_only_activities: false)
          expect(message: "#{DiscordRubyBot.config.user} set followers true").to respond_with_discord_message(
            'Your followers only activities will now be posted.'
          )
          expect(user.reload.followers_only_activities).to be true
        end
      end
      context 'as team admin' do
        context 'units' do
          it 'shows current value of units' do
            expect(message: "#{DiscordRubyBot.config.user} set units").to respond_with_discord_message(
              "Activities for team #{team.guild_name} display *miles, feet, yards, and degrees Fahrenheit*."
            )
          end
          it 'shows current value of units set to km' do
            team.update_attributes!(units: 'km')
            expect(message: "#{DiscordRubyBot.config.user} set units").to respond_with_discord_message(
              "Activities for team #{team.guild_name} display *kilometers, meters, and degrees Celcius*."
            )
          end
          it 'sets units to mi' do
            team.update_attributes!(units: 'km')
            expect(message: "#{DiscordRubyBot.config.user} set units mi").to respond_with_discord_message(
              "Activities for team #{team.guild_name} now display *miles, feet, yards, and degrees Fahrenheit*."
            )
            expect(command.team.units).to eq 'mi'
            expect(team.reload.units).to eq 'mi'
          end
          it 'sets units to km' do
            team.update_attributes!(units: 'mi')
            expect(message: "#{DiscordRubyBot.config.user} set units km").to respond_with_discord_message(
              "Activities for team #{team.guild_name} now display *kilometers, meters, and degrees Celcius*."
            )
            expect(command.team.units).to eq 'km'
            expect(team.reload.units).to eq 'km'
          end
          it 'sets units to metric' do
            team.update_attributes!(units: 'mi')
            expect(message: "#{DiscordRubyBot.config.user} set units metric").to respond_with_discord_message(
              "Activities for team #{team.guild_name} now display *kilometers, meters, and degrees Celcius*."
            )
            expect(command.team.units).to eq 'km'
            expect(team.reload.units).to eq 'km'
          end
          it 'sets units to imperial' do
            team.update_attributes!(units: 'km')
            expect(message: "#{DiscordRubyBot.config.user} set units imperial").to respond_with_discord_message(
              "Activities for team #{team.guild_name} now display *miles, feet, yards, and degrees Fahrenheit*."
            )
            expect(command.team.units).to eq 'mi'
            expect(team.reload.units).to eq 'mi'
          end
          it 'changes units' do
            team.update_attributes!(units: 'mi')
            expect(message: "#{DiscordRubyBot.config.user} set units km").to respond_with_discord_message(
              "Activities for team #{team.guild_name} now display *kilometers, meters, and degrees Celcius*."
            )
            expect(command.team.units).to eq 'km'
            expect(team.reload.units).to eq 'km'
          end
          it 'shows current value of units set to both' do
            team.update_attributes!(units: 'both')
            expect(message: "#{DiscordRubyBot.config.user} set units").to respond_with_discord_message(
              "Activities for team #{team.guild_name} display *both units*."
            )
          end
          it 'sets units to both' do
            team.update_attributes!(units: 'km')
            expect(message: "#{DiscordRubyBot.config.user} set units both").to respond_with_discord_message(
              "Activities for team #{team.guild_name} now display *both units*."
            )
            expect(command.team.units).to eq 'both'
            expect(team.reload.units).to eq 'both'
          end
        end
        context 'maps' do
          it 'shows current value of maps' do
            expect(message: "#{DiscordRubyBot.config.user} set maps").to respond_with_discord_message(
              "Maps for team #{team.guild_name} are *displayed in full*."
            )
          end
          it 'shows current value of maps set to thumb' do
            team.update_attributes!(maps: 'thumb')
            expect(message: "#{DiscordRubyBot.config.user} set maps").to respond_with_discord_message(
              "Maps for team #{team.guild_name} are *displayed as thumbnails*."
            )
          end
          it 'sets maps to thumb' do
            team.update_attributes!(maps: 'off')
            expect(message: "#{DiscordRubyBot.config.user} set maps thumb").to respond_with_discord_message(
              "Maps for team #{team.guild_name} are now *displayed as thumbnails*."
            )
            expect(team.reload.maps).to eq 'thumb'
          end
          it 'sets maps to off' do
            expect(message: "#{DiscordRubyBot.config.user} set maps off").to respond_with_discord_message(
              "Maps for team #{team.guild_name} are now *not displayed*."
            )
            expect(team.reload.maps).to eq 'off'
          end
          it 'displays an error for an invalid maps value' do
            expect(message: "#{DiscordRubyBot.config.user} set maps foobar").to respond_with_discord_message(
              'Invalid value: foobar, possible values are full, off and thumb.'
            )
            expect(team.reload.maps).to eq 'full'
          end
        end
        context 'fields' do
          it 'shows current value of fields' do
            expect(message: "#{DiscordRubyBot.config.user} set fields").to respond_with_discord_message(
              "Activity fields for team #{team.guild_name} are *set to default*."
            )
          end
          it 'shows current value of fields set to Time and Elapsed Time' do
            team.update_attributes!(activity_fields: ['Time', 'Elapsed Time'])
            expect(message: "#{DiscordRubyBot.config.user} set fields").to respond_with_discord_message(
              "Activity fields for team #{team.guild_name} are *Time and Elapsed Time*."
            )
          end
          it 'changes fields' do
            expect(message: "#{DiscordRubyBot.config.user} set fields Time, Elapsed Time").to respond_with_discord_message(
              "Activity fields for team #{team.guild_name} are now *Time and Elapsed Time*."
            )
            expect(command.team.activity_fields).to eq(['Time', 'Elapsed Time'])
            expect(team.reload.activity_fields).to eq(['Time', 'Elapsed Time'])
          end
          it 'sets fields to none' do
            expect(message: "#{DiscordRubyBot.config.user} set fields none").to respond_with_discord_message(
              "Activity fields for team #{team.guild_name} are now *not displayed*."
            )
            expect(command.team.activity_fields).to eq(['None'])
            expect(team.reload.activity_fields).to eq(['None'])
          end
          it 'sets fields to all' do
            team.update_attributes!(activity_fields: ['None'])
            expect(message: "#{DiscordRubyBot.config.user} set fields all").to respond_with_discord_message(
              "Activity fields for team #{team.guild_name} are now *all displayed if available*."
            )
            expect(command.team.activity_fields).to eq(['All'])
            expect(team.reload.activity_fields).to eq(['All'])
          end
          it 'sets fields to default' do
            team.update_attributes!(activity_fields: ['All'])
            expect(message: "#{DiscordRubyBot.config.user} set fields default").to respond_with_discord_message(
              "Activity fields for team #{team.guild_name} are now *set to default*."
            )
            expect(command.team.activity_fields).to eq(['Default'])
            expect(team.reload.activity_fields).to eq(['Default'])
          end
          it 'sets to invalid fields' do
            expect(message: "#{DiscordRubyBot.config.user} set fields Time, Foo, Bar").to respond_with_discord_message(
              'Invalid fields: Foo and Bar, possible values are Default, All, None, Type, Distance, Time, Moving Time, Elapsed Time, Pace, Speed, Elevation, Max Speed, Heart Rate, Max Heart Rate, PR Count, Calories and Weather.'
            )
            expect(team.reload.activity_fields).to eq ['Default']
          end
        end
        context 'not as a team admin' do
          let(:user) { Fabricate(:user, team: team) }
          context 'units' do
            it 'shows current value of units' do
              expect(message: "#{DiscordRubyBot.config.user} set units").to respond_with_discord_message(
                "Activities for team #{team.guild_name} display *miles, feet, yards, and degrees Fahrenheit*."
              )
            end
            it 'cannot set units' do
              team.update_attributes!(units: 'km')
              expect(message: "#{DiscordRubyBot.config.user} set units mi").to respond_with_discord_message(
                "Sorry, only a Discord admin can change units. Activities for team #{team.guild_name} display *kilometers, meters, and degrees Celcius*."
              )
              expect(team.reload.units).to eq 'km'
            end
          end
          context 'maps' do
            it 'shows current value of maps' do
              expect(message: "#{DiscordRubyBot.config.user} set maps").to respond_with_discord_message(
                "Maps for team #{team.guild_name} are *displayed in full*."
              )
            end
            it 'cannot set maps' do
              team.update_attributes!(maps: 'full')
              expect(message: "#{DiscordRubyBot.config.user} set maps off").to respond_with_discord_message(
                "Sorry, only a Discord admin can change maps. Maps for team #{team.guild_name} are *displayed in full*."
              )
              expect(team.reload.maps).to eq 'full'
            end
          end
          context 'fields' do
            it 'shows current value of fields' do
              expect(message: "#{DiscordRubyBot.config.user} set fields").to respond_with_discord_message(
                "Activity fields for team #{team.guild_name} are *set to default*."
              )
            end
            it 'cannot set fields' do
              team.update_attributes!(activity_fields: ['None'])
              expect(message: "#{DiscordRubyBot.config.user} set fields all").to respond_with_discord_message(
                "Sorry, only a Discord admin can change fields. Activity fields for team #{team.guild_name} are *not displayed*."
              )
              expect(command.team.activity_fields).to eq(['None'])
            end
          end
        end
      end
    end
  end
end
