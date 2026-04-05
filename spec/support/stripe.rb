RSpec.shared_context 'stripe mock' do
  let(:stripe_helper) { StripeMock.create_test_helper }
  let(:product) { stripe_helper.create_product(name: 'Default Product') }
  before do
    StripeMock.start
    product
  end

  after do
    StripeMock.stop
  end
end

RSpec.configure do |config|
  config.before do
    allow(Stripe).to receive(:api_key).and_return('key')
  end
end
