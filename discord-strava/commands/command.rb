module DiscordStrava
  module Commands
    class Command < Discord::Requests::Command
      include DiscordStrava::Loggable
      
      def initialize(params, request)
        super params, request
      end

      def team
        @team ||= begin
          Team.where(guild_id: self[:guild_id]).first || raise("Missing team with guild_id=#{self[:guild_id]}.")
        end
      end

      def user
        @user ||= begin
          team.users.where(
            user_id: self[:member][:user][:id],
            channel_id: self[:channel][:id]
          ).first || User.create!(
            team: team, 
            user_id: self[:member][:user][:id], 
            channel_id: self[:channel][:id],
            user_name: self[:member][:user][:username]
          )
        end
      end

      def to_s
        [
          "command=#{super}",
          "team=#{team}"
        ].compact.flatten.join(', ')
      end
    end
  end
end