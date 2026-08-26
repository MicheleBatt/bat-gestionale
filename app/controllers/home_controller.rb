class HomeController < ApplicationController
  # Punto d'ingresso dell'applicazione: smista l'utente verso la prima pagina utile.
  #
  # - chi appartiene a un'organizzazione va sulla dashboard della prima a cui si è unito
  # - un admin senza organizzazioni va sull'elenco delle organizzazioni
  # - chi non ha organizzazioni e non è admin non ha nulla da vedere: 404
  #
  # Nota: il terzo caso è già intercettato da ApplicationController#set_organization, che
  # rimanda a /404.html chi non è membro dell'organizzazione corrente. Il ramo resta qui
  # come rete di sicurezza, perché quella logica potrebbe cambiare.
  def index
    organization = current_user.memberships.order(:id).first&.organization

    if organization.present?
      redirect_to organization_path(organization)
    elsif current_user.admin?
      redirect_to organizations_path
    else
      redirect_to '/404.html'
    end
  end
end
