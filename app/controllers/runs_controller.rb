class RunsController < ApplicationController
  before_action :authenticate_user!

  def index
    if params[:flow_id]
      @flow = current_user.flows.find(params[:flow_id])
      @runs = @flow.runs.order(started_at: :desc)
    else
      @runs = Run.joins(:flow)
                 .where(flows: { user_id: current_user.id })
                 .order(started_at: :desc)
    end
  end

  def show
    @run = Run.joins(:flow)
              .where(flows: { user_id: current_user.id })
              .find(params[:id])

    @measurement_points = @run.flow
      .measurement_points
      .left_outer_joins(:measurement_logs)
      .where(
        "measurement_points.created_at <= :run_ts
         OR measurement_logs.run_id = :run_id",
        run_ts: @run.created_at,
        run_id: @run.id
      )
      .distinct
      .includes(:measurement_logs)

    # Logs grouped per point for quick access in the view
    @logs_by_point = @measurement_points.each_with_object({}) do |mp, hash|
      hash[mp.id] = mp.measurement_logs.select { |log| log.run_id == @run.id }
    end

    # Sort by type first, then sequence / timestamp
    @measurement_points = @measurement_points.sort_by do |mp|
      type_priority =
        case mp.node_type
        when "start"      then 0
        when "checkpoint" then 1
        when "stop"       then 2
        when "error"      then 3
        else                    4
        end

      secondary =
        if mp.node_type == "start"
          mp.sequence
        else
          first_log = @logs_by_point[mp.id].min_by(&:received_at)
          first_log&.received_at || Time.current + 100.years
        end

      [type_priority, secondary, mp.sequence]
    end
  end
end