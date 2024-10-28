module CountsHelper
  MONITORING_SCOPES = %w[ absolute annual monthly ].freeze

  def monitoring_scopes_for_select
    MONITORING_SCOPES.map{ | scope | [scope == 'monthly' ? 'Mensile' : (scope == 'annual' ? 'Annuale' : 'Assoluto'), scope]}
  end
end
