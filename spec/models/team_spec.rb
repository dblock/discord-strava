require 'spec_helper'

describe Team do
  include_context 'team activation'

  describe '#purge!' do
    let!(:active_team) { Fabricate(:team) }
    let!(:inactive_team) { Fabricate(:team, active: false) }
    let!(:inactive_team_one_week_ago) { Fabricate(:team, updated_at: 1.week.ago, active: false) }
    let!(:inactive_team_two_weeks_ago) { Fabricate(:team, updated_at: 2.weeks.ago, active: false) }
    let!(:inactive_team_a_month_ago) { Fabricate(:team, updated_at: 1.month.ago, active: false) }

    it 'destroys teams inactive for two weeks' do
      expect {
        described_class.purge!
      }.to change(described_class, :count).by(-2)
      expect(described_class.find(active_team.id)).to eq active_team
      expect(described_class.find(inactive_team.id)).to eq inactive_team
      expect(described_class.find(inactive_team_one_week_ago.id)).to eq inactive_team_one_week_ago
      expect(described_class.find(inactive_team_two_weeks_ago.id)).to be_nil
      expect(described_class.find(inactive_team_a_month_ago.id)).to be_nil
    end

    context 'with a subscribed team' do
      before do
        inactive_team_a_month_ago.set(subscribed: true)
      end

      it 'does not destroy team the subscribed team' do
        expect {
          described_class.purge!
        }.to change(described_class, :count).by(-1)
        expect(described_class.find(inactive_team_two_weeks_ago.id)).to be_nil
        expect(described_class.find(inactive_team_a_month_ago.id)).not_to be_nil
      end
    end
  end

  describe '#asleep?' do
    context 'default' do
      let(:team) { Fabricate(:team, created_at: Time.now.utc) }

      it 'false' do
        expect(team.asleep?).to be false
      end
    end

    context 'team created two weeks ago' do
      let(:team) { Fabricate(:team, created_at: 2.weeks.ago) }

      it 'is asleep' do
        expect(team.asleep?).to be true
      end
    end

    context 'team created two weeks ago and subscribed' do
      let(:team) { Fabricate(:team, created_at: 2.weeks.ago, subscribed: true) }

      before do
        allow(team).to receive(:inform_subscribed_changed!)
        team.update_attributes!(subscribed: true)
      end

      it 'is not asleep' do
        expect(team.asleep?).to be false
      end

      it 'resets subscription_expired_at' do
        expect(team.subscription_expired_at).to be_nil
      end
    end

    context 'team created over two weeks ago' do
      let(:team) { Fabricate(:team, created_at: 2.weeks.ago - 1.day) }

      it 'is asleep' do
        expect(team.asleep?).to be true
      end
    end

    context 'team created over two weeks ago and subscribed' do
      let(:team) { Fabricate(:team, created_at: 2.weeks.ago - 1.day, subscribed: true) }

      it 'is not asleep' do
        expect(team.asleep?).to be false
      end
    end
  end

  describe '#subscription_expired!' do
    let(:team) { Fabricate(:team, created_at: 2.weeks.ago) }

    before do
      expect(team).to receive(:inform_system!).with(team.subscribe_text)
      expect(team).to receive(:inform_guild_owner!).with(team.subscribe_text)
      team.subscription_expired!
    end

    it 'sets subscription_expired_at' do
      expect(team.subscription_expired_at).not_to be_nil
    end

    context '(re)subscribed' do
      before do
        expect(team).to receive(:inform_system!).with(team.subscribed_text)
        expect(team).to receive(:inform_guild_owner!).with(team.subscribed_text)
        team.update_attributes!(subscribed: true)
      end

      it 'resets subscription_expired_at' do
        expect(team.subscription_expired_at).to be_nil
      end
    end
  end

  context 'subscribed states' do
    let(:today) { DateTime.parse('2018/7/15 12:42pm') }
    let(:subscribed_team) { Fabricate(:team, subscribed: true) }
    let(:team_created_today) { Fabricate(:team, created_at: today) }
    let(:team_created_1_week_ago) { Fabricate(:team, created_at: (today - 1.week)) }
    let(:team_created_3_weeks_ago) { Fabricate(:team, created_at: (today - 3.weeks)) }

    before do
      Timecop.travel(today + 1.day)
    end

    after do
      Timecop.return
    end

    it 'subscription_expired?' do
      expect(subscribed_team.subscription_expired?).to be false
      expect(team_created_1_week_ago.subscription_expired?).to be false
      expect(team_created_3_weeks_ago.subscription_expired?).to be true
    end

    it 'trial_ends_at' do
      expect { subscribed_team.trial_ends_at }.to raise_error 'Team is subscribed.'
      expect(team_created_today.trial_ends_at).to eq team_created_today.created_at + 2.weeks
      expect(team_created_1_week_ago.trial_ends_at).to eq team_created_1_week_ago.created_at + 2.weeks
      expect(team_created_3_weeks_ago.trial_ends_at).to eq team_created_3_weeks_ago.created_at + 2.weeks
    end

    it 'remaining_trial_days' do
      expect { subscribed_team.remaining_trial_days }.to raise_error 'Team is subscribed.'
      expect(team_created_today.remaining_trial_days).to eq 13
      expect(team_created_1_week_ago.remaining_trial_days).to eq 6
      expect(team_created_3_weeks_ago.remaining_trial_days).to eq 0
    end

    describe '#inform_trial!' do
      it 'subscribed' do
        expect(subscribed_team).not_to receive(:inform!)
        expect(subscribed_team).not_to receive(:inform_guild_owner!)
        subscribed_team.inform_trial!
      end

      it '1 week ago' do
        expect(team_created_1_week_ago).to receive(:inform_system!).with(
          "Your trial subscription expires in 6 days. #{team_created_1_week_ago.subscribe_text}"
        )
        expect(team_created_1_week_ago).to receive(:inform_guild_owner!).with(
          "Your trial subscription expires in 6 days. #{team_created_1_week_ago.subscribe_text}"
        )
        team_created_1_week_ago.inform_trial!
      end

      it 'expired' do
        expect(team_created_3_weeks_ago).not_to receive(:inform_system!)
        expect(team_created_3_weeks_ago).not_to receive(:inform_guild_owner!)
        team_created_3_weeks_ago.inform_trial!
      end

      it 'informs once' do
        expect(team_created_1_week_ago).to receive(:inform_system!).once
        expect(team_created_1_week_ago).to receive(:inform_guild_owner!).once
        2.times { team_created_1_week_ago.inform_trial! }
      end
    end
  end

  describe '#destroy' do
    let!(:team) { Fabricate(:team) }
    let!(:user1) { Fabricate(:user, team:) }
    let!(:user2) { Fabricate(:user, team:, access_token: 'token', token_expires_at: Time.now + 1.day, token_type: 'Bearer') }

    it 'revokes access tokens' do
      allow(team).to receive(:users).and_return([user1, user2])
      expect(user1).to receive(:revoke_access_token!)
      expect(user2).to receive(:revoke_access_token!)
      team.destroy
    end
  end

  describe '#deactivate!' do
    let!(:team) { Fabricate(:team) }

    it 'sets active to false' do
      expect(team.active).to be true
      team.deactivate!
      expect(team.active).to be false
    end
  end

  describe '#check_access' do
    let(:team) { Fabricate(:team) }

    it 'deactivates a team on missing access' do
      allow(team).to receive(:guild_info).and_raise DiscordStrava::Error, 'Missing Access (50001, 403)'
      expect(team).to receive(:deactivate!).and_call_original
      team.check_access!
      expect(team.active).to be false
    end
  end

  describe '#update_info!' do
    let(:team) { Fabricate(:team) }

    it 'updates the bot owner' do
      team.update_info!
      expect(team.bot_owner_name).to eq 'bot_owner_name'
      expect(team.bot_owner_id).to eq 'bot_owner_id'
    end
  end

  describe '#inform_guild_owner!' do
    before do
      allow_any_instance_of(described_class).to receive(:update_info!)

      allow(Discord::Bot.instance).to receive(:send_dm)
        .with('guild_owner_id', 'message')
        .and_return('id' => 'm1', 'channel_id' => 'c1')

      allow(Discord::Bot.instance).to receive(:send_dm)
        .with('bot_owner_id', 'message')
        .and_return('id' => 'm2', 'channel_id' => 'c2')
    end

    context 'team with two different guild owners' do
      let(:team) { Fabricate(:team, guild_owner_id: 'guild_owner_id', bot_owner_id: 'bot_owner_id') }

      it 'returns an array of messages' do
        expect(team.guild_owners).to eq %w[guild_owner_id bot_owner_id]
        expect(team.inform_guild_owner!('message')).to eq [{
          message_id: 'm1',
          channel_id: 'c1'
        }, {
          message_id: 'm2',
          channel_id: 'c2'
        }]
      end
    end

    context 'team with the same guild owners' do
      let(:team) { Fabricate(:team, guild_owner_id: 'guild_owner_id', bot_owner_id: 'guild_owner_id') }

      it 'returns one message' do
        expect(team.guild_owners).to eq ['guild_owner_id']
        expect(team.inform_guild_owner!('message')).to eq [{
          message_id: 'm1',
          channel_id: 'c1'
        }]
      end
    end

    context 'team with no guild owners' do
      let(:team) { Fabricate(:team, guild_owner_id: nil, bot_owner_id: nil) }

      it 'returns nil' do
        expect(team.guild_owners).to eq []
        expect(team.inform_guild_owner!('message')).to be_nil
      end
    end
  end

  describe '#prune_activities!' do
    before do
      # skip re-saving map in ActivityFabricator#after_create which updates timestamps
      allow_any_instance_of(Map).to receive(:save!)
    end

    let!(:team) { Fabricate(:team) }
    let!(:user) { Fabricate(:user, team: team) }
    let!(:team2) { Fabricate(:team) }
    let!(:user2) { Fabricate(:user, team: team2) }
    let!(:recent_activity) { Fabricate(:user_activity, user: user, updated_at: Time.now - 15.days) }
    let!(:old_activity) { Fabricate(:user_activity, user: user, updated_at: Time.now - 31.days) }
    let!(:very_old_activity) { Fabricate(:user_activity, user: user, updated_at: Time.now - 60.days) }
    let!(:other_team_activity) { Fabricate(:user_activity, team: team2, user: user2, updated_at: Time.now - 31.days) }

    it 'removes activities older than 30 days' do
      expect(team.activities.count).to eq 3
      expect {
        expect(team.prune_activities!).to eq 2
      }.to change(team.activities, :count).by(-2)
      expect(team.activities.count).to eq 1
      expect(team.activities.first).to eq recent_activity
    end

    context 'with a retention period of 45 days' do
      before do
        team.update_attributes!(retention: 45 * 24 * 60 * 60)
      end

      it 'removes older activities' do
        expect(team.activities.count).to eq 3
        expect {
          expect(team.prune_activities!).to eq 1
        }.to change(team.activities, :count).by(-1)
        expect(team.activities.count).to eq 2
        expect(team.activities.first).to eq recent_activity
      end
    end

    it 'does not affect other teams activities' do
      expect {
        team.prune_activities!
      }.not_to change(other_team_activity.team.activities, :count)
    end
  end

  describe '#retention' do
    context 'default value' do
      let(:team) { Fabricate(:team) }

      it 'sets default retention to 30 days in seconds' do
        expect(team.retention).to eq(30 * 24 * 60 * 60)
      end
    end

    context 'validation' do
      let(:team) { Fabricate(:team) }

      it 'allows valid retention periods' do
        [24 * 60 * 60, 7 * 24 * 60 * 60, 6 * 30 * 24 * 60 * 60].each do |retention|
          team.retention = retention
          expect(team).to be_valid
        end
      end

      it 'rejects retention less than 24 hours' do
        team.retention = 23 * 60 * 60
        expect(team).not_to be_valid
        expect(team.errors[:team]).to include('Retention must be at least 24 hours.')
      end

      it 'rejects retention more than 6 months' do
        team.retention = (6 * 30 * 24 * 60 * 60) + 1
        expect(team).not_to be_valid
        expect(team.errors[:team]).to include('Retention cannot exceed 6 months.')
      end

      it 'allows nil retention' do
        team.retention = nil
        expect(team).to be_valid
      end
    end
  end
end
