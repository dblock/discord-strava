require 'spec_helper'

describe DiscordStrava::Commands::Help do
  let(:app) { DiscordStrava::Server.new(team: team) }
  let(:client) { app.send(:client) }
  let(:message_hook) { DiscordRubyBot::Hooks::Message.new }
  context 'subscribed team' do
    let!(:team) { Fabricate(:team, subscribed: true) }
    it 'help' do
      expect(client).to receive(:say).with(channel: 'channel', text: DiscordStrava::Commands::Help::HELP)
      message_hook.call(client, Hashie::Mash.new(channel: 'channel', text: "#{DiscordRubyBot.config.user} help"))
    end
  end
  context 'non-subscribed team after trial' do
    let!(:team) { Fabricate(:team, created_at: 2.weeks.ago) }
    it 'help' do
      expect(client).to receive(:say).with(channel: 'channel', text: [
        DiscordStrava::Commands::Help::HELP,
        team.trial_message
      ].join("\n"))
      message_hook.call(client, Hashie::Mash.new(channel: 'channel', text: "#{DiscordRubyBot.config.user} help"))
    end
  end
  context 'non-subscribed team during trial' do
    let!(:team) { Fabricate(:team, created_at: 1.day.ago) }
    it 'help' do
      expect(client).to receive(:say).with(channel: 'channel', text: [
        DiscordStrava::Commands::Help::HELP,
        team.trial_message
      ].join("\n"))
      message_hook.call(client, Hashie::Mash.new(channel: 'channel', text: "#{DiscordRubyBot.config.user} help"))
    end
  end
end
