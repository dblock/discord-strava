module Discord
  module Commands
    class << self
      def invoke!(command)
        result = child_command_classes.detect do |d|
          rc = d.invoke!(command)
          break rc if rc
        end
        result ||= Discord::Commands::Unknown.invoke!(command)
        result
      end

      private

      def command_classes
        Discord::Commands::Command.command_classes
      end

      def child_command_classes
        command_classes.reject do |k|
          k.name&.starts_with?('Discord::Commands::')
        end
      end
    end

    class Command
      class << self
        attr_accessor :command_classes

        def inherited(subclass)
          Discord::Commands::Command.command_classes ||= []
          Discord::Commands::Command.command_classes << subclass
        end

        def command(*values, &block)
          values.each do |value|
            if value.is_a?(Hash)
              value.each_pair do |k, v|
                routes[k] = { subcommands: v, block: block }
              end
            else
              routes[value] = { block: block }
            end
          end
        end

        def invoke!(command)
          finalize_routes!

          routes.each_pair do |route, options|
            next unless command.matches?(route, options[:subcommands])

            result = call_command(command, options[:block])
            return result if result
          end
          nil
        rescue DiscordStrava::Error => e
          e.message
        end

        def routes
          @routes ||= ActiveSupport::OrderedHash.new
        end

        private

        def call_command(command, block)
          if block
            block.call(command)
          elsif respond_to?(:call)
            send(:call, command)
          else
            raise NotImplementedError, command.name
          end
        end

        def finalize_routes!
          return if routes&.any?

          command command_name_from_class
        end

        def command_name_from_class
          name ? name.split(':').last.downcase : object_id.to_s
        end
      end
    end
  end
end
