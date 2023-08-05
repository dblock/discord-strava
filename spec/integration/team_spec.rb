require 'spec_helper'

describe 'Teams', js: true, type: :feature do
  before do
    ENV['DISCORD_CLIENT_ID'] = 'client_id'
    ENV['DISCORD_CLIENT_SECRET'] = 'secret'
    ENV['URL'] = 'https://localhost:5000'
  end
  after do
    ENV.delete 'DISCORD_CLIENT_ID'
    ENV.delete 'DISCORD_CLIENT_SECRET'
    ENV.delete 'URL'
  end
  context 'oauth' do
    it 'registers a team' do
      allow_any_instance_of(Team).to receive(:ping!).and_return(ok: true)
      expect(DiscordStrava::Service.instance).to receive(:start!)
      oauth_access = { 'token' => 'token', 'guild_id' => 'guild_id' }
      allow(Discord::OAuth2).to receive(:exchange_code).with('code').and_return(oauth_access)
      allow_any_instance_of(Team).to receive(:activated!)
      expect {
        visit '/?code=code&guild_id=guild_id&permissions=2147502080'
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
      url = "https://discord.com/api/oauth2/authorize?scope=bot&client_id=#{ENV.fetch('DISCORD_CLIENT_ID', nil)}&permissions=2147502080&redirect_uri=#{ENV.fetch('URL', nil)}&response_type=code"
      expect(find("a[href='#{url}']"))
    end
  end
end
