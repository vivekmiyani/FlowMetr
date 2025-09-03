class ApplicationController < ActionController::Base
  include CanCan::ControllerAdditions
  
  protect_from_forgery with: :exception
  before_action :authenticate_user!
  before_action :set_locale
  before_action :set_secure_headers
  
  rescue_from CanCan::AccessDenied do |exception|
    redirect_to root_url, alert: exception.message
  end

  def set_secure_headers
    response.set_header("X-Frame-Options", "DENY")
  end

  def set_locale
    I18n.locale = current_user.try(:locale) || I18n.default_locale
  end

  # This method overrides Rails.application.default_url_options[:host] to add an absolute URL to meta tags, good for SEO
  def default_url_options
    { host: ENV["DOMAIN"] || "localhost:3000" }
  end
end
