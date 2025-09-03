class Public::ProjectsController < ApplicationController
  layout "public"
  skip_before_action :authenticate_user!
  after_action :allow_iframe

  def show
    @project = Project.includes(:flows).find_by!(public_token: params[:public_token])

    # Same dashboard stats as ProjectsController
    range_days = (params[:range] || 7).to_i
    range = (range_days.days.ago.to_date..Date.tomorrow)

    @dashboard_stats = FlowDashboard.stats_for_range_for_project(@project, range)

    @flows_with_stats = FlowStatsForRange.call(flows: @project.flows, range: range)
    
    @recent_runs = Run
      .joins(:flow)
      .where(flows: { project_id: @project.id })
      .order(started_at: :desc)
      .limit(10)

    raw_runs = Run
      .joins(:flow)
      .where(flows: { project_id: @project.id })
      .where(started_at: range)
      .group_by_day(:started_at, range: range, time_zone: Time.zone.name)
      .count

    @total_runs_per_day = range.each_with_object({}) do |day, hash|
      hash[day.to_s] = raw_runs[day] || 0
    end

    date_format = "%Y-%m-%d"
    all_dates = (range.first.to_date..range.last.to_date).each_with_object({}) do |date, hash|
      hash[date.strftime(date_format)] = 0
    end

    @successful_runs_per_day = all_dates.merge(
      Run.joins(:flow)
         .where(flows: { project_id: @project.id })
         .where(started_at: range, status: "successful")
         .group("DATE(started_at)")
         .count
         .transform_keys { |date| date.strftime(date_format) }
    )

    @pending_runs_per_day = all_dates.merge(
      Run.joins(:flow)
         .where(flows: { project_id: @project.id })
         .where(started_at: range, status: "pending")
         .group("DATE(started_at)")
         .count
         .transform_keys { |date| date.strftime(date_format) }
    )

    @failed_runs_per_day = all_dates.merge(
      Run.joins(:flow)
         .where(flows: { project_id: @project.id })
         .where(started_at: range, status: "failed")
         .group("DATE(started_at)")
         .count
         .transform_keys { |date| date.strftime(date_format) }
    )

    success_runs = Run
      .joins(:flow)
      .where(flows: { project_id: @project.id })
      .where(started_at: range, status: "successful")
      .group_by_day(:started_at, range: range, time_zone: Time.zone.name)
      .count

    @success_rate_data = range.each_with_object({}) do |day, hash|
      total = raw_runs[day] || 0
      success = success_runs[day] || 0
      hash[day.to_s] = total > 0 ? ((success.to_f / total) * 100).round(1) : 0
    end
  end

  private

  def allow_iframe
    response.headers.delete("X-Frame-Options")
    response.headers["Content-Security-Policy"] = "frame-ancestors *" 
  end
end
