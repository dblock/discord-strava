module DiscordStrava
  module Commands
    class Stats < Discord::Commands::Command
      include DiscordStrava::Commands::Mixins::Subscribe
      include DiscordStrava::Loggable

      subscribe_command 'strada' => 'stats' do |command|
        logger.info "STATS: #{command}"
        # channel_options = {}
        # channel_options.merge!(channel_id: data.channel) unless data.channel[0] == 'D'
        # client.web_client.chat_postMessage(
        #   command.team.stats(
        #     channel_options
        #   ).to_discord.merge(channel: data.channel, as_user: true)
        # )
        "TODO"
      end
    end
  end
end
