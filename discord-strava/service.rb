module DiscordStrava
  class Service
    include DiscordStrava::Loggable

    LOCALHOST = 'http://localhost:5000'.freeze

    def self.localhost?
      url == LOCALHOST
    end

    def self.url
      ENV.fetch('URL') { (ENV['RACK_ENV'] == 'development' ? LOCALHOST : 'https://strada.playplay.io') }
    end

    def self.start!
      Thread.new do
        Thread.current.abort_on_exception = true
        instance.start_from_database!
      end
    end

    def self.instance
      @instance ||= DiscordStrava::Service.new
    end

    def initialize
      @callbacks = Hash.new { |h, k| h[k] = [] }
      @intervals = Hash.new { |h, k| h[k] = [] }
    end

    def on(*types, &block)
      Array(types).each do |type|
        @callbacks[type.to_s] << block
      end
    end

    def once_and_every(*intervals, &block)
      Array(intervals).each do |interval|
        @intervals[_validate_interval(interval)] << [block, { run_on_start: true }]
      end
    end

    def every(*intervals, &block)
      Array(intervals).each do |interval|
        @intervals[_validate_interval(interval)] << [block, {}]
      end
    end

    def create!(team, options = {})
      run_callbacks :creating, team, nil, options
      start!(team)
      run_callbacks :created, team, nil, options
    end

    def start!(team)
      logger.info "Starting team #{team}."
      run_callbacks :starting, team
      run_callbacks :started, team
    rescue StandardError => e
      run_callbacks :error, team, e
      logger.error e
      NewRelic::Agent.notice_error(e)
    end

    def restart!(team)
      logger.info "Restarting team #{team}."
      run_callbacks :restarting, team
      run_callbacks :restarted, team
    rescue StandardError => e
      run_callbacks :error, team, e
      logger.error e
      NewRelic::Agent.notice_error(e)
    end

    def stop!(team)
      logger.info "Stopping team #{team}."
      run_callbacks :stopping, team
      run_callbacks :stopped, team
    rescue StandardError => e
      run_callbacks :error, team, e
      logger.error e
      NewRelic::Agent.notice_error(e)
    end

    def start_from_database!
      Team.active.each do |team|
        run_callbacks :booting, team
        start!(team)
        run_callbacks :booted, team
      end
      start_intervals!
    end

    def start_intervals!(&)
      ::Async::Reactor.run do |task|
        @intervals.each_pair do |period, calls_with_options|
          calls_with_options.each do |call_with_options|
            call, options = *call_with_options
            _every period, options do
              call.call
            end
          end
        end
        yield task if block_given?
      end
    end

    def deactivate!(team)
      run_callbacks :deactivating, team
      team.deactivate!
      run_callbacks :deactivated, team
    rescue StandardError => e
      run_callbacks :error, team, e
      logger.error "#{team.guild_name}: #{e.class}, #{e.message}, ignored."
      NewRelic::Agent.notice_error(e, custom_params: { team: team.to_s })
    end

    def self.reset!
      @instance = nil
    end

    private

    def _validate_interval(interval)
      case interval
      when :minute
        interval = 60
      when :hour
        interval = 60 * 60
      when :day
        interval = 60 * 60 * 24
      end
      raise "Invalid interval \"#{interval}\"." unless interval.is_a?(Integer) && interval.positive?

      interval
    end

    def _every(tt, options = {}, &)
      ::Async::Reactor.run do |task|
        loop do
          if options[:run_on_start]
            options = {}
            yield
          end
          task.sleep tt
          yield
        rescue StandardError => e
          logger.error e
          NewRelic::Agent.notice_error(e)
        end
      end
    end

    def run_callbacks(type, team = nil, error = nil, options = {})
      callbacks = @callbacks[type.to_s]
      return false unless callbacks

      callbacks.each do |c|
        c.call team, error, options
      end
      true
    rescue StandardError => e
      logger.error e
      NewRelic::Agent.notice_error(e)
      false
    end
  end
end
