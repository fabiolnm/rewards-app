Sentry.init do |config|
  config.dsn = ENV["SENTRY_DSN"]
  config.environment = ENV.fetch("RAILS_ENV", "development")
  config.release = ENV["GIT_SHA"] || (Rails.env.local? ? `git rev-parse HEAD`.strip.presence : nil)
  config.breadcrumbs_logger = [ :active_support_logger, :http_logger ]
  config.traces_sample_rate = ENV.fetch("SENTRY_TRACES_SAMPLE_RATE", 0.1).to_f
  config.send_default_pii = false
end
