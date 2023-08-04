require 'spec_helper'

RSpec.shared_context :discord_command, shared_context: :metadata do
  let(:team) { Fabricate(:team, created_at: 2.weeks.ago) }
  let(:user) { Fabricate(:user, team: team) }
  let(:args) { [] }
  let(:command_options) do
    result = []
    for arg in Array(args).reverse do
      if arg.is_a?(Hash)
        arg.each_pair do |k, v|
          result = [{
            name: k,
            value: v,
            options: result,
            type: 1
          }]
        end
      else
        result = [{
          name: arg,
          options: result,
          type: 1
        }]
      end
    end
    result
  end
  let(:params) do
    {
      id: 'id',
      type: Discord::Interactions::Type::APPLICATION_COMMAND,
      version: 1,
      token: 'token',
      application_id: '1135347799840522240',
      guild_id: team.guild_id,
      channel: {
        id: user.channel_id,
        type: 0
      },
      member: {
        user: {
          id: user.user_id,
          username: 'username'
        }
      },
      data: {
        id: '1135549211878903849',
        name: 'strada',
        options: command_options
      },
      channel_id: '1136112917264224338',
      locale: 'en-US'
    }
  end
  let(:command) { DiscordStrava::Commands::Command.new(params, nil) }
  let(:response) { Discord::Commands.invoke!(command) }
end
