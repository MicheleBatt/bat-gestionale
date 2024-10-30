class CountsController < ApplicationController
  authorize_resource
  before_action :set_count, only: %i[ update destroy stats ]

  include ApplicationHelper

  # GET /counts or /counts.json
  def index
    @search = @organization.counts.ransack(params[:q])
    @counts = @search.result
    @counts_count = @counts.length
    @counts_global_amount = @counts.sum(:current_amount).to_f.round(2)
    @counts =
      @counts
      .includes(:movements)
      .page(params[:page] || DEFAULT_PAGE)
      .per(params[:per_page] || DEFAULT_PER_PAGE_PARAM)
  end

  # GET /counts/1/edit
  def edit
  end

  # POST /counts or /counts.json
  def create
    modal_id = params[:count][:modal_id]
    params[:count].delete(:modal_id)
    @count = Count.new(count_params)

    respond_to do |format|
      if @count.save
        format.html { redirect_to organization_counts_path(@organization), notice: "Conto aggiunto correttamente alla lista dei conti corrente" }
        format.json { render :show, status: :created, location: @count }
      else
        format.turbo_stream do
          render turbo_stream: turbo_stream.update("#{modal_id}_error_messages", partial: "layouts/error_messages", locals: { obj: @count })
        end
        format.html { redirect_to organization_counts_path(@organization), status: :unprocessable_entity }
        format.json { render json: @count.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /counts/1 or /counts/1.json
  def update
    modal_id = params[:count][:modal_id]
    params[:count].delete(:modal_id)

    respond_to do |format|
      if @count.update(count_params)
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace("count_#{@count.id}", partial: "counts/count", locals: { count: @count })
        end
        format.html { redirect_to organization_counts_path(@organization), notice: "Conto corrente aggiornato correttamente" }
        format.json { render :show, status: :ok, location: @count }
      else
        format.turbo_stream do
          render turbo_stream: turbo_stream.update("#{modal_id}_error_messages", partial: "layouts/error_messages", locals: { obj: @count })
        end
        format.html { redirect_to organization_counts_path(@organization), status: :unprocessable_entity }
        format.json { render json: @count.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /counts/1 or /counts/1.json
  def destroy
    @count.destroy!

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace("count_#{@count.id}", partial: "layouts/modal_closing")
      end
      format.html { redirect_to organization_counts_path(@organization), status: :see_other, notice: "Conto rimosso dalla lista dei conti corrente" }
      format.json { head :no_content }
    end
  end

  def stats
    @search = @count.movements.ransack(params[:q])
    movements = @search.result

    @years_range,
    @final_amounts_by_date,
    @movements_global_amount_by_expense_items,
    @year,
    @movements_max_amount,
    @in_out_global_amounts = stats_for_charts(@count, movements, params)
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_count
      @count = @organization.counts.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def count_params
      params.require(:count).permit(:name, :description, :count_type, :iban, :monitoring_scope, :initial_amount, :ordering_number, :organization_id)
    end
end
