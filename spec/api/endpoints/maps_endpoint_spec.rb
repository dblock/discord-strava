require 'spec_helper'

describe Api::Endpoints::MapsEndpoint do
  include Api::Test::EndpointTest

  context 'maps' do
    context 'without an activity' do
      it '404s' do
        get '/api/maps/5abd07019b0b58f119c1bbaa.png'
        expect(last_response.status).to eq 404
        expect(JSON.parse(last_response.body)).to eq('error' => 'Not Found')
      end
    end

    context 'with an activity' do
      let(:user) { Fabricate(:user) }
      let(:activity) { Fabricate(:user_activity, user:) }

      it 'redirects to map URL' do
        get "/api/maps/#{activity.map.id}.png"
        expect(last_response.status).to eq 302
        expect(last_response.headers['Location']).to eq activity.map.image_url
      end
    end

    context 'with a private activity', vcr: { cassette_name: 'strava/map' } do
      let(:user) { Fabricate(:user, private_activities: false) }
      let(:activity) { Fabricate(:user_activity, private: true, user:) }

      it 'does not return map' do
        get "/api/maps/#{activity.map.id}.png"
        expect(last_response.status).to eq 403
      end
    end

    context 'with an activity witout a map' do
      let(:user) { Fabricate(:user) }
      let(:activity) { Fabricate(:user_activity, user:, map: { summary_polyline: '' }) }

      it 'does not return map' do
        get "/api/maps/#{activity.map.id}.png"
        expect(last_response.status).to eq 404
      end
    end
  end
end
