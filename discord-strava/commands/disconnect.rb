module DiscordStrava
  module Commands
    class Disconnect < Discord::Commands::Command
      include DiscordStrava::Commands::Mixins::Subscribe
      include DiscordStrava::Loggable

      subscribe_command 'strada' => 'disconnect' do |command|
        target_user_id = command.options.dig('disconnect', 'args', 'user', 'value')
        if target_user_id
          if command.user.guild_owner?
            target_user = command.team.users.where(user_id: target_user_id).first
            if target_user&.connected_to_strava?
              logger.info "DISCONNECT: #{command}, user=#{command.user}, #{target_user}"
              target_user.disconnect!
              "Strava account for user #{target_user.discord_mention} successfully disconnected."
            elsif target_user
              logger.info "DISCONNECT: #{command}, user=#{command.user}, #{target_user} - already disconnected"
              "Strava account for user #{target_user.discord_mention} is already disconnected."
            else
              logger.info "DISCONNECT: #{command}, user=#{command.user}, target=#{target_user_id} - not found"
              "I cannot find the user <@#{target_user_id}>, sorry."
            end
          else
            logger.info "DISCONNECT: #{command}, user=#{command.user}, target=#{target_user_id} - not admin"
            'Sorry, only a Discord admin can disconnect other users.'
          end
        else
          logger.info "DISCONNECT: #{command}, user=#{command.user}"
          command.user.disconnect!
        end
      end
    end
  end
end
