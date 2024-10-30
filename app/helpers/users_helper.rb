module UsersHelper
  ALL_USER_ROLES = %w[admin].freeze

  def all_user_roles_for_select
    ALL_USER_ROLES.map { | role | [role.titleize, role] }
  end
end
