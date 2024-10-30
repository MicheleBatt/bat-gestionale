class User < ApplicationRecord
  include UsersHelper

  # Relations
  has_many :memberships, dependent: :destroy
  has_many :organizations, through: :memberships
  has_many :counts, through: :organizations
  has_many :expense_items, through: :organizations
  has_many :deadlines, through: :organizations
  has_many :movements, through: :counts

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  # Validations
  validates :first_name, :last_name, presence: true
  enum role: ALL_USER_ROLES.index_by(&:itself), _prefix: :role


  # Instance Methods
  def self.ransackable_scopes(_auth_object = nil)
    %i[]
  end

  def self.ransackable_attributes(auth_object = nil)
    %w(first_name last_name email role)
  end

  def self.ransackable_associations(auth_object = nil)
    %i[]
  end

  def full_name
    "#{self.first_name} #{self.last_name}"
  end

  def admin?
    self.role == 'admin'
  end
end
