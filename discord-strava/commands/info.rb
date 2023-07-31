module DiscordStrava
  module Commands
    class Info < Discord::Commands::Command
      include DiscordStrava::Loggable

      command 'strada' => 'info' do |command|
        logger.info "INFO: #{command}"
        [
          DiscordStrava::INFO,
          command.team.reload.subscribed? ? nil : command.team.trial_message
        ].compact.join("\n")
      end
    end
  end
end
