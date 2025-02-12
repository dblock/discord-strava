require 'spec_helper'
describe Discord::Bot do
  describe '#instance' do
    context 'with DISCORD_CLIENT_SECRET' do
      before do
        ENV['DISCORD_CLIENT_SECRET'] = 'token'
      end

      after do
        ENV.delete 'DISCORD_CLIENT_SECRET'
      end

      it 'returns a singleton instance' do
        expect(described_class.instance).to be_a(Discord::Bot)
      end

      it 'initializes with the correct token type and token' do
        expect(described_class.instance.token_type).to eq('Bot')
        expect(described_class.instance.token).to eq('token')
      end

      it 'sends a bot authorization header' do
        request = instance_double(Faraday::Request, headers: {}, body: '')
        response = instance_double(Faraday::Response, body: {})
        expect_any_instance_of(Faraday::Connection).to receive(:send)
          .with(:get, 'guilds/guild_id', {})
          .and_yield(request).and_return(response)
        described_class.instance.info('guild_id')
        expect(request.headers['Authorization']).to eq('Bot token')
      end
    end

    context 'without DISCORD_CLIENT_SECRET' do
      before do
        @secret = ENV.fetch('DISCORD_CLIENT_SECRET', nil)
        ENV.delete 'DISCORD_CLIENT_SECRET'
      end

      after do
        ENV['DISCORD_CLIENT_SECRET'] = @secret
      end

      it 'raises an error' do
        expect { described_class.instance }.to raise_error('Missing token type or token.')
      end
    end
  end
end
