module Api
  module Endpoints
    class StravaEndpoint < Grape::API
      format :json

      namespace :strava do
        namespace :event do
          desc 'Respond to a webhook challenge.'
          params do
            requires 'hub.verify_token', type: String
            requires 'hub.challenge', type: String
            requires 'hub.mode', type: String
          end
          get do
            Api::Middleware.logger.info "Responding to a Strava webhook #{params['hub.mode']} challenge (#{params['hub.verify_token']})."
            error!('Invalid token', 403) unless params['hub.verify_token'] == StravaWebhook.instance.verify_token
            { 'hub.challenge' => params['hub.challenge'] }
          end

          desc 'Respond to a webhook event.'
          params do
            requires 'object_type', type: String
            requires 'object_id', type: String
            requires 'aspect_type', type: String
            requires 'updates', type: Hash
            requires 'owner_id', type: String
            requires 'subscription_id', type: String
            requires 'event_time', type: Time, coerce_with: ->(v) { Time.at(v) }
          end
          post do
            case params['object_type']
            when 'activity'
              case params['aspect_type']
              when 'create'
                User.connected_to_strava.where('athlete.athlete_id' => params['owner_id']).each do |user|
                  if !user.team.active?
                    Api::Middleware.logger.info "Team #{user.team} is inactive, user #{user}, #{user.athlete}, #{params['object_type']}=#{params['object_id']}."
                  elsif user.team.subscription_expired?
                    Api::Middleware.logger.info "Team #{user.team} subscription expired, user #{user}, #{user.athlete}, #{params['object_type']}=#{params['object_id']}."
                  else
                    Api::Middleware.logger.info "Syncing activity for team #{user.team}, user #{user}, #{user.athlete}, #{params['object_type']}=#{params['object_id']}."
                    begin
                      user.sync_and_brag!
                    rescue StandardError => e
                      Api::Middleware.logger.warn "Error syncing new activity for team #{user.team}, user #{user}, #{user.athlete}, #{params['object_type']}=#{params['object_id']}: #{e}."
                    end
                  end
                end
              when 'update'
                User.connected_to_strava.where('athlete.athlete_id' => params['owner_id']).each do |user|
                  if !user.team.active?
                    Api::Middleware.logger.info "Team #{user.team} inactive, user #{user}, #{user.athlete}, #{params['object_type']}=#{params['object_id']}."
                  elsif user.team.subscription_expired?
                    Api::Middleware.logger.info "Team #{user.team} subscription expired, user #{user}, #{user.athlete}, #{params['object_type']}=#{params['object_id']}."
                  else
                    activity = user.activities.where(strava_id: params['object_id']).first
                    if activity
                      Api::Middleware.logger.info "Updating activity team #{user.team}, user #{user}, #{user.athlete}, #{params['object_type']}=#{params['object_id']}, #{params['updates']}."
                      begin
                        user.rebrag_activity!(activity)
                      rescue StandardError => e
                        Api::Middleware.logger.warn "Error rebgragging activity for team #{user.team}, user #{user}, #{user.athlete}, #{params['object_type']}=#{params['object_id']}: #{e}."
                      end
                    else
                      Api::Middleware.logger.info "Ignoring activity team #{user.team}, user #{user}, #{user.athlete}, #{params['object_type']}=#{params['object_id']}, #{params['updates']}."
                    end
                  end
                end
              when 'delete'
                User.connected_to_strava.where('athlete.athlete_id' => params['owner_id']).each do |user|
                  if !user.team.active?
                    Api::Middleware.logger.info "Team #{user.team} inactive, user #{user}, #{user.athlete}, #{params['object_type']}=#{params['object_id']}."
                  elsif user.team.subscription_expired?
                    Api::Middleware.logger.info "Team #{user.team} subscription expired, user #{user}, #{user.athlete}, #{params['object_type']}=#{params['object_id']}."
                  else
                    begin
                      activity = user.activities.where(strava_id: params['object_id']).first
                      if activity
                        Api::Middleware.logger.info "Deleting activity team #{user.team}, user #{user}, #{user.athlete}, #{params['object_type']}=#{params['object_id']}."
                        activity.unbrag!
                      else
                        Api::Middleware.logger.info "Ignoring activity team #{user.team}, user #{user}, #{user.athlete}, #{params['object_type']}=#{params['object_id']}."
                      end
                    rescue StandardError => e
                      Api::Middleware.logger.warn "Error deleting activity for team #{user.team}, user #{user}, #{user.athlete}, #{params['object_type']}=#{params['object_id']}: #{e}."
                    end
                  end
                end
              else
                Api::Middleware.logger.info "Ignoring aspect type '#{params['aspect_type']}', object_type=#{params['object_type']}, object_id=#{params['object_id']}, #{params['updates']}."
              end
            else
              Api::Middleware.logger.warn "Ignoring object type '#{params['object_type']}', aspect_type=#{params['aspect_type']}, object_id=#{params['object_id']}, #{params['updates']}."
            end
            status 200
            { ok: true }
          end
        end
      end
    end
  end
end
