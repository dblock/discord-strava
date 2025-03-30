require 'spec_helper'

describe DiscordStrava::Commands::Leaderboard do
  context 'leaderboard' do
    include_context 'discord command' do
      let(:args) { ['leaderboard'] }
    end

    let(:team) { Fabricate(:team, subscribed: true) }

    it 'returns leaderboard' do
      expect_any_instance_of(Team).to receive(:leaderboard).with(
        channel_id: user.channel_id,
        metric: 'distance'
      ).and_call_original
      expect(response).to eq 'There are no activities with distance in this channel.'
    end
  end

  context 'leaderboard with options' do
    include_context 'discord command' do
      let(:args) { ['leaderboard', { 'metric' => 'elapsed_time' }] }
    end

    let(:team) { Fabricate(:team, subscribed: true) }

    it 'displays elapsed time leaderboard' do
      expect(response).to eq 'There are no activities with elapsed time in this channel.'
    end
  end

  context 'with count metric' do
    include_context 'discord command' do
      let(:args) { ['leaderboard', { 'metric' => 'count' }] }
    end

    let(:team) { Fabricate(:team, subscribed: true) }

    it 'does not include the count metric name in the response' do
      expect(response).to eq 'There are no activities in this channel.'
    end
  end

  context 'with a default team leaderboard' do
    context 'without an expression' do
      include_context 'discord command' do
        let(:args) { ['leaderboard'] }
      end

      let(:team) { Fabricate(:team, subscribed: true, default_leaderboard: 'elapsed time since 2025') }

      it 'returns leaderboard' do
        Timecop.freeze do
          start_date = Time.new(2025, 1, 1)
          end_date = Time.now
          expect_any_instance_of(Team).to receive(:leaderboard).with(
            channel_id: user.channel_id,
            metric: 'elapsed_time',
            start_date: start_date,
            end_date: end_date
          ).and_call_original
          expect(response).to eq "There are no activities with elapsed time between #{start_date.to_fs(:long)} and #{end_date.to_fs(:long)} in this channel."
        end
      end
    end

    context 'with an expression' do
      include_context 'discord command' do
        let(:args) { ['leaderboard', { 'metric' => 'two days ago' }] }
      end

      let(:team) { Fabricate(:team, subscribed: true, default_leaderboard: 'elapsed time since 2025') }

      it 'returns leaderboard' do
        dt = Time.now - 2.days
        allow(Chronic).to receive(:parse).with('two days ago', context: :past, guess: false).and_return(dt)
        expect_any_instance_of(Team).to receive(:leaderboard).with(
          channel_id: user.channel_id,
          metric: 'distance',
          start_date: dt
        ).and_call_original
        expect(response).to eq "There are no activities with distance after #{dt.to_fs(:long)} in this channel."
      end
    end
  end

  context 'with a start date' do
    include_context 'discord command' do
      let(:args) { ['leaderboard', { 'metric' => 'two days ago' }] }
    end

    let(:team) { Fabricate(:team, subscribed: true) }

    it 'returns leaderboard' do
      dt = Time.now - 2.days
      allow(Chronic).to receive(:parse).with('two days ago', context: :past, guess: false).and_return(dt)
      expect_any_instance_of(Team).to receive(:leaderboard).with(
        channel_id: user.channel_id,
        metric: 'distance',
        start_date: dt
      ).and_call_original
      expect(response).to eq "There are no activities with distance after #{dt.to_fs(:long)} in this channel."
    end
  end

  context 'with a year' do
    include_context 'discord command' do
      let(:args) { ['leaderboard', { 'metric' => '2023' }] }
    end

    let(:team) { Fabricate(:team, subscribed: true) }

    it 'returns leaderboard' do
      expect_any_instance_of(Team).to receive(:leaderboard).with(
        channel_id: user.channel_id,
        metric: 'distance',
        start_date: Time.new(2023, 1, 1),
        end_date: Time.new(2023, 1, 1).end_of_year
      ).and_call_original
      expect(response).to eq 'There are no activities with distance between January 01, 2023 00:00 and December 31, 2023 23:59 in this channel.'
    end
  end

  context 'with a month' do
    include_context 'discord command' do
      let(:args) { ['leaderboard', { 'metric' => 'September 2023' }] }
    end

    let(:team) { Fabricate(:team, subscribed: true) }

    it 'returns leaderboard' do
      start_date = Time.new(2023, 9, 1, 0, 0, 0)
      end_date = Time.new(2023, 10, 1, 0, 0, 0)
      expect_any_instance_of(Team).to receive(:leaderboard).with(
        channel_id: user.channel_id,
        metric: 'distance',
        start_date: start_date,
        end_date: end_date
      ).and_call_original
      expect(response).to eq 'There are no activities with distance between September 01, 2023 00:00 and October 01, 2023 00:00 in this channel.'
    end
  end

  context 'with an ISO date' do
    include_context 'discord command' do
      let(:args) { ['leaderboard', { 'metric' => 'moving time 2023-03-01' }] }
    end

    let(:team) { Fabricate(:team, subscribed: true) }

    it 'returns leaderboard' do
      start_date = Time.new(2023, 3, 1, 0, 0, 0)
      end_date = Time.new(2023, 3, 2, 0, 0, 0)
      expect_any_instance_of(Team).to receive(:leaderboard).with(
        channel_id: user.channel_id,
        metric: 'moving_time',
        start_date: start_date,
        end_date: end_date
      ).and_call_original
      expect(response).to eq 'There are no activities with moving time between March 01, 2023 00:00 and March 02, 2023 00:00 in this channel.'
    end
  end

  context 'since' do
    include_context 'discord command' do
      let(:args) { ['leaderboard', { 'metric' => 'since September 2023' }] }
    end

    let(:team) { Fabricate(:team, subscribed: true) }

    it 'returns leaderboard' do
      Timecop.freeze do
        start_date = Time.new(2023, 9, 1, 0, 0, 0)
        end_date = Time.now
        expect_any_instance_of(Team).to receive(:leaderboard).with(
          channel_id: user.channel_id,
          metric: 'distance',
          start_date: start_date,
          end_date: end_date
        ).and_call_original
        expect(response).to eq "There are no activities with distance between #{start_date.to_fs(:long)} and #{end_date.to_fs(:long)} in this channel."
      end
    end
  end

  context 'between' do
    include_context 'discord command' do
      let(:args) { ['leaderboard', { 'metric' => 'between September 2023 and August 2024' }] }
    end

    let(:team) { Fabricate(:team, subscribed: true) }

    it 'returns leaderboard' do
      start_date = Time.new(2023, 9, 1, 0, 0, 0)
      end_date = Time.new(2024, 9, 1, 0, 0, 0)
      expect_any_instance_of(Team).to receive(:leaderboard).with(
        channel_id: user.channel_id,
        metric: 'distance',
        start_date: start_date,
        end_date: end_date
      ).and_call_original
      expect(response).to eq 'There are no activities with distance between September 01, 2023 00:00 and September 01, 2024 00:00 in this channel.'
    end
  end
end
