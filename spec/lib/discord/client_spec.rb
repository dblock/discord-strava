require 'spec_helper'
describe Discord::Client do
  describe '#initialize' do
    it 'initializes with a token type and token' do
      client = described_class.new('Bot', 'token')
      expect(client.token_type).to eq('Bot')
      expect(client.token).to eq('token')
    end

    it 'sends a bearer authorization header' do
      token = SecureRandom.hex
      client = described_class.new('Bearer', token)
      request = instance_double(Faraday::Request, headers: {}, body: '')
      response = instance_double(Faraday::Response, body: {})
      expect_any_instance_of(Faraday::Connection).to receive(:send)
        .with(:get, 'guilds/guild_id', {})
        .and_yield(request).and_return(response)
      client.info('guild_id')
      expect(request.headers['Authorization']).to eq("Bearer #{token}")
    end
  end
end
