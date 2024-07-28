require 'spec_helper'

describe DiscordStrava::Commands::Connect do
  include_context 'discord command'
  context 'one arg' do
    let(:args) { ['invalid'] }

    it 'fails with an error' do
      expect(response).to eq(
        data: {
          content: "Sorry, I don't understand this command: strada invalid.",
          flags: 64
        },
        type: 4
      )
    end
  end

  context 'no args' do
    it 'fails with an error' do
      expect(response).to eq(
        data: {
          content: "Sorry, I don't understand this command: strada.",
          flags: 64
        },
        type: 4
      )
    end
  end

  context 'three args' do
    let(:args) { ['foo' => 'bar'] }

    it 'fails with an error' do
      expect(response).to eq(
        data: {
          content: "Sorry, I don't understand this command: strada foo bar.",
          flags: 64
        },
        type: 4
      )
    end
  end
end
