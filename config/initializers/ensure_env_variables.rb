env_variables = %w[]

if Rails.env.staging? || Rails.env.production?
  env_variables << 'USER'
  env_variables << 'DATABASE'
  env_variables << 'DATABASE_PWD'
end

env_variables.each do |env_var|
  if !ENV.has_key?(env_var) || ENV[env_var].blank?
    error_message = "Missing environment variable: #{env_var}. Ask a teammate for the appropriate value."
    Rails.logger.warn error_message
    raise error_message
  end
end