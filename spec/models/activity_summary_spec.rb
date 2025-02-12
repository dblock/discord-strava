require 'spec_helper'

describe ActivitySummary do
  include_context 'team activation'

  let(:activity_summary) { Fabricate(:activity_summary) }

  describe '#to_discord_embed' do
    let(:discord_attachment) { activity_summary.to_discord_embed }

    it 'returns a discord attachment' do
      expect(discord_attachment).to eq(
        {
          fields: [
            { inline: true, name: 'Runs 🏃', value: '8' },
            { inline: true, name: 'Athletes', value: '2' },
            { inline: true, name: 'Distance', value: '14.01mi' },
            { inline: true, name: 'Moving Time', value: '2h6m26s' },
            { inline: true, name: 'Elapsed Time', value: '2h8m6s' },
            { inline: true, name: 'Elevation', value: '475.4ft' }
          ]
        }
      )
    end
  end
end
