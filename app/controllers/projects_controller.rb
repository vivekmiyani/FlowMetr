class ProjectsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_project, only: [:show, :edit, :update, :destroy, :generate_public_token, :regenerate_public_token, :regenerate_secret_token, :disable_public_token]

  def index
    @projects = current_user.projects.includes(:flows)
  end

  def show
    @recent_runs = Run
      .joins(:flow)
      .where(flows: { project_id: @project.id })
      .order(started_at: :desc)
      .limit(10)

    range_days = (params[:range] || 7).to_i
    range = (range_days.days.ago.to_date..Date.tomorrow)

    @flows_with_stats = FlowStatsForRange.call(flows: @project.flows, range: range)

    @dashboard_stats = FlowDashboard.stats_for_range_for_project(@project, range)

    date_format = "%Y-%m-%d"
    all_dates = (range.first.to_date..range.last.to_date).each_with_object({}) do |date, hash|
      hash[date.strftime(date_format)] = 0
    end

    @total_runs_per_day = all_dates.merge(
      Run.joins(:flow)
         .where(flows: { project_id: @project.id })
         .where(started_at: range)
         .group("DATE(started_at)")
         .count
         .transform_keys { |date| date.strftime(date_format) }
    )

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

    @success_rate_data = @successful_runs_per_day.each_with_object({}) do |(day, successful), hash|
      total = @total_runs_per_day[day] || 0
      hash[day] = total > 0 ? ((successful.to_f / total) * 100).round(1) : 0
    end

    previous_range = (range_days * 2).days.ago.to_date...range_days.days.ago.to_date
  end

  def new
    @project = current_user.projects.build
  end

  def create
    @project = current_user.projects.build(project_params)
    
    if @project.save
      redirect_to @project, notice: "Project created successfully."
    else
      flash.now[:alert] = @project.errors.full_messages.to_sentence
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @project.update(project_params)
      redirect_to @project, notice: "Project updated."
    else
      render :edit
    end
  end

  def destroy
    @project = current_user.projects.find(params[:id])
    @project.destroy
    redirect_to projects_path, notice: "Project was successfully deleted."
  end

  def generate_public_token
    @project.generate_public_token
    @project.save!
    redirect_to edit_project_path(@project), notice: 'Public link generated.'
  end

  def regenerate_public_token
    @project.regenerate_public_token!
    redirect_to edit_project_path(@project), notice: 'Public link regenerated.'
  end

  def regenerate_secret_token
    @project.regenerate_secret_token!
    redirect_to edit_project_path(@project), notice: 'Secret token has been regenerated. Update your webhook URLs with the new token.'
  end

  def disable_public_token
    @project.update!(public_token: nil)
    redirect_to edit_project_path(@project), notice: 'Public link disabled.'
  end

  private

  def set_project
    @project = current_user.projects.find(params[:id])
  end

  def project_params
    params.require(:project).permit(:name, :description)
  end
end
