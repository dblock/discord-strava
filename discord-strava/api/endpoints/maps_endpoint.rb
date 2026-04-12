module Api
  module Endpoints
    class MapsEndpoint < Grape::API
      content_type :png, 'image/png'

      # 1x1 transparent PNG pixel returned when a map is not available.
      PIXEL_PNG = Base64.decode64(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAAC0lEQVQI12NgAAIABQAABjE+ibYAAAAASUVORK5CYII='
      ).freeze

      namespace :maps do
        desc 'Redirect to the map URI.'
        params do
          requires :id, type: String
        end
        get ':id' do
          user_agent = headers['User-Agent'] || 'Unknown User-Agent'
          activity = UserActivity.where('map._id' => BSON::ObjectId(params[:id])).first
          unless activity
            Api::Middleware.logger.info "Map #{params[:id]} for #{user_agent}, not found, returning pixel."
            content_type 'image/png'
            next body Api::Endpoints::MapsEndpoint::PIXEL_PNG
          end
          if activity.hidden?
            Api::Middleware.logger.info "Map png for #{activity.user}, #{activity} for #{user_agent}, hidden, returning pixel."
            content_type 'image/png'
            next body Api::Endpoints::MapsEndpoint::PIXEL_PNG
          end
          unless activity.map&.has_image?
            Api::Middleware.logger.info "Map png for #{activity.user}, #{activity} for #{user_agent}, no map, returning pixel."
            content_type 'image/png'
            next body Api::Endpoints::MapsEndpoint::PIXEL_PNG
          end
          if (png = activity.map.cached_png)
            content_type 'image/png'
            Api::Middleware.logger.debug "Map png cached for #{activity.user}, #{activity} for #{user_agent}, #{png.size} byte(s)."
            body png
          else
            redirect activity.map.image_url
          end
        end
      end
    end
  end
end
