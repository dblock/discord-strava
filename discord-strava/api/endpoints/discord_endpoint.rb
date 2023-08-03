module Api
  module Endpoints
    class DiscordEndpoint < Grape::API
      format :json

      namespace :discord do
        before do
          # https://gist.github.com/mattantonelli/d9c311abbf2400387480488e3853dd1f
          signature = request.headers['X-Signature-Ed25519'] || error!('Missing X-Signature-Ed25519', 401)
          timestamp = request.headers['X-Signature-Timestamp'] || error!('Missing X-Signature-Timestamp', 401)
          discord_public_key = ENV.fetch('DISCORD_PUBLIC_KEY') { error!('Missing DISCORD_PUBLIC_KEY', 401) }
          Discord::Interactions::Signature.verify!(discord_public_key, signature, timestamp, env[Grape::Env::API_REQUEST_INPUT])
        rescue Ed25519::VerifyError
          error! '401 Unauthorized', 401
        end

        desc 'Discord event handler.'
        params do
          requires :id, type: String
          requires :type, type: Integer, values: Discord::Interactions::Type.values
          requires :version, type: Integer
          requires :token, type: String
          given type: ->(type) { type == Discord::Interactions::Type::PING } do
            requires :application_id, type: String
            # requires :entitlements, type: Array
            # requires :user, type: Hash do
            # requires :id, type: String
            # requires :username, type: String
            # requires :avatar, type: String
            # requires :avatar_decoration, type: String
            # requires :discriminator, type: String
            # requires :global_name, type: String
            # requires :public_flags, type: Integer
            # end
          end
          given type: ->(type) { type == Discord::Interactions::Type::APPLICATION_COMMAND } do
            requires :locale, type: String
            # requires :app_permissions, type: Integer
            requires :application_id, type: String
            requires :channel_id, type: String
            requires :channel, type: Hash do
              requires :id, type: String
              requires :type, type: Integer
              # requires :guild_id, type: String
              # requires :name, type: String
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
              requires :id, type: String
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
            optional :guild_id, type: String
            optional :guild_locale, type: String
            optional :guild, type: Hash do
              # requires :id, type: String
              # requires :locale, type: String
              # requires vfeatures, type: Array
            end
            optional :user, type: Hash do
              optional :id, type: String
              optional :username, type: String
              # requires :avatar, type: String
              # requires :avatar_decoration, type: String
              # requires :discriminator, type: String
              # requires :global_name, type: String
              # requires :public_flags, type: Integer
            end
            optional :member, type: Hash do
              requires :user, type: Hash do
                requires :id, type: String
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
          when Discord::Interactions::Type::PING
            Api::Middleware.logger.info "Discord ping: application_id=#{params[:application_id]})"
            {
              type: Discord::Interactions::Type::PING
            }
          when Discord::Interactions::Type::APPLICATION_COMMAND
            case params[:channel][:type]
            when Discord::Interactions::Channels::GUILD_TEXT
              command = DiscordStrava::Commands::Command.new(params, request)
              data = Discord::Commands.invoke!(command)
              data = { content: data } if data.is_a?(String)
              result = {
                type: Discord::Interactions::Type::APPLICATION_COMMAND_AUTOCOMPLETE,
                data: data.merge(flags: Discord::Interactions::Messages::EPHEMERAL)
              }
              result || body(false)
            else
              {
                type: Discord::Interactions::Type::APPLICATION_COMMAND_AUTOCOMPLETE,
                data: {
                  content: 'Strada works best in a regular channnel.',
                  flags: Discord::Interactions::Messages::EPHEMERAL
                }
              }
            end
          else
            Api::Middleware.logger.info "Unhandled interaction #{params[:type]}: #{params}"
            error!('Unhandled Interaction', 400)
          end
        end
      end
    end
  end
end
