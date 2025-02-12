require 'spec_helper'

describe 'Teams', :js, type: :feature do
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
      allow(Discord::Bot.instance).to receive(:exchange_code).with('code').and_return(oauth_access)
      allow_any_instance_of(Team).to receive(:activated!)
      allow_any_instance_of(Team).to receive(:update_info!)
      expect {
        visit '/?code=code&guild_id=guild_id&permissions=2147502080'
        expect(page.find_by_id('messages')).to have_content 'Team successfully registered!'
      }.to change(Team, :count).by(1)
    end
  end
end
