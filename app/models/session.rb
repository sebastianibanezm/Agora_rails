class Session < ApplicationRecord
  EXPIRES_IN = 2.weeks

  belongs_to :user

  scope :active, -> { where("expires_at > ?", Time.current) }
  scope :expired, -> { where(expires_at: ..Time.current) }

  validates :expires_at, presence: true

  def expired?
    expires_at <= Time.current
  end
end
