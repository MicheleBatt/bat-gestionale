module MovementsHelper
  MOVEMENT_TYPES = %w[ in out ].freeze

  def movement_types_for_select
    MOVEMENT_TYPES.map{ | type | [type == 'in' ? 'Entrata' : 'Uscita', type]}
  end
end
