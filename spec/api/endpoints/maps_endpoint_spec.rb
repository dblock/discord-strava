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

    context 'defaults' do
      let(:team) { Fabricate(:team) }
      let(:user) { Fabricate(:user, team: team) }
      let(:activity) { Fabricate(:user_activity, user: user) }

      context 'without cache' do
        before do
          allow_any_instance_of(Map).to receive(:cached_png).and_return(nil)
        end

        it 'redirects to Google map' do
          get "/api/maps/#{activity.map.id}.png"
          expect(last_response.status).to eq 302
          expect(last_response.headers['Location']).to start_with 'https://maps.googleapis.com'
        end
      end

      context 'with cache', vcr: { cassette_name: 'strava/map' } do
        before do
          Api::Middleware.cache.clear
        end

        it 'returns content-type' do
          get "/api/maps/#{activity.map.id}.png"
          expect(last_response.status).to eq 200
          expect(last_response.headers['Content-Type']).to eq 'image/png'
        end

        it 'returns content-length' do
          get "/api/maps/#{activity.map.id}.png"
          expect(last_response.status).to eq 200
          expect(last_response.headers['Content-Length']).to eq last_response.body.size.to_s
        end

        it 'handles if-none-match' do
          get "/api/maps/#{activity.map.id}.png"
          expect(last_response.status).to eq 200
          expect(last_response.headers['ETag']).not_to be_nil
          get "/api/maps/#{activity.map.id}.png", {}, 'HTTP_IF_NONE_MATCH' => last_response.headers['ETag']
          expect(last_response.status).to eq 304
        end

        it 'only fetches map once' do
          expect(Api::Middleware.cache).to receive(:write).once.and_call_original
          2.times do
            get "/api/maps/#{activity.map.id}.png"
            expect(last_response.status).to eq 200
            expect(last_response.headers['Content-Type']).to eq 'image/png'
          end
        end
      end
    end

    context 'with a private activity', vcr: { cassette_name: 'strava/map' } do
      let(:user) { Fabricate(:user, private_activities: false) }
      let(:activity) { Fabricate(:user_activity, private: true, user: user) }

      it 'does not return map' do
        get "/api/maps/#{activity.map.id}.png"
        expect(last_response.status).to eq 403
      end
    end

    context 'without a polyline' do
      let(:user) { Fabricate(:user, private_activities: false) }
      let(:activity) { Fabricate(:user_activity, user: user) }

      before do
        activity.map.update_attributes!(summary_polyline: nil)
      end

      it 'does not return map' do
        get "/api/maps/#{activity.map.id}.png"
        expect(last_response.status).to eq 404
      end
    end
  end
end
