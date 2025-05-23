require 'spec_helper'

describe DiscordStrava::App do
  subject do
    DiscordStrava::App.instance
  end

  include_context 'team activation'

  describe '#instance' do
    it 'is an instance of the strava app' do
      expect(subject).to be_a(DiscordStrava::App)
      expect(subject).to be_an_instance_of(DiscordStrava::App)
    end
  end

  describe '#purge_inactive_teams!' do
    it 'purges teams' do
      expect(Team).to receive(:purge!)
      subject.send(:purge_inactive_teams!)
    end
  end

  describe '#deactivate_asleep_teams!' do
    let!(:active_team) { Fabricate(:team, created_at: Time.now.utc) }
    let!(:active_team_one_week_ago) { Fabricate(:team, created_at: 1.week.ago) }
    let!(:active_team_two_weeks_ago) { Fabricate(:team, created_at: 2.weeks.ago) }
    let!(:subscribed_team_a_month_ago) { Fabricate(:team, created_at: 1.month.ago, subscribed: true) }

    it 'destroys teams inactive for two weeks' do
      expect_any_instance_of(Team).to receive(:inform_everyone!).with(
        "Your subscription expired more than 2 weeks ago, deactivating. Reactivate at #{DiscordStrava::Service.url}. Your data will be purged in another 2 weeks."
      ).once
      subject.send(:deactivate_asleep_teams!)
      expect(active_team.reload.active).to be true
      expect(active_team_one_week_ago.reload.active).to be true
      expect(active_team_two_weeks_ago.reload.active).to be false
      expect(subscribed_team_a_month_ago.reload.active).to be true
    end
  end

  context 'subscribed' do
    include_context 'stripe mock'
    let(:plan) { stripe_helper.create_plan(id: 'strada-yearly', amount: 1999) }
    let(:customer) { Stripe::Customer.create(source: stripe_helper.generate_card_token, plan: plan.id, email: 'foo@bar.com', metadata: { name: 'Team', guild_id: 'guild_id' }) }
    let!(:team) { Fabricate(:team, subscribed: true, stripe_customer_id: customer.id) }

    describe '#check_subscribed_teams!' do
      it 'ignores active subscriptions' do
        expect_any_instance_of(Team).not_to receive(:inform_everyone!)
        subject.send(:check_subscribed_teams!)
      end

      it 'notifies past due subscription' do
        customer.subscriptions.data.first['status'] = 'past_due'
        expect(Stripe::Customer).to receive(:retrieve).and_return(customer)
        expect_any_instance_of(Team).to receive(:inform_everyone!).with("Your subscription to StripeMock Default Plan ID ($19.99) is past due. #{team.update_cc_text}")
        subject.send(:check_subscribed_teams!)
      end

      it 'notifies past due subscription' do
        customer.subscriptions.data.first['status'] = 'canceled'
        expect(Stripe::Customer).to receive(:retrieve).and_return(customer)
        expect_any_instance_of(Team).to receive(:inform_everyone!).with('Your subscription to StripeMock Default Plan ID ($19.99) was canceled and your team has been downgraded. Thank you for being a customer!')
        subject.send(:check_subscribed_teams!)
        expect(team.reload.subscribed?).to be false
      end

      it 'notifies no active subscriptions' do
        customer.subscriptions.data = []
        expect(Stripe::Customer).to receive(:retrieve).and_return(customer)
        expect_any_instance_of(Team).to receive(:inform_everyone!).with('Your subscription was canceled and your team has been downgraded. Thank you for being a customer!')
        subject.send(:check_subscribed_teams!)
        expect(team.reload.subscribed?).to be false
      end
    end

    describe '#check_stripe_subscribers!' do
      it 'works without errors' do
        expect(subject.logger).not_to receive(:warn)
        subject.send(:check_stripe_subscribers!)
      end

      context 'inactive team' do
        before do
          team.update_attributes!(active: false)
        end

        it 'cancels auto-renew for an inactive team' do
          expect_any_instance_of(Stripe::Subscription).to receive(:delete)
          subject.send(:check_stripe_subscribers!)
        end
      end
    end
  end

  describe '#check_trials!' do
    let!(:active_team) { Fabricate(:team, created_at: Time.now.utc) }
    let!(:active_team_one_week_ago) { Fabricate(:team, created_at: 1.week.ago) }
    let!(:active_team_twelve_days_ago) { Fabricate(:team, created_at: 12.days.ago) }

    it 'notifies teams' do
      expect_any_instance_of(Team).to receive(:inform_everyone!).with(active_team_twelve_days_ago.trial_message)
      subject.send(:check_trials!)
    end
  end

  describe '#check_access!' do
    let!(:team1) { Fabricate(:team) }
    let!(:team2) { Fabricate(:team) }
    let!(:team3) { Fabricate(:team) }

    [
      'Missing Access (50001, 403)',
      'Missing Permissions (50013, 403)',
      'Unknown Guild (10004, 404)'
    ].each do |error|
      it "deactivates a team on #{error}" do
        allow_any_instance_of(Team).to receive(:guild_info) do |team|
          case team
          when team1
            raise DiscordStrava::Error, error
          when team2
            raise DiscordStrava::Error, 'error'
          end
        end

        subject.send(:check_access!)
        expect(team1.reload.active).to be false
        expect(team2.reload.active).to be true
        expect(team3.reload.active).to be true
      end
    end
  end

  describe '#prune_activities!' do
    let!(:first_team) { Fabricate(:team) }
    let!(:second_team) { Fabricate(:team) }

    before do
      allow(Team).to receive(:each)
        .and_yield(first_team)
        .and_yield(second_team)
    end

    it 'calls prune_activities! on each team' do
      expect(first_team).to receive(:prune_activities!)
      expect(second_team).to receive(:prune_activities!)
      expect(subject.logger).to receive(:info).with(/Pruning activities for \d+ team\(s\)\./)
      expect(subject.logger).to receive(:info).with(%r{Pruned \d+/\d+ activities\.})
      subject.send(:prune_activities!)
    end

    context 'with error during pruning' do
      before do
        allow_any_instance_of(Team).to receive(:prune_activities!).and_raise('Error')
      end

      it 'logs error and continues' do
        expect(subject.logger).to receive(:warn).with(/Error pruning team .*, Error/).twice
        expect(NewRelic::Agent).to receive(:notice_error).twice
        subject.send(:prune_activities!)
      end
    end
  end
end
