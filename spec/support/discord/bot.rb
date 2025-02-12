RSpec.configure do |config|
  config.before do
    Discord::Bot.reset!
    ENV['DISCORD_CLIENT_SECRET'] = 'token'
    ENV['DISCORD_CLIENT_ID'] = 'client_id'
  end
end
