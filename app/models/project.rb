class Project < ApplicationRecord
  belongs_to :user
  has_many :flows, dependent: :nullify
  validates :name, presence: true

  before_create :generate_public_token
  before_create :generate_secret_token

  def generate_public_token
    self.public_token ||= SecureRandom.hex(20)
  end

  def generate_secret_token
    self.secret_token ||= SecureRandom.hex(32)
  end

  def regenerate_secret_token!
    update!(secret_token: SecureRandom.hex(32))
  end

  def regenerate_public_token!
    update!(public_token: SecureRandom.hex(20))
  end
end
