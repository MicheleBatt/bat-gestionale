module MembershipsHelper
  ALL_MEMBERSHIP_ROLES = %w[guest editor].freeze

  def all_membership_roles_for_select
    ALL_MEMBERSHIP_ROLES.map { | role | [italian_role(role), role]}
  end

  def italian_role(role)
    role == 'guest' ? 'Ospite' : 'Editor'
  end
end
