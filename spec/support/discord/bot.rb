RSpec.configure do |config|
  config.before do
    Discord::Bot.reset!
    ENV['DISCORD_CLIENT_SECRET'] = 'client_secret'
    ENV['DISCORD_CLIENT_ID'] = 'client_id'
    ENV['DISCORD_SECRET_TOKEN'] = 'secret_token'
  end
end
