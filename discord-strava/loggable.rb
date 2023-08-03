# frozen_string_literal: true

module DiscordStrava
  module Loggable
    def self.included(base)
      base.send :include, InstanceMethods
      base.extend(ClassMethods)
    end

    module ClassMethods
      def logger
        @logger ||= DiscordStrava::Config.logger || begin
          $stdout.sync = true
          Logger.new($stdout)
        end
      end
    end

    module InstanceMethods
      def logger
        self.class.logger
      end
    end
  end
end
