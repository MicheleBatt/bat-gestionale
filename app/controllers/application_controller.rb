class ApplicationController < ActionController::Base
  before_action :authenticate_user!
  before_action :set_organization

  rescue_from CanCan::AccessDenied do |exception|
    redirect_to '/404.html'
  end

  protected
    # Stabilisce l'organizzazione di contesto della richiesta: serve alla navbar e alle
    # azioni index dei controller annidati, che non hanno un singolo record da autorizzare.
    def set_organization
      return unless user_signed_in?

      @organization = resolve_organization
      return if @organization.nil?

      # L'appartenenza è definita una volta sola, in Ability: qui si applica soltanto.
      # CanCan::AccessDenied è gestita dal rescue_from in cima a questa classe.
      authorize! :show, @organization
    end

    # L'organizzazione richiesta esplicitamente dalla rotta, altrimenti la prima a cui
    # l'utente appartiene. Un admin senza organizzazioni ripiega sulla prima esistente;
    # se non ne esiste nessuna il risultato è nil e sono le singole pagine a gestirlo.
    def resolve_organization
      # Nelle rotte annidate l'identificativo è :organization_id, in quelle di
      # OrganizationsController è :id. Altrove :id indica tutt'altro (un utente, un conto...).
      requested_id = params[:organization_id].presence
      requested_id ||= params[:id].presence if controller_name == "organizations"

      return Organization.find(requested_id) if requested_id.present?

      current_user.memberships.order(:id).first&.organization ||
        (current_user.admin? ? Organization.order(:id).first : nil)
    end
end
