# frozen_string_literal: true

module Discord
  module Commands
    class Unknown < Command
      command '*' do |command|
        {
            type: Discord::Interactions::Type::APPLICATION_COMMAND_AUTOCOMPLETE,
            data: {
                content: "Sorry, I don't understand this command: #{command.name}.",
                flags: Discord::Interactions::Messages::EPHEMERAL
            }
         }
      end
    end
  end
end