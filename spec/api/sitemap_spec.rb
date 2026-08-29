require 'spec_helper'
require 'rexml/document'

describe Api do
  include Api::Test::EndpointTest

  it 'returns a sitemap.xml with the indexable pages' do
    get '/sitemap.xml'
    expect(last_response.status).to eq 200
    expect(last_response.body).to include '<loc>https://strada.playplay.io/</loc>'
    expect(last_response.body).to include '<loc>https://strada.playplay.io/help.html</loc>'
    expect(last_response.body).to include '<loc>https://strada.playplay.io/privacy.html</loc>'
  end

  it 'returns valid XML' do
    get '/sitemap.xml'
    expect { REXML::Document.new(last_response.body) }.not_to raise_error
    doc = REXML::Document.new(last_response.body)
    expect(doc.root.name).to eq 'urlset'
  end
end
