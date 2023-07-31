# frozen_string_literal: true

require_relative 'request'

module Discord
  module Requests
    class Command < Request
      def name
        self[:data][:name]
      end

      def option_names
        self[:data][:options].map do |option|
          option[:name]
        end
      end

      def initialize(params, request)
        super params, request
      end

      def matches?(route, options = [])
        route == '*' || (route == name && option_names == Array(options))
      end

      def to_s
        [
          name, 
          option_names
        ].compact.flatten.join(' ')
      end
    end
  end
end