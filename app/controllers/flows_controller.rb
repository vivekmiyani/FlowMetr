class FlowsController < ApplicationController
  before_action :set_flow, only: %i[ show edit update destroy ]

  # GET /flows or /flows.json
  def index
    @flows = current_user.flows
  end

  # GET /flows/1 or /flows/1.json
  def show
    @flow = current_user.flows.find(params[:id])
    @measurement_points = @flow.measurement_points.sort_by do |mp|
      sort_priority =
        case mp.node_type
        when "start" then 0
        when "checkpoint" then 1
        when "stop" then 2
        when "error" then 3
        else 4
        end
    
      [sort_priority, mp.created_at]
    end
    @runs = @flow.runs

    range_days = (params[:range] || 7).to_i
    range = (range_days.days.ago.to_date..Date.tomorrow)
    scoped_runs = @runs.where(started_at: range)
    
    # Initialize dashboard statistics
    @dashboard_stats = {
      total_runs: scoped_runs.count,
      successful: scoped_runs.successful.count,
      pending: scoped_runs.pending.count,
      failed: scoped_runs.failed.count
    }

    # Group by day in the selected range, ensuring all dates in the range are included
    date_format = "%Y-%m-%d"
    
    # Create a hash with all dates in the range initialized to 0
    all_dates = (range.first.to_date..range.last.to_date).each_with_object({}) do |date, hash|
      hash[date.strftime(date_format)] = 0
    end
    
    # Total runs per day
    @total_runs_per_day = all_dates.merge(
      @runs.where(started_at: range)
           .group("DATE(started_at)")
           .count
           .transform_keys { |date| date.strftime(date_format) }
    )

    # Successful runs per day
    @successful_runs_per_day = all_dates.merge(
      @runs.where(started_at: range).successful
           .group("DATE(started_at)")
           .count
           .transform_keys { |date| date.strftime(date_format) }
    )
    
    # Pending runs per day
    @pending_runs_per_day = all_dates.merge(
      @runs.where(started_at: range).pending
           .group("DATE(started_at)")
           .count
           .transform_keys { |date| date.strftime(date_format) }
    )
    
    # Failed runs per day
    @failed_runs_per_day = all_dates.merge(
      @runs.where(started_at: range).failed
           .group("DATE(started_at)")
           .count
           .transform_keys { |date| date.strftime(date_format) }
    )

    # Calculate success rate data
    @success_rate_data = @successful_runs_per_day.each_with_object({}) do |(day, successful), hash|
      total = @total_runs_per_day[day] || 0
      hash[day] = total > 0 ? (successful.to_f / total * 100).round(2) : 0
    end
    
    @recent_runs = @runs.order(started_at: :desc).limit(10)

    # Duration per run in the last 7 days
    duration_runs = @runs.where.not(started_at: nil, ended_at: nil)
    .where(started_at: range)

    @duration_data = duration_runs.map do |run|
      [
        run.started_at.strftime(date_format),
        run.duration ? run.duration.round(2) : 0
      ]
    end.group_by(&:first)
       .transform_values { |arr| arr.map(&:last).sum / arr.size.to_f }    
  end

  def settings
    @flow = current_user.flows.find(params[:id])
    @measurement_points = @flow.measurement_points.sort_by do |mp|
      sort_priority =
        case mp.node_type
        when "start" then 0
        when "checkpoint" then 1
        when "stop" then 2
        when "error" then 3
        else 4
        end
    
      [sort_priority, mp.created_at]
    end
  end
  

  # GET /flows/new
  def new
    @flow = current_user.flows.build
    @projects = current_user.projects
  end

  # GET /flows/1/edit
  def edit
    @flow = current_user.flows.find(params[:id])
    @projects = current_user.projects
  end

  # POST /flows or /flows.json
  def create
    @flow = current_user.flows.build(flow_params)

    respond_to do |format|
      if @flow.save
        format.html { 
          redirect_to @flow, notice: "Flow was successfully created.", flash: { created_flow: true }
        }
        format.json { render :show, status: :created, location: @flow }
      else
        format.html { 
          @projects = current_user.projects
          render :new, status: :unprocessable_entity 
        }
        format.json { render json: @flow.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /flows/1 or /flows/1.json
  def update
    respond_to do |format|
      if @flow.update(flow_params)
        format.html { redirect_to @flow, notice: "Flow was successfully updated." }
        format.json { render :show, status: :ok, location: @flow }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @flow.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /flows/1 or /flows/1.json
  def destroy
    @flow = current_user.flows.find(params[:id])
    @flow.destroy

    respond_to do |format|
      format.html { redirect_to flows_path, status: :see_other, notice: "Flow was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  def download_template
    @flow = current_user.flows.find(params[:id])
    template_name = params[:template] # e.g., "zapier", "make"

    template_path = Rails.root.join("lib", "templates", "#{template_name}.json.erb")
    unless File.exist?(template_path)
      redirect_to @flow, alert: "Template not found"
      return
    end

    # render with Rails variables
    rendered = ERB.new(File.read(template_path)).result_with_hash(flow: @flow)

    send_data rendered,
              filename: "#{template_name}_template_#{@flow.id}.json",
              type: "application/json"
  end


  private
    # Use callbacks to share common setup or constraints between actions.
    def set_flow
      @flow = current_user.flows.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def flow_params
      params.expect(flow: [ :name, :url, :description, :user_id, :project_id ])
    end
end
