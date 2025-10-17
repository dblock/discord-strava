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

      def options
        self[:data][:options].to_h do |option|
          name = option[:name]
          args = option[:options].to_h do |arg|
            [arg[:name], arg]
          end
          [name, option.merge(args: args)].compact
        end
      end

      def text
        [name, options.map { |key, value| [key, value[:value]] }].flatten.compact.join(' ')
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
