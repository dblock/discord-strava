module Api
  module Endpoints
    class TeamsEndpoint < Grape::API
      format :json
      helpers Api::Helpers::CursorHelpers
      helpers Api::Helpers::SortHelpers
      helpers Api::Helpers::PaginationParameters

      namespace :teams do
        desc 'Get a team.'
        params do
          requires :id, type: String, desc: 'Team ID.'
        end
        get ':id' do
          team = Team.where(_id: params[:id], api: true).first || error!('Not Found', 404)
          present team, with: Api::Presenters::TeamPresenter
        end

        desc 'Get all the teams.'
        params do
          optional :active, type: Boolean, desc: 'Return active teams only.'
          use :pagination
        end
        sort Team::SORT_ORDERS
        get do
          teams = Team.api
          teams = teams.active if params[:active]
          teams = paginate_and_sort_by_cursor(teams, default_sort_order: '-_id')
          present teams, with: Api::Presenters::TeamsPresenter
        end

        desc 'Create a team using an OAuth token.'
        params do
          requires :code, type: String
          requires :guild_id, type: String
          requires :permissions, type: Integer
        end
        post do
          oauth2_response = Discord::OAuth2.exchange_code(params[:code])

          team = Team.where(token: oauth2_response[:token]).first
          team ||= Team.where(guild_id: oauth2_response[:guild_id]).first

          if team
            team.ping_if_active!

            team.update_attributes!(oauth2_response.merge(
                                      permissions: params[:permissions]
                                    ))

            raise "Team \"#{team.guild_name}\" is already registered. You're all set." if team.active?

            team.update_attributes!(
              active: true
            )
          else
            team = Team.create!(oauth2_response.merge(
                                  permissions: params[:permissions]
                                ))
          end

          DiscordStrava::Service.instance.create!(team)
          present team, with: Api::Presenters::TeamPresenter
        end
      end
    end
  end
end
