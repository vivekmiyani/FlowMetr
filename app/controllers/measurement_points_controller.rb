class MeasurementPointsController < ApplicationController
  before_action :set_measurement_point, only: %i[ show edit update destroy ]

  # GET /measurement_points or /measurement_points.json
  def index
    @measurement_points = MeasurementPoint.all
  end

  # GET /measurement_points/1 or /measurement_points/1.json
  def show
  end

  # GET /measurement_points/new
  def new
    @measurement_point = MeasurementPoint.new
  end

  # GET /measurement_points/1/edit
  def edit
  end

  def create
    @flow = Flow.find(params[:flow_id])
    @measurement_point = @flow.measurement_points.build(measurement_point_params)
  
    if @measurement_point.save
      redirect_to settings_flow_path(@flow), notice: "Measurement point created successfully."
    else
      redirect_to @flow, alert: "Failed to create measurement point."
    end
  end

  # PATCH/PUT /measurement_points/1 or /measurement_points/1.json
  def update
    respond_to do |format|
      if @measurement_point.update(measurement_point_params)
        format.html { redirect_to @measurement_point, notice: "Measurement point was successfully updated." }
        format.json { render :show, status: :ok, location: @measurement_point }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @measurement_point.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /measurement_points/1 or /measurement_points/1.json
  def destroy
    flow = @measurement_point.flow

    if @measurement_point.node_type == "start"
      redirect_to settings_flow_path(flow), alert: "Cannot delete the start measurement point."
      return
    end

    @measurement_point.destroy!

    respond_to do |format|
      format.html { redirect_to settings_flow_path(flow), status: :see_other, notice: "Measurement point was successfully deleted." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_measurement_point
      @measurement_point = MeasurementPoint.find(params.expect(:id))
    end

    def measurement_point_params
      params.require(:measurement_point).permit(:name, :node_type)
    end
end
