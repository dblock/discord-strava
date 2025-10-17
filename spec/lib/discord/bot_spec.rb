require 'spec_helper'
describe Discord::Bot do
  describe '#instance' do
    context 'with DISCORD_SECRET_TOKEN' do
      before do
        ENV['DISCORD_SECRET_TOKEN'] = 'token'
      end

      after do
        ENV.delete 'DISCORD_SECRET_TOKEN'
      end

      it 'returns a singleton instance' do
        expect(described_class.instance).to be_a(described_class)
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

    context 'without DISCORD_SECRET_TOKEN' do
      before do
        @secret = ENV.fetch('DISCORD_SECRET_TOKEN', nil)
        ENV.delete 'DISCORD_SECRET_TOKEN'
      end

      after do
        ENV['DISCORD_SECRET_TOKEN'] = @secret
      end

      it 'raises an error' do
        expect { described_class.instance }.to raise_error('Missing token type or token.')
      end
    end
  end
end
