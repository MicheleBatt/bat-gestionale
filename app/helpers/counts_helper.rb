module CountsHelper
  MONITORING_SCOPES = %w[ absolute annual monthly ].freeze

  ALL_METALS = {
    'XAU': { 'italian_name': 'oro', unit: 'grams' },
    'XAG': { 'italian_name': 'argento', unit: 'grams' }
  }.freeze

  base_count_types = {
    "bank_account": "conto corrente",
    "savings_account": "conto risparmi",
    "investments_account": "fondo di investimento su azioni o obbligazioni",
    "accumulation_plan": "piano d'accumulo",
    "postal_savings_bond": "buoni fruttiferi postali",
    "savings_booklet": "libretto dei risparmi"
   }
  metals = ALL_METALS.keys.map{ | key | ["#{key.downcase}_investment_account", "fondo di investimento su #{ALL_METALS[key][:italian_name]}"] }.uniq.to_h
  ALL_COUNT_TYPES = { **base_count_types, **metals }.freeze

  base_currencies = %w[EUR]
  metals_currencies = ALL_METALS.keys.map{ | key | ALL_METALS[key][:unit] }.uniq
  ALL_CURRENCIES = [ *base_currencies, *metals_currencies ].freeze

  def monitoring_scopes_for_select
    MONITORING_SCOPES.map{ | scope | [scope == 'monthly' ? 'Mensile' : (scope == 'annual' ? 'Annuale' : 'Assoluto'), scope]}
  end

  def count_types_for_select
    ALL_COUNT_TYPES.keys.map{ | count_type | [ ALL_COUNT_TYPES[count_type].to_s.capitalize, count_type ]}
  end
end
