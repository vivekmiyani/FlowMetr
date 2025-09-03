# app/helpers/dashboard_helper.rb
module DashboardHelper
    def dashboard_stats
        {
        total_flows: Flow.count,
        successful: Flow.select(&:successful_run?).count,
        pending: Flow.select(&:pending_run?).count,
        failed: Flow.select(&:failed_run?).count
        }
    end
end
  