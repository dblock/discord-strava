module DiscordStrava
  module Commands
    class Help < Discord::Commands::Command
      include DiscordStrava::Loggable

      HELP = <<~EOS.freeze
        ```
        I am Strada, your friendly bot powered by Strava.

        Use /strada [command] to get started.

        Setup
        ------------
        connect                          - connect your Strava account
        disconnect                       - disconnect your Strava account
        leaderboard count|distance|...   - leaderboard by count, distance, etc.
        stats                            - stats in current channel for the past 30 days

        Settings
        ------------
        set units imperial|metric|both   - use imperial vs. metric units, or display both
        set fields all|none|...          - display all, none or certain activity fields
        set maps off|full|thumb          - change the way maps are displayed
        set sync true|false              - sync activities (default is true)
        set private true|false           - sync private (only you) activities (default is false)
        set followers true|false         - sync followers only activities (default is true)

        General
        ------------
        help                             - get this helpful message
        subscription                     - show subscription info, update credit-card
        unsubscribe                      - turn off subscription auto-renew
        resubscribe                      - turn on subscription auto-renew
        info                             - bot info, contact, feature requests
        ```
      EOS

      command 'strada' => 'help' do |command|
        logger.info "HELP: #{command}"
        [
          HELP,
          command.team.reload.subscribed? ? nil : command.team.trial_message
        ].compact.join("\n")
      end
    end
  end
end
