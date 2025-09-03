class Flow < ApplicationRecord
  belongs_to :user
  belongs_to :project, optional: true
  has_many :measurement_points, dependent: :destroy
  has_many :runs, dependent: :destroy

  has_one :start_point, -> { where(node_type: 'start') }, class_name: 'MeasurementPoint'
  has_one :end_point, -> { where(node_type: 'stop') }, class_name: 'MeasurementPoint'
  has_many :checkpoints, -> { where(node_type: 'checkpoint') }, class_name: 'MeasurementPoint'
  has_many :error_points, -> { where(node_type: 'error') }, class_name: 'MeasurementPoint'

  validates :url, format: URI::DEFAULT_PARSER.make_regexp(%w[http https]), allow_blank: true
  
  before_create :generate_webhook_token

  def generate_webhook_token
    self.webhook_token = SecureRandom.uuid
  end

  def webhook_url
    return unless webhook_token.present? && project.present?
    "#{ENV['HOST_URL']}/webhooks/receive?token=#{webhook_token}&project_token=#{project.secret_token}"
  end

  def latest_duration
    runs.order(started_at: :desc).where.not(duration: nil).limit(1).pluck(:duration).first
  end

  def successful_run?
    runs.successful.exists?
  end

  def pending_run?
    runs.pending.exists?
  end

  def failed_run?
    runs.failed.exists?
  end

  def last_run_checkpoint_durations
    run = runs.order(started_at: :desc).includes(:checkpoints).first
    return [] unless run

    checkpoints = run.checkpoints.includes(:measurement_point).sort_by(&:received_at)

    checkpoints.each_cons(2).map do |a, b|
      [
        a.measurement_point.name,
        b.measurement_point.name,
        (b.received_at - a.received_at)
      ]
    end
  end
end
