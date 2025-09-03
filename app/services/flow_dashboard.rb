# app/services/flow_dashboard.rb
class FlowDashboard
  def self.stats_for_range_for_user(user, range)
    runs = Run
      .joins(:flow)
      .where(flows: { user_id: user.id })
      .where(started_at: range)

    total_runs = runs.count
    successful = runs.where(status: "successful").count
    failed = runs.where(status: "failed").count
    pending = runs.where(status: "pending").count

    {
      total_runs: total_runs,
      successful: successful,
      failed: failed,
      pending: pending
    }
  end

  def self.stats_for_range_for_flow(flow, range)
    runs = Run
      .joins(:flow)
      .where(flows: { flow: flow.id })
      .where(started_at: range)

    total_runs = runs.count
    successful = runs.where(status: "successful").count
    failed = runs.where(status: "failed").count
    pending = runs.where(status: "pending").count

    {
      total_runs: total_runs,
      successful: successful,
      failed: failed,
      pending: pending
    }
  end

  def self.stats_for_range_for_project(project, range)
    runs = Run
      .joins(:flow)
      .where(flows: { project_id: project.id })
      .where(started_at: range)
    {
      total_runs: runs.count,
      successful: runs.where(status: "successful").count,
      failed: runs.where(status: "failed").count,
      pending: runs.where(status: "pending").count
    }
  end
end
