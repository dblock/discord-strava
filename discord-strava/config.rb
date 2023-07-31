module DiscordStrava
  module Config
    extend self

    attr_accessor :logger
    attr_accessor :view_paths

    def reset!
      self.logger = nil

      self.view_paths = [
        'views',
        'public',
        File.expand_path(File.join(__dir__, '../../public'))
      ]
    end

    reset!
  end

  class << self
    def configure
      block_given? ? yield(Config) : Config
    end

    def config
      Config
    end
  end
end