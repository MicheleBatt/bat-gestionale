module MetalValuesHelper

  DEFAULT_KARAT_PARAM = (24.0).freeze

  def available_karats_for_select(metal)
    MetalValue.where(metal: metal).order(karat: :desc).pluck(:karat).uniq.map { |k| ["#{k.to_i}k", k] }
  end
end
