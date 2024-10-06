module Brag
  def with_strava_error_handler(&)
    yield
  rescue Strava::Errors::Fault => e
    case e.message
    when 'Rate Limit Exceeded'
      logger.warn 'Strava API rate limit exceeded.'
      raise e
    else
      backtrace = e.backtrace.join("\n")
      logger.warn "Error in team #{team}, #{self}, #{e.message}, #{backtrace}."
    end
  rescue Faraday::Error => e
    backtrace = e.backtrace.join("\n")
    logger.warn "Error in team #{team}, #{self}, #{e.message}, #{e.response[:body]}, #{backtrace}."
    NewRelic::Agent.notice_error(e, custom_params: { team: team.to_s, user: to_s })
  rescue StandardError => e
    backtrace = e.backtrace.join("\n")
    logger.warn "Error in team #{team}, #{self}, #{e.message}, #{backtrace}."
    NewRelic::Agent.notice_error(e, custom_params: { team: team.to_s, user: to_s })
  end

  def sync_and_brag!
    with_lock do
      with_strava_error_handler do
        sync_new_strava_activities!
        brag!
      end
    end
  end
end
