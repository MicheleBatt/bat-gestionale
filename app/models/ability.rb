# frozen_string_literal: true

class Ability
  include CanCan::Ability

  def initialize(user)
    user ||= User.new

    # Tutti gli utenti possono modificare i dati del loro account
    can :edit, User, id: user.id
    can :update, User, id: user.id

    if user.admin?
      can :manage, :all
    elsif user.memberships.present?
      # Tutti i membri di una organizzazione possono leggere i dati della loro organizzazione
      organizations_ids = user.memberships.pluck(:organization_id)
      can :read, Count, organization_id: organizations_ids
      can :stats, Count, organization_id: organizations_ids
      can :read, Movement, count: { organization_id: organizations_ids }
      can :stats, Movement, count: { organization_id: organizations_ids }
      can :read, ExpenseItem, organization_id: organizations_ids
      can :read, Deadline, organization_id: organizations_ids

      # Gli editor possono creare, modificare, eliminare dati relativi alla loro organizzazione
      editor_organizations_ids = user.memberships.where(role: 'editor').pluck(:organization_id)
      if editor_organizations_ids.present?
        can :manage, Count, organization_id: editor_organizations_ids
        can :manage, Movement, count: { organization_id: editor_organizations_ids }
        can :manage, ExpenseItem, organization_id: editor_organizations_ids
        can :manage, Deadline, organization_id: editor_organizations_ids
      end

      cannot :manage, [Organization, Membership]
      cannot [:index, :add, :destroy], User
    end
  end
end
