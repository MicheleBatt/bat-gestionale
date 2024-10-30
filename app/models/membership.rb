class Membership < ApplicationRecord
  include MembershipsHelper

  # Relations
  belongs_to :user
  belongs_to :organization

  # Validations
  validates :user_id, :uniqueness => { scope: :organization }
  validates :role, presence: true
  enum role: ALL_MEMBERSHIP_ROLES.index_by(&:itself), _prefix: :role

  def username
    self.user.full_name
  end
end
