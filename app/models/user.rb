class User < ApplicationRecord
  belongs_to :organization, optional: true
  belongs_to :role, optional: true

  has_secure_password
  has_many :sessions, dependent: :destroy
  has_paper_trail

  validates :email_address, presence: true,
                            format: { with: URI::MailTo::EMAIL_REGEXP },
                            uniqueness: { case_sensitive: false }

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  def can?(resource, action)
    return false unless role
    role.can?(resource, action)
  end

  def full_name
    [first_name, last_name].compact_blank.join(" ").presence || email_address
  end
end
