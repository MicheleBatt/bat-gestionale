class OrganizationsController < ApplicationController
  authorize_resource
  before_action :set_current_organization, only: %i[ show update destroy stats month_movements ]

  include ApplicationHelper

  # Quanti movimenti del mese mostra la dashboard prima del "vedi tutti"
  DASHBOARD_MOVEMENTS_LIMIT = 10

  # GET /organizations or /organizations.json
  def index
    @search = Organization.all.ransack(params[:q])
    @organizations = @search.result.order(name: :asc).includes(memberships: :user)
    @organizations_count = @organizations.length
  end

  # GET /organizations/1
  # Dashboard di sintesi dell'organizzazione: anagrafica, membri, e l'attività registrata
  # nell'ultimo mese (movimenti, giacenze, spese per voce, scadenze).
  def show
    # authorize_resource controlla la classe, non il singolo record: senza questa riga un
    # membro potrebbe aprire la dashboard di un'organizzazione a cui non appartiene.
    authorize! :show, @organization

    @memberships = @organization.memberships.includes(:user).sort_by { |membership| membership.username.to_s.downcase }

    set_dashboard_period

    # Tutta la pagina guarda la fine del mese mostrato: i conti sono quelli già esistenti
    # a quella data e le giacenze sono quelle che risultavano allora, non quelle di oggi.
    @closing_date = @period_end.end_of_month
    @counts = @organization.not_deleted_counts.where(created_at: ..@closing_date.end_of_day)

    # initial_amount_by_date somma i movimenti *precedenti* alla data indicata: per includere
    # anche l'ultimo giorno del mese si passa il giorno successivo. Il metodo valorizza già
    # i piani sui metalli al cambio di quella data.
    day_after = @closing_date + 1.day
    @global_amount = @organization.initial_amount_by_date(day_after.year, day_after.month, day_after.day).to_f.round(2)

    # Intervalli dei pulsanti di navigazione: mese pieno, dal primo all'ultimo giorno
    previous_month = @period_start.prev_month
    next_month = @period_start.next_month
    @previous_period = { from: previous_month.beginning_of_month, to: previous_month.end_of_month }
    @next_period = { from: next_month.beginning_of_month, to: next_month.end_of_month }

    period_movements = month_movements_scope

    @movements_count = period_movements.count
    @recent_movements = period_movements.limit(DASHBOARD_MOVEMENTS_LIMIT)

    # Quanti movimenti sono entrate e quante uscite. L'ordinamento e le associazioni
    # precaricate vanno tolti: su un conteggio raggruppato, includes produce una JOIN
    # che moltiplicherebbe le righe.
    movements_by_type = period_movements.except(:includes, :order).group(:movement_type).count
    @movements_in_count = movements_by_type['in'].to_i
    @movements_out_count = movements_by_type['out'].to_i

    # I movimenti sui piani in metalli sono espressi in grammi: vanno tenuti fuori dai
    # totali e dai grafici in euro, altrimenti sommerebbero unità di misura diverse.
    cash_movements = period_movements.to_a.reject { |movement| movement.count.metal_account? }
    @period_in = cash_movements.sum { |movement| [movement.amount.to_f, 0].max }.round(2)
    @period_out = cash_movements.sum { |movement| [movement.amount.to_f, 0].min }.round(2)
    @period_balance = (@period_in + @period_out).round(2)

    @in_out_by_day = in_out_by_day(cash_movements)
    @amount_by_count = amount_by_count(@counts)
    @expenses_by_item, @expense_items_colors = expenses_by_item(cash_movements)

    @deadlines = @organization.deadlines
                              .where(year: @period_end.year, month: @period_end.month)
                              .order(expired_at: :asc)
  end

  # GET /organizations/1/month_movements
  # Restituisce, via turbo stream, i movimenti del mese oltre a quelli già mostrati nella
  # dashboard, per accodarli alla lista senza ricaricare la pagina.
  def month_movements
    authorize! :show, @organization

    set_dashboard_period
    @movements = month_movements_scope.offset(DASHBOARD_MOVEMENTS_LIMIT)

    respond_to do |format|
      format.turbo_stream
      # Senza JavaScript (o aprendo il link in una nuova scheda) si finisce sulla dashboard
      format.html { redirect_to organization_path(@organization) }
    end
  end

  # POST /organizations or /organizations.json
  def create
    modal_id = params[:organization][:modal_id]
    params[:organization].delete(:modal_id)
    @organization = Organization.new(organization_params)

    respond_to do |format|
      if @organization.save
        format.html { redirect_to organizations_path, notice: "Organizzazione aggiunta correttamente alla lista" }
        format.json { render :index, status: :created, location: @organization }
      else
        format.turbo_stream do
          render turbo_stream: turbo_stream.update("#{modal_id}_error_messages", partial: "layouts/error_messages", locals: { obj: @organization }), status: :unprocessable_entity
        end
        format.html { redirect_to organizations_path, status: :unprocessable_entity }
        format.json { render json: @organization.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /organizations/1 or /organizations/1.json
  def update
    modal_id = params[:organization][:modal_id]
    params[:organization].delete(:modal_id)
    
    respond_to do |format|
      if @organization.update(organization_params)
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace("organization_#{@organization.id}", partial: "organizations/organization", locals: { organization: @organization })
        end
        format.html { redirect_to organizations_path, notice: "Organizzazione aggiornata correttamente" }
        format.json { render :index, status: :ok, location: @organization }
      else
        format.turbo_stream do
          render turbo_stream: turbo_stream.update("#{modal_id}_error_messages", partial: "layouts/error_messages", locals: { obj: @organization }), status: :unprocessable_entity
        end
        format.html { redirect_to organizations_path, status: :unprocessable_entity }
        format.json { render json: @organization.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /organizations/1 or /organizations/1.json
  def destroy
    @organization.destroy!

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace("organization_#{@organization.id}", partial: "layouts/modal_closing")
      end
      format.html { redirect_to organizations_path, status: :see_other, notice: "Organizzazione rimossa dalla lista" }
      format.json { head :no_content }
    end
  end

  def stats
    # authorize_resource verifica solo la classe: senza questo controllo un membro
    # potrebbe aprire le statistiche di un'organizzazione a cui non appartiene.
    authorize! :stats, @organization

    @search = @organization.movements.includes(:count).ransack(params[:q])
    movements = @search.result

    @count = @organization.not_deleted_counts.find(params[:q][:count_id_eq]) if params[:q].present? && params[:q][:count_id_eq].present?

    @years_range,
    @final_amounts_by_date,
    @movements_global_amount_by_expense_items,
    @year,
    @movements_max_amount,
    @in_out_global_valued_amounts = stats_for_charts(@count || @organization, movements, params)

    if @count.blank?
      @movements_global_amount_by_counts,
      @savings_global_amount_by_counts = @organization.additional_stats_for_charts(@year)
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_current_organization
      @organization = Organization.find(params[:id])
    end

    # Finestra temporale della dashboard: il mese corrente, dal primo del mese a oggi
    # Il periodo mostrato è un intervallo di date preso dai parametri della richiesta.
    # Senza parametri vale il mese corrente, dal primo giorno a oggi; i pulsanti di
    # navigazione fra i mesi non fanno altro che riproporre la stessa pagina con
    # l'intervallo spostato indietro o avanti.
    def set_dashboard_period
      @period_start = data_da_parametro(:from) || Date.today.beginning_of_month
      @period_end = data_da_parametro(:to) || Date.today

      # Un intervallo rovesciato produrrebbe pagine vuote senza spiegazione
      @period_start, @period_end = @period_end, @period_start if @period_start > @period_end
    end

    # Interpreta una data dai parametri, ignorando valori assenti o malformati
    def data_da_parametro(nome)
      valore = params[nome]
      return nil if valore.blank?

      Date.parse(valore)
    rescue Date::Error
      nil
    end

    # Movimenti del periodo, dal più recente: la stessa base per la dashboard e per il
    # caricamento incrementale, così le due liste non possono divergere
    def month_movements_scope
      @organization.movements
                   .includes(:count, :expense_item)
                   .where(emitted_at: @period_start.beginning_of_day..@period_end.end_of_day)
                   # reorder e non order: l'associazione movements passa da counts, che ordina
                   # per ordering_number, e order si limiterebbe ad accodarsi a quello. La lista
                   # risulterebbe raggruppata per conto invece che cronologica.
                   .reorder(emitted_at: :desc, id: :desc)
    end

    # Entrate e uscite giorno per giorno nel periodo, pronte per il grafico a colonne.
    # Tutti i giorni sono presenti anche senza movimenti, così l'asse temporale non ha buchi.
    def in_out_by_day(movements)
      incomes = Hash.new(0.0)
      outflows = Hash.new(0.0)

      movements.each do |movement|
        bucket = movement.amount.to_f > 0 ? incomes : outflows
        bucket[movement.emitted_at.to_date] += movement.amount.to_f
      end

      # Le chiavi sono etichette già formattate (es. "26/08") e non oggetti Date: passando
      # le date, Chartkick costruirebbe un asse temporale con etichette in formato ISO.
      # Uscite prima delle entrate, come nel grafico della pagina statistiche: l'ordine
      # delle serie determina l'ordine delle barre e l'abbinamento con i colori.
      days = (@period_start..@period_end).to_a
      [
        { name: 'Uscite', data: days.to_h { |day| [day.strftime('%-d %-b'), outflows[day].abs.round(2)] } },
        { name: 'Entrate', data: days.to_h { |day| [day.strftime('%-d %-b'), incomes[day].round(2)] } }
      ]
    end

    # Controvalore in euro di ogni conto alla fine del mese mostrato, per il grafico a
    # torta della ripartizione: come per la giacenza complessiva, i saldi sono quelli
    # che risultavano a quella data e non quelli odierni.
    def amount_by_count(counts)
      day_after = @closing_date + 1.day

      counts.each_with_object({}) do |count, result|
        value = if count.metal_account?
                  count.economic_value_at_date(@closing_date).to_f
                else
                  count.initial_amount_by_date(day_after.year, day_after.month, day_after.day).to_f
                end
        result[count.name] = value.round(2) if value.positive?
      end
    end

    # Uscite del periodo raggruppate per voce di spesa, con i colori scelti dall'utente
    # per ciascuna voce, così il grafico usa la stessa legenda cromatica del resto dell'app.
    def expenses_by_item(movements)
      grouped = movements.select { |movement| movement.amount.to_f.negative? && movement.expense_item.present? }
                         .group_by(&:expense_item)
                         .transform_values { |items| items.sum { |movement| movement.amount.to_f }.abs.round(2) }

      [
        grouped.to_h { |expense_item, total| [expense_item.description, total] },
        grouped.map { |expense_item, _total| expense_item.color.presence || '#94a3b8' }
      ]
    end

    # Only allow a list of trusted parameters through.
    def organization_params
      params.require(:organization).permit(:name)
    end
end
