class Run < ApplicationRecord
  belongs_to :flow
  has_many :measurement_logs, dependent: :destroy

  enum :status, { pending: "pending", successful: "successful", failed: "failed" }

  before_create :generate_uuid

  def complete!(end_time)
    update!(
      ended_at: end_time,
      duration: end_time - started_at,
      status: error? ? "failed" : "successful"
    )
  end

  scope :by_user, ->(user) {
    joins(:flow).where(flows: { user_id: user.id })
  }


  private

  def generate_uuid
    self.uuid ||= SecureRandom.uuid
  end
end
