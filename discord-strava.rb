ENV['RACK_ENV'] ||= 'development'

require 'bundler/setup'
Bundler.require :default, ENV.fetch('RACK_ENV', nil)

Dir[File.expand_path('config/initializers', __dir__) + '/**/*.rb'].sort.each do |file|
  require file
end

Mongoid.load! File.expand_path('config/mongoid.yml', __dir__), ENV.fetch('RACK_ENV', nil)

require 'discord-strava/version'
require 'discord-strava/config'
require 'discord-strava/loggable'
require 'discord-strava/lib/discord'
require 'discord-strava/service'
require 'discord-strava/info'
require 'discord-strava/models'
require 'discord-strava/api'
require 'discord-strava/app'
require 'discord-strava/server'
require 'discord-strava/commands'
