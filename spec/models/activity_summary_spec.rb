require 'spec_helper'

describe ActivitySummary do
  let(:activity_summary) { Fabricate(:activity_summary) }
  context '#to_discord_embed' do
    let(:discord_attachment) { activity_summary.to_discord_embed }
    it 'returns a discord attachment' do
      expect(discord_attachment).to eq(
        {
          fallback: '14.01mi in 2h6m26s',
          fields: [
            { short: true, name: 'Runs 🏃', value: '8' },
            { short: true, name: 'Athletes', value: '2' },
            { short: true, name: 'Distance', value: '14.01mi' },
            { short: true, name: 'Moving Time', value: '2h6m26s' },
            { short: true, name: 'Elapsed Time', value: '2h8m6s' },
            { short: true, name: 'Elevation', value: '475.4ft' }
          ]
        }
      )
    end
  end
end
