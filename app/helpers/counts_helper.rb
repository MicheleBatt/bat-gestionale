module CountsHelper
  ALL_COUNT_TYPES = {
    "bank_account": "conto corrente",
    "savings_account": "conto risparmi",
    "investments_account": "fondo di investimento su azioni o obbligazioni",
    "gold_investment_account": "fondo di investimento sull'oro",
    "silver_investment_account": "fondo di investimento sull'argento",
    "accumulation_plan": "piano d'accumulo",
    "postal_savings_bond": "buoni fruttiferi postali",
    "savings_booklet": "libretto dei risparmi"
   }.freeze

  MONITORING_SCOPES = %w[ absolute annual monthly ].freeze

  def monitoring_scopes_for_select
    MONITORING_SCOPES.map{ | scope | [scope == 'monthly' ? 'Mensile' : (scope == 'annual' ? 'Annuale' : 'Assoluto'), scope]}
  end

  def count_types_for_select
    ALL_COUNT_TYPES.keys.map{ | count_type | [ ALL_COUNT_TYPES[count_type].to_s.capitalize, count_type ]}
  end
end
