module DiscordStrava
  module Commands
    class Command < Discord::Requests::Command
      include DiscordStrava::Loggable

      def initialize(params, request)
        super params, request
      end

      def team
        @team ||= Team.where(guild_id: self[:guild_id]).first || raise("Missing team with guild_id=#{self[:guild_id]}.")
      end

      def user
        @user ||= team.users.where(
          user_id: user_id,
          channel_id: channel_id
        ).first || User.create!(
          team: team,
          user_id: user_id,
          channel_id: channel_id,
          user_name: username
        )
      end

      def to_s
        [
          "command=#{super}",
          "team=#{team}"
        ].compact.flatten.join(', ')
      end

      def channel_id
        self[:channel][:id]
      end

      def user_id
        user_info[:id]
      end

      private

      def user_info
        if self[:channel][:type] == 0 && key?(:member) # message type 0, text
          self[:member][:user] || {}
        elsif self[:channel][:type] == 1 # message type 1, DM
          self[:user] || {}
        else
          raise NotImplementedError
        end
      end

      def username
        user_info[:username]
      end
    end
  end
end
