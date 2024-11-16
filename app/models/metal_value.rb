class MetalValue < ApplicationRecord
  include CountsHelper

  # Validations
  validates :metal, :value, :karat, presence: true
  validates :karat, :uniqueness => { scope: :metal }
  enum metal: ALL_METALS.keys.map { | key | key.to_s }.index_by(&:itself), _prefix: :metal
  validates :value, numericality: { greater_than_or_equal_to: 0.0 }
  validates :karat, numericality: { greater_than_or_equal_to: 0.0 }

  # Callbacks
  before_validation { self.value = self.value.to_f.round(2) if self.value }
  before_validation { self.karat = self.karat.to_f.round(2) if self.karat }
end
