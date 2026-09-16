$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..'))

require 'simplecov'
SimpleCov.start do
  add_filter '/spec/'
end

require 'fabrication'
require 'faker'
require 'hyperclient'
require 'webmock/rspec'

ENV['RACK_ENV'] = 'test'

require 'discord-strava'

Dir[File.join(File.dirname(__FILE__), 'support', '**/*.rb')].each do |file|
  require file
end
