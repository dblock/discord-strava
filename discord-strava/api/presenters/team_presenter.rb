module Api
  module Presenters
    module TeamPresenter
      include Roar::JSON::HAL
      include Roar::Hypermedia
      include Grape::Roar::Representer

      property :id, type: String, desc: 'Team ID.'
      property :guild_id, type: String, desc: 'Guild ID.'
      property :guild_name, type: String, desc: 'Guild name.'
      property :active, type: Boolean, desc: 'Team is active.'
      property :subscribed, type: Boolean, desc: 'Team is a paid subscriber.'
      property :subscribed_at, type: DateTime, desc: 'Date/time when a subscription was purchased.'
      property :created_at, type: DateTime, desc: 'Date/time when the team was created.'
      property :updated_at, type: DateTime, desc: 'Date/time when the team was accepted, declined or canceled.'

      link :self do |opts|
        request = Grape::Request.new(opts[:env])
        "#{request.base_url}/api/teams/#{id}"
      end
    end
  end
end
