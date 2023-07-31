require 'spec_helper'

describe 'Teams', js: true, type: :feature do
  before do
    ENV['DISCORD_APPLICATION_ID'] = 'client_id'
    ENV['DISCORD_SECRET_TOKEN'] = 'client_secret'
    ENV['SLACK_OAUTH_SCOPE'] = 'bot,commands,links:read,links:write'
  end
  after do
    ENV.delete 'DISCORD_APPLICATION_ID'
    ENV.delete 'DISCORD_SECRET_TOKEN'
    ENV.delete 'SLACK_OAUTH_SCOPE'
  end
  context 'oauth', vcr: { cassette_name: 'auth_test' } do
    it 'registers a team' do
      allow_any_instance_of(Team).to receive(:ping!).and_return(ok: true)
      expect(DiscordStrava::Service.instance).to receive(:start!)
      oauth_access = { 'bot' => { 'bot_access_token' => 'token' }, 'guild_id' => 'guild_id', 'team_name' => 'team_name' }
      allow_any_instance_of(Discord::Web::Client).to receive(:oauth_access).with(hash_including(code: 'code')).and_return(oauth_access)
      expect {
        visit '/?code=code'
        expect(page.find('#messages')).to have_content 'Team successfully registered!'
      }.to change(Team, :count).by(1)
    end
  end
  context 'homepage' do
    before do
      visit '/'
    end
    it 'displays index.html page' do
      expect(title).to eq('Strada: Strava integration with Discord')
    end
    it 'includes a link to add to discord with the client id' do
      expect(find("a[href='https://discord.com/oauth/authorize?scope=#{ENV.fetch('SLACK_OAUTH_SCOPE', nil)}&client_id=#{ENV.fetch('DISCORD_APPLICATION_ID', nil)}']"))
    end
  end
end
