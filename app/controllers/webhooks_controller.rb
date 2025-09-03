class WebhooksController < ApplicationController
  skip_forgery_protection only: :receive
  skip_before_action :verify_authenticity_token, only: [:receive]
  skip_before_action :authenticate_user!, only: [:receive]
  
  def receive
    event_time = Time.current.iso8601
    flow_token = params[:token]
    project_token = params[:project_token]

    # Find flow by token and ensure it belongs to the correct project
    flow = Flow.joins(:project).find_by(webhook_token: flow_token)
    
    if flow.nil? || flow.project.secret_token != project_token
      Rails.logger.warn "Invalid webhook attempt - Flow: #{flow_token}, Project Token: #{project_token}"
      return render json: { error: "Invalid or missing token" }, status: :unauthorized
    end

    WebhookProcessorJob.perform_later(
      flow_token,
      request.query_parameters,
      event_time,
      project_token
    )
    render json: { status: "accepted" }, status: :accepted
  end
end
