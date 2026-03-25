class MetalValue < ApplicationRecord
  include CountsHelper

  # Relations
  has_many :movements

  # Validations
  validates :metal, :value, :karat, :recorded_at, presence: true
  validates :recorded_at, uniqueness: { scope: [:metal, :karat] }
  enum metal: ALL_METALS.keys.map { | key | key.to_s }.index_by(&:itself), _prefix: :metal
  validates :value, numericality: { greater_than_or_equal_to: 0.0 }
  validates :karat, numericality: { greater_than_or_equal_to: 0.0 }

  # Callbacks
  before_validation { self.value = self.value.to_f.round(2) if self.value }
  before_validation { self.karat = self.karat.to_f.round(2) if self.karat }

  # Scopes
  scope :for_metal, ->(metal) { where(metal: metal) }
  scope :for_karat, ->(karat) { where(karat: karat) }
  scope :on_date, ->(date) { where(recorded_at: date) }
  scope :before_date, ->(date) { where('recorded_at <= ?', date).order(recorded_at: :desc) }

  # Prezzo più recente per un metallo e una caratura
  def self.latest_price(metal, karat)
    where(metal: metal, karat: karat).order(recorded_at: :desc).first&.value.round(2)
  end

  # Referenza al record della tabella alla data specificata (o il più recente prima di quella data)
  def self.metal_value_at_date(metal, karat, date)
    where(metal: metal, karat: karat).where('recorded_at <= ?', date).order(recorded_at: :desc).first
  end

  # Prezzo alla data specificata (o il più recente prima di quella data)
  def self.price_at_date(metal, karat, date)
    self.metal_value_at_date(metal, karat, date)&.value.to_f.round(2)
  end
end
