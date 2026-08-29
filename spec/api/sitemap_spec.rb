require 'spec_helper'

describe Api do
  include Api::Test::EndpointTest

  it 'returns a sitemap.xml with the indexable pages' do
    get '/sitemap.xml'
    expect(last_response.status).to eq 200
    expect(last_response.body).to include '<loc>https://strada.playplay.io/</loc>'
    expect(last_response.body).to include '<loc>https://strada.playplay.io/help.html</loc>'
    expect(last_response.body).to include '<loc>https://strada.playplay.io/privacy.html</loc>'
  end
end
