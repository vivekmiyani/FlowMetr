class User < ApplicationRecord
  devise :database_authenticatable, :recoverable, :rememberable, :validatable, :registerable, :confirmable
  
  # Associations
  has_many :projects, dependent: :destroy
  has_many :flows, dependent: :destroy
  has_many :runs, through: :flows
  has_many :measurement_logs, through: :runs

  # Callbacks
  after_create :create_default_project
  
  def admin?
    admin
  end
  
  private

  def create_default_project
    projects.create!(name: "Default", description: "The default project")
  end
  
  # Helper methods for plan limitations
  def monthly_measurement_count
    # Count measurements for the current month
    start_date = Time.current.beginning_of_month
    end_date = Time.current.end_of_month
    
    # Safely count measurements, handling cases where associations might not be loaded
    if runs.loaded?
      runs.flat_map { |run| run.measurement_logs.where(created_at: start_date..end_date) }.count
    else
      measurement_logs.where(created_at: start_date..end_date).count
    end
  rescue => e
    Rails.logger.error "Error counting monthly measurements: #{e.message}"
    0 # Return 0 if there's an error to prevent blocking access
  end
end
