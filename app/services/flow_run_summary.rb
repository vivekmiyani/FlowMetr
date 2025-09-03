class FlowRunSummary
  Run = Struct.new(:run_id, :flow, :started_at, :ended_at, :duration, :status)

  def self.recent(limit: 20)
    # Get logs from the past 7 days (including today)
    recent_logs = MeasurementLog.where.not(run_id: nil)
                     .where('received_at >= ?', 7.days.ago)
                     .order(received_at: :desc)

    grouped = recent_logs.group_by(&:run_id).first(limit)
    runs = []

    grouped.each do |run_id, logs|
      flow = logs.first.measurement_point.flow

      start_log = logs.find { |l| l.measurement_point.node_type == "start" }
      stop_log   = logs.find { |l| l.measurement_point.node_type == "stop" }
      error_log = logs.find { |l| l.measurement_point.node_type == "error" }

      started_at = start_log&.received_at
      ended_at   = end_log&.received_at
      duration   = (ended_at - started_at) if started_at && ended_at

      status = if error_log
          :failed
      elsif started_at && ended_at
          :success
      elsif started_at
          :pending
      else
          :unknown
      end

      runs << Run.new(run_id, flow, started_at, ended_at, duration, status)
    end

    runs
  end
end
