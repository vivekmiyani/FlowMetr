class Users::RegistrationsController < Devise::RegistrationsController
  invisible_captcha only: [:create], honeypot: :subtitle, timestamp_threshold: 4

  def after_sign_up_path_for(resource)
    # Redirect to dashboard after sign up
    dashboard_path
  end
  
  def create
    super do |user|
      next unless user.persisted?

      Rails.logger.info "[User Registration] Starting plan assignment for user: #{user.id}"

      selected_plan_name = params[:plan].presence&.capitalize || "Pro"
      Rails.logger.info "[User Registration] Selected plan name: #{selected_plan_name}"

      selected_plan = Plan.find_by(name: selected_plan_name)
      Rails.logger.info "[User Registration] Found plan: #{selected_plan.inspect}"

      if selected_plan_name == "Pro"
        user.update!(plan: selected_plan, trial_ends_at: 14.days.from_now)
      elsif selected_plan
        user.update!(plan: selected_plan)
      else
        Rails.logger.warn "[User Registration] Plan not found for: #{selected_plan_name}, fallback to Free"
        free_plan = Plan.find_by(name: "Free")
        user.update!(plan: free_plan)
      end

      Rails.logger.info "[User Registration] Final user plan: #{user.plan.inspect}"
    end
  end
end
