$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..'))

require 'fabrication'
require 'faker'
require 'hyperclient'
require 'webmock/rspec'

ENV['RACK_ENV'] = 'test'

require 'discord-strava'

Dir[File.join(File.dirname(__FILE__), 'support', '**/*.rb')].sort.each do |file|
  require file
end
