module Discord
  class Bot < Client
    def initialize
      super('Bot', ENV.fetch('DISCORD_SECRET_TOKEN', nil))
    end

    class << self
      def instance
        @instance ||= new
      end

      def reset!
        @instance = nil
      end
    end
  end
end
