module Api
  module Endpoints
    class DiscordEndpoint < Grape::API
      format :json

      namespace :discord do
        before do
          # https://gist.github.com/mattantonelli/d9c311abbf2400387480488e3853dd1f
          signature = request.headers['X-Signature-Ed25519']
          timestamp = request.headers['X-Signature-Timestamp']
          key = Ed25519::VerifyKey.new([ENV['DISCORD_PUBLIC_KEY']].pack('H*')).freeze
          key.verify([signature].pack('H*'), "#{timestamp}#{env[Grape::Env::API_REQUEST_INPUT]}")
        rescue Ed25519::VerifyError
          error! '401 Unauthorized', 401
        end

        desc 'Ping'
        params do
          requires :id, type: Integer
          requires :type, type: Integer, values: Discord::Interactions::Type.values
          requires :version, type: Integer
          requires :token, type: String
          given type: ->(type) { type == Discord::Interactions::Type::PING } do
            requires :application_id, type: Integer
            # requires :entitlements, type: Array
            requires :user, type: Hash do
              requires :id, type: Integer
              requires :username, type: String
              # requires :avatar, type: String
              # requires :avatar_decoration, type: String
              # requires :discriminator, type: String
              # requires :global_name, type: String
              # requires :public_flags, type: Integer
            end
          end
          given type: ->(type) { type == Discord::Interactions::Type::APPLICATION_COMMAND } do
            requires :locale, type: String
            # requires :app_permissions, type: Integer
            requires :application_id, type: Integer
            requires :channel_id, type: Integer
            requires :channel, type: Hash do
              requires :type, type: Integer
              requires :guild_id, type: Integer
              requires :name, type: String
              # requires :flags, type: Integer
              # requires :last_message_id, type: Integer
              # requires :nsfw, type: Boolean
              # requires :parent_id, type: Integer
              # requires :permissions, type: Integer
              # requires :position, type: Integer
              # requires :rate_limit_per_user, type: Integer
              # requires :topic, type: String
            end
            requires :data, type: Hash do
              requires :id, type: Integer
              requires :type, type: Integer
              requires :name, type: String
              requires :options, type: Array do
                requires :type, type: Integer
                requires :name, type: String
                requires :options, type: Array
              end
            end
            # requires ventitlement_sku_ids, type: Array
            # requires :entitlements, type: Array
            requires :guild_id, type: Integer
            requires :guild_locale, type: String
            requires :guild, type: Hash do
              # requires :id, type: Integer
              # requires :locale, type: String
              # requires vfeatures, type: Array
            end
            requires :member, type: Hash do
              requires :user, type: Hash do
                requires :id, type: Integer
                requires :username, type: String
                # requires :avatar, type: String
                # requires :avatar_decoration, type: String
                # requires :discriminator, type: String
                # requires :global_name, type: String
                # requires :public_flags, type: Integer
              end
            end
          end
        end
        post do
          case params[:type]
          when Discord::Interactions::Type::PING then
            Api::Middleware.logger.info "Discord ping: application_id=#{params[:application_id]}, user=#{params[:user][:username]} (#{params[:user][:id]})"
            {
              type: Discord::Interactions::Type::PING
            }
          when Discord::Interactions::Type::APPLICATION_COMMAND then
            command = DiscordStrava::Commands::Command.new(params, request)
            result = Discord::Commands::invoke!(command) 
            result =  {
              type: Discord::Interactions::Type::APPLICATION_COMMAND_AUTOCOMPLETE,
              data: {
                  content: result,
                  flags: Discord::Interactions::Messages::EPHEMERAL
              }
            } if result.is_a?(String)
            result || body(false)
          else
            Api::Middleware.logger.info "Unhandled interaction #{params[:type]}: #{params}"
          end
        end
      end
    end
  end
end
