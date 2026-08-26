class MembershipsController < ApplicationController
  authorize_resource
  before_action :set_membership, only: %i[ update destroy ]
  before_action :set_user_id, only: %i[ update create ]

  # POST /memberships or /memberships.json
  def create
    modal_id = params[:membership][:modal_id]
    params[:membership].delete(:modal_id)
    @membership = Membership.new(membership_params)

    # authorize_resource verifica solo la classe: senza questo controllo sul record un
    # editor potrebbe aggiungere membri a un'organizzazione di cui non è editor.
    authorize! :create, @membership

    # L'email non corrisponde a nessun utente: invece di fermarsi con un errore, il form
    # si allarga per creare l'account contestualmente (e al secondo invio lo crea).
    return handle_missing_user(modal_id) if user_to_be_created?

    respond_to do |format|
      if @membership.save
        # La lista si aggiorna sul posto: un redirect porterebbe l'utente sull'elenco delle
        # organizzazioni, che i non-admin non hanno nemmeno il permesso di aprire.
        format.turbo_stream { render turbo_stream: membership_list_streams(modal_id) }
        format.html { redirect_to organization_path(@membership.organization), notice: "Membro aggiunto correttamente all'organizzazione" }
        format.json { render :show, status: :created, location: @membership }
      else
        # Lo stato di errore è indispensabile: con un 200 il gestore di turbo:submit-end
        # in layouts/_auto_close_modals considera riuscito l'invio e chiude la modale,
        # nascondendo all'utente i messaggi di errore appena caricati.
        format.turbo_stream do
          render turbo_stream: turbo_stream.update("#{modal_id}_error_messages", partial: "layouts/error_messages", locals: { obj: @membership }), status: :unprocessable_entity
        end
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @membership.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /memberships/1 or /memberships/1.json
  def update
    modal_id = params[:membership][:modal_id]
    params[:membership].delete(:modal_id)

    respond_to do |format|
      if @membership.update(membership_params)
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace("membership_#{@membership.id}", partial: "memberships/membership", locals: { membership: @membership, organization: @organization })
        end
        format.html { redirect_to organizations_path, notice: "Ruolo aggiornato correttamente" }
        format.json { render :show, status: :ok, location: @membership }
      else
        # Stesso motivo di create: senza lo stato di errore la modale si chiuderebbe
        format.turbo_stream do
          render turbo_stream: turbo_stream.update("#{modal_id}_error_messages", partial: "layouts/error_messages", locals: { obj: @membership }), status: :unprocessable_entity
        end
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @membership.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /memberships/1 or /memberships/1.json
  def destroy
    @membership.destroy!

    respond_to do |format|
      # La lista viene ricostruita: se era l'ultimo membro compare il messaggio di elenco
      # vuoto, che una semplice rimozione della riga non avrebbe fatto apparire.
      format.turbo_stream do
        render turbo_stream: [
          *membership_list_streams,
          render_to_string(partial: "layouts/modal_closing").html_safe
        ]
      end
      format.html { redirect_to organization_path(@membership.organization), status: :see_other, notice: "Membro rimosso dall'organizzazione" }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_organization
      @organization = Organization.find(params[:organization_id])
    end

    def set_membership
      @membership = @organization.memberships.find(params[:id])

      # Stesso motivo di create: la verifica va fatta sul record, non sulla classe
      authorize! action_name.to_sym, @membership
    end

    # Only allow a list of trusted parameters through.
    def membership_params
      params.require(:membership).permit(:role, :user_id, :organization_id)
    end

    def set_user_id
      return if submitted_email.blank?

      # L'email resta nei parametri: serve a ripresentarla nel form e a creare l'account
      # se l'indirizzo non corrisponde a nessun utente.
      params[:membership][:user_id] = User.find_by(email: submitted_email)&.id
    end

    # L'indirizzo digitato nel form, normalizzato come lo memorizza Devise
    def submitted_email
      params.dig(:membership, :email).to_s.strip.downcase
    end

    # Va creato anche l'utente? Solo se è stata indicata un'email che non corrisponde a
    # nessun account e chi sta operando ha il permesso di crearne.
    def user_to_be_created?
      submitted_email.present? && @membership.user.blank? && can?(:create, User)
    end

    def new_user_params
      return {} if params[:user].blank?

      # Il ruolo globale non è fra i parametri consentiti: un nuovo utente non nasce admin,
      # il suo ruolo è quello che gli viene dato nella membership.
      params.require(:user).permit(:first_name, :last_name, :password, :password_confirmation)
    end

    # Primo invio: il form si allarga chiedendo i dati dell'account da creare.
    # Secondo invio: utente e membership nascono insieme.
    def handle_missing_user(modal_id)
      @new_user = User.new(new_user_params.merge(email: submitted_email))

      if params[:user].present? && create_user_and_membership
        respond_to do |format|
          format.turbo_stream { render turbo_stream: membership_list_streams(modal_id) }
          format.html { redirect_to organization_path(@membership.organization), notice: "Utente creato e aggiunto all'organizzazione" }
          format.json { render :show, status: :created, location: @membership }
        end
      else
        render_expanded_form(modal_id)
      end
    end

    # In transazione: se la membership fallisce dopo il salvataggio dell'utente,
    # a database non deve restare un account che nessuno ha chiesto.
    def create_user_and_membership
      outcome = false

      ActiveRecord::Base.transaction do
        outcome = @new_user.save && @membership.update(user: @new_user)
        raise ActiveRecord::Rollback unless outcome
      end

      # Gli errori dell'utente sono riportati sulla membership, così la vista ne mostra
      # un elenco solo, comprensivo di entrambi i problemi
      unless outcome
        @new_user.errors.full_messages.each { |message| @membership.errors.add(:base, message) }
      end

      outcome
    end

    # Aggiornamenti da inviare dopo l'aggiunta o la rimozione di un membro: la lista, il
    # conteggio nell'intestazione e il form della modale, riportato allo stato iniziale
    # perché alla riapertura non mostri i dati dell'inserimento precedente.
    # I bersagli assenti nella pagina corrente vengono semplicemente ignorati da Turbo.
    def membership_list_streams(modal_id = nil)
      organization = @membership.organization

      streams = [
        turbo_stream.replace("memberships_#{organization.id}",
                             partial: "memberships/list",
                             locals: { organization: organization }),
        turbo_stream.update("memberships_count_#{organization.id}",
                            "#{organization.memberships.count} Membri")
      ]

      # Le modali del membro seguono la sua riga: senza, i pulsanti di modifica e
      # rimozione punterebbero a elementi che nella pagina non esistono ancora.
      if @membership.destroyed?
        streams << turbo_stream.remove("membership_modals_#{@membership.id}")
      else
        streams << turbo_stream.append("memberships_modals_#{organization.id}",
                                       partial: "memberships/membership_modals",
                                       locals: { membership: @membership, organization: organization })
      end

      if modal_id.present?
        streams << turbo_stream.update("#{modal_id}_error_messages", "")
        # update e non replace: replace sostituirebbe il contenitore stesso, e con esso
        # l'id che serve a raggiungerlo l'invio successivo.
        streams << turbo_stream.update("#{modal_id}_form",
                                       partial: "memberships/form",
                                       locals: { membership: Membership.new,
                                                 organization: organization,
                                                 modal_id: modal_id })
      end

      streams
    end

    def render_expanded_form(modal_id)
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.update("#{modal_id}_error_messages", partial: "layouts/error_messages", locals: { obj: @membership }),
            turbo_stream.update("#{modal_id}_form",
                                partial: "memberships/form",
                                locals: { membership: @membership,
                                          organization: @organization,
                                          modal_id: modal_id,
                                          email: submitted_email,
                                          new_user: @new_user })
          ], status: :unprocessable_entity
        end
        format.html { redirect_to organizations_path, status: :unprocessable_entity }
      end
    end
end
