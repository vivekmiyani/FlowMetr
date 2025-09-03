class DashboardController < ApplicationController
  def show
    @flows_without_mps = current_user.flows
    if @flows_without_mps.count == 0
      redirect_to welcome_path
    end

    # Read range param from request, default to 7 days
    range_days = params[:range].present? ? params[:range].to_i : 7
    range = (range_days.days.ago.to_date..Date.tomorrow)

    @dashboard_stats = FlowDashboard.stats_for_range_for_user(current_user, range)

    @flows = @flows_without_mps.includes(:measurement_points)
    @flows_with_stats = FlowStatsForRange.call(flows: @flows, range: range)
    @recent_runs = Run.by_user(current_user).order(started_at: :desc).limit(10)

    # Create a hash with all dates in the range initialized to 0
    date_format = "%Y-%m-%d"
    all_dates = (range.first.to_date..range.last.to_date).each_with_object({}) do |date, hash|
      hash[date.strftime(date_format)] = 0
    end

    # Total runs per day
    @total_runs_per_day = all_dates.merge(
      Run.joins(:flow)
         .where(flows: { user_id: current_user.id })
         .where(started_at: range)
         .group("DATE(started_at)")
         .count
         .transform_keys { |date| date.strftime(date_format) }
    )

    # Successful runs per day
    @successful_runs_per_day = all_dates.merge(
      Run.joins(:flow)
         .where(flows: { user_id: current_user.id })
         .where(started_at: range, status: "successful")
         .group("DATE(started_at)")
         .count
         .transform_keys { |date| date.strftime(date_format) }
    )

    # Pending runs per day
    @pending_runs_per_day = all_dates.merge(
      Run.joins(:flow)
         .where(flows: { user_id: current_user.id })
         .where(started_at: range, status: "pending")
         .group("DATE(started_at)")
         .count
         .transform_keys { |date| date.strftime(date_format) }
    )

    # Failed runs per day
    @failed_runs_per_day = all_dates.merge(
      Run.joins(:flow)
         .where(flows: { user_id: current_user.id })
         .where(started_at: range, status: "failed")
         .group("DATE(started_at)")
         .count
         .transform_keys { |date| date.strftime(date_format) }
    )

    # Calculate success rate data
    @success_rate_data = @successful_runs_per_day.each_with_object({}) do |(day, successful), hash|
      total = @total_runs_per_day[day] || 0
      hash[day] = total > 0 ? ((successful.to_f / total) * 100).round(1) : 0
    end
  end
end
