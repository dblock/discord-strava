require 'spec_helper'
require 'nokogiri'

describe Api do
  include Api::Test::EndpointTest

  it 'shares navigation, content layout, and footer across every website page' do
    %w[/ /help.html /privacy.html /connect.html /subscribe.html /update_cc.html].each do |path|
      get path

      expect(last_response.status).to eq 200
      document = Nokogiri::HTML(last_response.body)
      expect(document.at_css('body.site-page > nav[aria-label="Main navigation"]')).not_to be_nil
      expect(document.at_css('main#main')).not_to be_nil
      expect(document.at_css('body > footer.site-footer')).not_to be_nil
    end
  end

  it 'provides concise onboarding and expandable platform-specific help' do
    get '/help.html'

    document = Nokogiri::HTML(last_response.body)
    expect(document.at_css('#get-started').text).to include('/strada connect', '/strada disconnect')
    expect(document.css('#commands details summary').map(&:text)).to include('Sharing and privacy', 'Retention, timezone, and posting limits')
    expect(document.at_css('#support a')['href']).to eq 'mailto:dblock@vestris.com'
  end
end
