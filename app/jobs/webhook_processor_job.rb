class WebhookProcessorJob < ApplicationJob
  queue_as :default

  # ========= entry point =========
  def perform(flow_token, raw_params, event_time_iso, project_token)
    time = Time.iso8601(event_time_iso)
    
    # Find flow by token and ensure it belongs to the correct project
    flow = Flow.joins(:project).find_by!(webhook_token: flow_token, projects: { secret_token: project_token })

    node_id = raw_params["node_id"]
    node_type = raw_params["node_type"].to_s.downcase # "start" / "checkpoint" / "end" / "error"

    point = flow.measurement_points
                .find_or_initialize_by(node_id: node_id)
    point.node_type ||= node_type
    point.save!

    # --- 2. find or create run ------------------------------
    run = find_or_create_run(node_type, flow, time, raw_params["run_id"])
    return unless run  # Return if no run was found/created

    # --- 3. create measurement log if it's a start or pending run ---
    if node_type == "start" || run.pending?
      MeasurementLog.create!(
        run: run,
        measurement_point: point,
        received_at: time,
        logs: raw_params["logs"].present? ? { value: raw_params["logs"] } : nil
      )

      check_alerts(point, run)

      # --- 4. update run state ---------------------------------
      case node_type
      when "stop"
        run.complete!(time)
      when "error"
        run.update!(error: true, status: :failed)
        AlertMailer.error_triggered_alert([run.flow.user.email], run, point).deliver_later
      end
    end
  end

  # ========= helpers =========
  def find_or_create_run(node_type, flow, time, run_uuid)
    if node_type == "start"
      # Check if a run with this UUID already exists for this flow
      existing_run = flow.runs.find_by(uuid: run_uuid)
      return nil if existing_run.present?

      Run.create!(
        uuid:       run_uuid.presence || SecureRandom.uuid,
        flow:       flow,
        started_at: time,
        status:     :pending,
        error:      false
      )
    elsif run_uuid.present?
      flow.runs.find_by(uuid: run_uuid) ||
        raise(ActiveRecord::RecordNotFound, "No run found with UUID: #{run_uuid}")
    else
      flow.runs.pending.order(started_at: :desc).first ||
        raise(ActiveRecord::RecordNotFound, "No open run found for #{node_type}")
    end
  end

  def check_alerts(point, run)
    Alert.where(flow: point.flow, alert_type: :error_triggered, active: true).find_each do |alert|
      AlertMailer.error_triggered_alert(alert.email_addresses.to_s.split(/,\s*/), run, point).deliver_later
    end
  end
end
