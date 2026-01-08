module SentryContext
  extend ActiveSupport::Concern

  included do
    before_action :set_sentry_context
  end

  private

  def set_sentry_context
    Sentry.set_tags(request_id: request.request_id)

    # Placeholder for future authentication
    # Sentry.set_user(id: current_user.id) if current_user
  end
end
