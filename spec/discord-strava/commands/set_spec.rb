require 'spec_helper'

describe DiscordStrava::Commands::Set do
  include_context 'discord command' do
    let(:args) { 'set' }
  end
  context 'settings' do
    it 'requires a subscription' do
      expect(response).to eq team.trial_message
    end

    context 'subscribed team' do
      let(:team) { Fabricate(:team, subscribed: true) }

      context 'invalid setting' do
        let(:args) { %w[set whatever] }

        it 'errors' do
          expect(response).to eq 'Invalid setting whatever, type `help` for instructions.'
        end
      end

      it 'shows current settings' do
        expect(response).to eq([
          "Activities for team #{team.guild_name} display *miles, feet, yards, and degrees Fahrenheit*.",
          'Activity fields are *set to default*.',
          "Maps for team #{team.guild_name} are *displayed in full*.",
          'Your activities will sync.',
          'Your private activities will not be posted.',
          'Your followers only activities will be posted.'
        ].join("\n"))
      end

      context 'sync' do
        context 'without arguments' do
          let(:args) { %w[set sync] }

          it 'shows default value of sync' do
            expect(response).to eq(
              'Your activities will sync.'
            )
          end

          it 'shows current value of sync set to true' do
            user.update_attributes!(sync_activities: true)
            expect(response).to eq(
              'Your activities will sync.'
            )
          end
        end

        context 'false' do
          let(:args) { ['set', { 'sync' => 'false' }] }

          it 'sets sync to false' do
            user.update_attributes!(sync_activities: true)
            expect(response).to eq(
              'Your activities will no longer sync.'
            )
            expect(user.reload.sync_activities).to be false
          end
        end

        context 'with sync set to false' do
          before do
            user.update_attributes!(sync_activities: false)
          end

          context 'true' do
            let(:args) { ['set', { 'sync' => 'true' }] }

            it 'sets sync to true' do
              expect(response).to eq(
                'Your activities will now sync.'
              )
              expect(user.reload.sync_activities).to be true
            end

            context 'with prior activities' do
              before do
                allow_any_instance_of(User).to receive(:inform!)
                2.times { Fabricate(:user_activity, user: user) }
                user.brag!
              end

              it 'resets all activities' do
                expect {
                  expect {
                    expect(response).to eq(
                      'Your activities will now sync.'
                    )
                  }.to change(user.activities, :count).by(-2)
                  user.reload
                }.to change(user, :activities_at)
              end
            end
          end
        end
      end

      context 'private' do
        context 'no args' do
          let(:args) { %w[set private] }

          it 'shows current value of private' do
            expect(response).to eq(
              'Your private activities will not be posted.'
            )
          end

          it 'shows current value of private set to true' do
            user.update_attributes!(private_activities: true)
            expect(response).to eq(
              'Your private activities will be posted.'
            )
          end
        end

        context 'false' do
          let(:args) { ['set', { 'private' => 'false' }] }

          it 'sets private to false' do
            user.update_attributes!(private_activities: true)
            expect(response).to eq(
              'Your private activities will no longer be posted.'
            )
            expect(user.reload.private_activities).to be false
          end
        end

        context 'true' do
          let(:args) { ['set', { 'private' => 'true' }] }

          it 'sets private to true' do
            expect(response).to eq(
              'Your private activities will now be posted.'
            )
            expect(user.reload.private_activities).to be true
          end
        end
      end

      context 'followers only' do
        context 'no args' do
          let(:args) { %w[set followers] }

          it 'shows current value of followers_only' do
            expect(response).to eq(
              'Your followers only activities will be posted.'
            )
          end

          it 'shows current value of followers only set to false' do
            user.update_attributes!(followers_only_activities: false)
            expect(response).to eq(
              'Your followers only activities will not be posted.'
            )
          end
        end

        context 'false' do
          let(:args) { ['set', { 'followers' => 'false' }] }

          it 'sets followers only to false' do
            user.update_attributes!(followers_only_activities: true)
            expect(response).to eq(
              'Your followers only activities will no longer be posted.'
            )
            expect(user.reload.followers_only_activities).to be false
          end
        end

        context 'true' do
          let(:args) { ['set', { 'followers' => 'true' }] }

          it 'sets followers only to true' do
            user.update_attributes!(followers_only_activities: false)
            expect(response).to eq(
              'Your followers only activities will now be posted.'
            )
            expect(user.reload.followers_only_activities).to be true
          end
        end
      end

      context 'as team admin' do
        before do
          allow_any_instance_of(User).to receive(:guild_owner?).and_return(true)
        end

        context 'units' do
          context 'no args' do
            let(:args) { %w[set units] }

            it 'shows current value of units' do
              expect(response).to eq(
                "Activities for team #{team.guild_name} display *miles, feet, yards, and degrees Fahrenheit*."
              )
            end

            it 'shows current value of units set to km' do
              team.update_attributes!(units: 'km')
              expect(response).to eq(
                "Activities for team #{team.guild_name} display *kilometers, meters, and degrees Celcius*."
              )
            end

            it 'shows current value of units set to both' do
              team.update_attributes!(units: 'both')
              expect(response).to eq(
                "Activities for team #{team.guild_name} display *both units*."
              )
            end
          end

          context 'mi' do
            let(:args) { ['set', { 'units' => 'mi' }] }

            it 'sets units to mi' do
              team.update_attributes!(units: 'km')
              expect(response).to eq(
                "Activities for team #{team.guild_name} now display *miles, feet, yards, and degrees Fahrenheit*."
              )
              expect(command.team.units).to eq 'mi'
              expect(team.reload.units).to eq 'mi'
            end
          end

          context 'km' do
            let(:args) { ['set', { 'units' => 'km' }] }

            it 'sets units to km' do
              team.update_attributes!(units: 'mi')
              expect(response).to eq(
                "Activities for team #{team.guild_name} now display *kilometers, meters, and degrees Celcius*."
              )
              expect(command.team.units).to eq 'km'
              expect(team.reload.units).to eq 'km'
            end
          end

          context 'metric' do
            let(:args) { ['set', { 'units' => 'metric' }] }

            it 'sets units to metric' do
              team.update_attributes!(units: 'mi')
              expect(response).to eq(
                "Activities for team #{team.guild_name} now display *kilometers, meters, and degrees Celcius*."
              )
              expect(command.team.units).to eq 'km'
              expect(team.reload.units).to eq 'km'
            end
          end

          context 'imperial' do
            let(:args) { ['set', { 'units' => 'imperial' }] }

            it 'sets units to imperial' do
              team.update_attributes!(units: 'km')
              expect(response).to eq(
                "Activities for team #{team.guild_name} now display *miles, feet, yards, and degrees Fahrenheit*."
              )
              expect(command.team.units).to eq 'mi'
              expect(team.reload.units).to eq 'mi'
            end
          end

          context 'km' do
            let(:args) { ['set', { 'units' => 'km' }] }

            it 'changes units' do
              team.update_attributes!(units: 'mi')
              expect(response).to eq(
                "Activities for team #{team.guild_name} now display *kilometers, meters, and degrees Celcius*."
              )
              expect(command.team.units).to eq 'km'
              expect(team.reload.units).to eq 'km'
            end
          end

          context 'both' do
            let(:args) { ['set', { 'units' => 'both' }] }

            it 'sets units to both' do
              team.update_attributes!(units: 'km')
              expect(response).to eq(
                "Activities for team #{team.guild_name} now display *both units*."
              )
              expect(command.team.units).to eq 'both'
              expect(team.reload.units).to eq 'both'
            end
          end
        end

        context 'maps' do
          context 'no args' do
            let(:args) { %w[set maps] }

            it 'shows current value of maps' do
              expect(response).to eq(
                "Maps for team #{team.guild_name} are *displayed in full*."
              )
            end

            it 'shows current value of maps set to thumb' do
              team.update_attributes!(maps: 'thumb')
              expect(response).to eq(
                "Maps for team #{team.guild_name} are *displayed as thumbnails*."
              )
            end
          end

          context 'thumb' do
            let(:args) { ['set', { 'maps' => 'thumb' }] }

            it 'sets maps to thumb' do
              team.update_attributes!(maps: 'off')
              expect(response).to eq(
                "Maps for team #{team.guild_name} are now *displayed as thumbnails*."
              )
              expect(team.reload.maps).to eq 'thumb'
            end
          end

          context 'off' do
            let(:args) { ['set', { 'maps' => 'off' }] }

            it 'sets maps to off' do
              expect(response).to eq(
                "Maps for team #{team.guild_name} are now *not displayed*."
              )
              expect(team.reload.maps).to eq 'off'
            end
          end

          context 'foobar' do
            let(:args) { ['set', { 'maps' => 'foobar' }] }

            it 'displays an error for an invalid maps value' do
              expect(response).to eq(
                'Invalid value: foobar, possible values are full, off and thumb.'
              )
              expect(team.reload.maps).to eq 'full'
            end
          end
        end

        context 'fields' do
          context 'no value' do
            let(:args) { %w[set fields] }

            it 'shows current value of fields' do
              expect(response).to eq(
                "Activity fields for team #{team.guild_name} are *set to default*."
              )
            end

            it 'shows current value of fields set to Time and Elapsed Time' do
              team.update_attributes!(activity_fields: ['Time', 'Elapsed Time'])
              expect(response).to eq(
                "Activity fields for team #{team.guild_name} are *Time and Elapsed Time*."
              )
            end
          end

          context 'times' do
            let(:args) { ['set', { 'fields' => 'Time, Elapsed Time' }] }

            it 'changes fields' do
              expect(response).to eq(
                "Activity fields for team #{team.guild_name} are now *Time and Elapsed Time*."
              )
              expect(command.team.activity_fields).to eq(['Time', 'Elapsed Time'])
              expect(team.reload.activity_fields).to eq(['Time', 'Elapsed Time'])
            end
          end

          context 'none' do
            let(:args) { ['set', { 'fields' => 'none' }] }

            it 'sets fields to none' do
              expect(response).to eq(
                "Activity fields for team #{team.guild_name} are now *not displayed*."
              )
              expect(command.team.activity_fields).to eq(['None'])
              expect(team.reload.activity_fields).to eq(['None'])
            end
          end

          context 'all' do
            let(:args) { ['set', { 'fields' => 'all' }] }

            it 'sets fields to all' do
              team.update_attributes!(activity_fields: ['None'])
              expect(response).to eq(
                "Activity fields for team #{team.guild_name} are now *all displayed if available*."
              )
              expect(command.team.activity_fields).to eq(['All'])
              expect(team.reload.activity_fields).to eq(['All'])
            end
          end

          context 'default' do
            let(:args) { ['set', { 'fields' => 'default' }] }

            it 'sets fields to default' do
              team.update_attributes!(activity_fields: ['All'])
              expect(response).to eq(
                "Activity fields for team #{team.guild_name} are now *set to default*."
              )
              expect(command.team.activity_fields).to eq(['Default'])
              expect(team.reload.activity_fields).to eq(['Default'])
            end
          end

          context 'some' do
            let(:args) { ['set', { 'fields' => 'Title, Url, PR Count, Elapsed Time' }] }

            it 'sets fields to default' do
              team.update_attributes!(activity_fields: ['All'])
              expect(response).to eq(
                "Activity fields for team #{team.guild_name} are now *Title, Url, PR Count and Elapsed Time*."
              )
              expect(command.team.activity_fields).to eq(['Title', 'Url', 'PR Count', 'Elapsed Time'])
              expect(team.reload.activity_fields).to eq(['Title', 'Url', 'PR Count', 'Elapsed Time'])
            end
          end

          context 'each field' do
            (ActivityFields.values - [ActivityFields::ALL, ActivityFields::DEFAULT, ActivityFields::NONE]).each do |field|
              context field do
                let(:args) { ['set', { 'fields' => field }] }

                it "sets fields to #{field}" do
                  team.update_attributes!(activity_fields: ['All'])
                  expect(response).to eq(
                    "Activity fields for team #{team.guild_name} are now *#{field}*."
                  )
                  expect(command.team.activity_fields).to eq([field])
                  expect(team.reload.activity_fields).to eq([field])
                end
              end
            end
          end

          context 'invalid' do
            let(:args) { ['set', { 'fields' => 'Time, Foo, Bar' }] }

            it 'sets to invalid fields' do
              expect(response).to eq(
                'Invalid fields: Foo and Bar, possible values are Default, All, None, Type, Distance, Time, Moving Time, Elapsed Time, Pace, Speed, Elevation, Max Speed, Heart Rate, Max Heart Rate, PR Count, Calories, Weather, Title, Description, Url, User, Athlete and Date.'
              )
              expect(team.reload.activity_fields).to eq ['Default']
            end
          end
        end

        context 'not as a team admin' do
          before do
            allow_any_instance_of(User).to receive(:guild_owner?).and_return(false)
          end

          context 'units' do
            context 'no args' do
              let(:args) { %w[set units] }

              it 'shows current value of units' do
                expect(response).to eq(
                  "Activities for team #{team.guild_name} display *miles, feet, yards, and degrees Fahrenheit*."
                )
              end
            end

            context 'mi' do
              let(:args) { ['set', { 'units' => 'mi' }] }

              it 'cannot set units' do
                team.update_attributes!(units: 'km')
                expect(response).to eq(
                  "Sorry, only a Discord admin can change units. Activities for team #{team.guild_name} display *kilometers, meters, and degrees Celcius*."
                )
                expect(team.reload.units).to eq 'km'
              end
            end
          end

          context 'maps' do
            context 'no args' do
              let(:args) { %w[set maps] }

              it 'shows current value of maps' do
                expect(response).to eq(
                  "Maps for team #{team.guild_name} are *displayed in full*."
                )
              end
            end

            context 'off' do
              let(:args) { ['set', { 'maps' => 'off' }] }

              it 'cannot set maps' do
                team.update_attributes!(maps: 'full')
                expect(response).to eq(
                  "Sorry, only a Discord admin can change maps. Maps for team #{team.guild_name} are *displayed in full*."
                )
                expect(team.reload.maps).to eq 'full'
              end
            end
          end

          context 'fields' do
            context 'no args' do
              let(:args) { %w[set fields] }

              it 'shows current value of fields' do
                expect(response).to eq(
                  "Activity fields for team #{team.guild_name} are *set to default*."
                )
              end
            end

            context 'all' do
              let(:args) { ['set', { 'fields' => 'all' }] }

              it 'cannot set fields' do
                team.update_attributes!(activity_fields: ['None'])
                expect(response).to eq(
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
end
