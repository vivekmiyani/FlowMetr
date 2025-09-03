module ApplicationHelper
  include Heroicon::Engine.helpers

  def webhook_url_for(flow)
    raise ArgumentError, "Flow is nil" if flow.nil?
    raise ArgumentError, "Flow has no webhook_token" if flow.webhook_token.blank?

    Rails.application.routes.url_helpers.webhook_receiver_url(token: flow.webhook_token)
  end

  def dynamic_root_path
    user_signed_in? ? authenticated_root_path : unauthenticated_root_path
  end
end
