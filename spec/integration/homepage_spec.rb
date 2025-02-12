require 'spec_helper'

describe 'Homepage', :js, type: :feature do
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

  context 'homepage' do
    before do
      visit '/'
    end

    it 'displays index.html page' do
      expect(title).to eq('Strada: Strava integration with Discord')
    end

    it 'includes a link to add to discord with the client id' do
      url = "https://discord.com/api/oauth2/authorize?scope=identify+bot&client_id=#{ENV.fetch('DISCORD_CLIENT_ID', nil)}&permissions=2147502080&redirect_uri=#{ENV.fetch('URL', nil)}&response_type=code"
      expect(find("a[href='#{url}']"))
    end
  end
end
