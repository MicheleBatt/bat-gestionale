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

      # Dashboard, caricamento incrementale dei movimenti e statistiche della propria
      # organizzazione restano visibili: sono in sola lettura e mostrano dati che il membro
      # può già consultare altrove. Gestione e modifica restano agli admin.
      can [:show, :month_movements, :stats], Organization, id: organizations_ids

      # Gli editor gestiscono i membri delle sole organizzazioni di cui sono editor:
      # possono aggiungerli, cambiarne il ruolo e rimuoverli. La regola sta dopo il
      # `cannot` perché in CanCanCan vince l'ultima definizione che corrisponde.
      if editor_organizations_ids.present?
        can :manage, Membership, organization_id: editor_organizations_ids

        # Creare un utente è consentito solo come passaggio dell'aggiunta di un membro:
        # la pagina utenti usa l'azione :add, che resta riservata agli admin.
        can :create, User
      end
    end
  end
end
