class MeasurementPoint < ApplicationRecord
  belongs_to :flow
  has_many :measurement_logs, dependent: :destroy

  validates :node_type, inclusion: { in: %w[start stop checkpoint error] }

  default_scope { order(:sequence) }

  def measurement_logs_for_run(run)
    measurement_logs.where(run_id: run.id)
  end
end
