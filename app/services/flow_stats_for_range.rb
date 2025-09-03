class FlowStatsForRange
  def self.call(flows:, range:)
    previous_range = (range.first - (range.last - range.first))...range.first

    flows.includes(:runs).map do |flow|
      scoped_runs = flow.runs.where(started_at: range)
      previous_runs = flow.runs.where(started_at: previous_range)

      total_runs = scoped_runs.count
      successful_runs = scoped_runs.successful.count
      failed_runs = scoped_runs.failed.count

      durations = scoped_runs.where.not(duration: nil).pluck(:duration)
      mean_duration = durations.any? ? (durations.sum.to_f / durations.size).round(2) : nil
      max_duration = durations.max&.round(2)

      previous_total = previous_runs.count
      percent_change =
        if previous_total.zero?
          total_runs.positive? ? 100.0 : 0.0
        else
          (((total_runs - previous_total) / previous_total.to_f) * 100).round(1)
        end

      {
        flow: flow,
        total_runs: total_runs,
        successful_runs: successful_runs,
        failed_runs: failed_runs,
        mean_duration: mean_duration,
        max_duration: max_duration,
        percent_change: percent_change
      }
    end
  end
end
