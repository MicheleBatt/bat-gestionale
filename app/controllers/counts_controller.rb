class CountsController < ApplicationController
  before_action :set_count, only: %i[ edit update destroy stats ]

  include ApplicationHelper

  # GET /counts or /counts.json
  def index
    @search = Count.all.ransack(params[:q])
    @counts = @search.result
    @counts_global_amount = @counts.sum(:current_amount).to_f.round(2)
    @counts = @counts.order(ordering_number: :asc).includes(:movements)
  end

  # GET /counts/new
  def new
    @count = Count.new
  end

  # GET /counts/1/edit
  def edit
  end

  # POST /counts or /counts.json
  def create
    @count = Count.new(count_params)

    respond_to do |format|
      if @count.save
        format.html { redirect_to counts_path, notice: "Conto aggiunto correttamente alla lista dei conti corrente" }
        format.json { render :show, status: :created, location: @count }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @count.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /counts/1 or /counts/1.json
  def update
    respond_to do |format|
      if @count.update(count_params)
        format.html { redirect_to counts_path, notice: "Conto corrente aggiornato correttamente" }
        format.json { render :show, status: :ok, location: @count }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @count.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /counts/1 or /counts/1.json
  def destroy
    @count.destroy!

    respond_to do |format|
      format.html { redirect_to counts_path, status: :see_other, notice: "Conto rimosso dalla lista dei conti corrente" }
      format.json { head :no_content }
    end
  end

  def stats
    @grouped_count_final_amounts = {}
    @movements_global_amount_by_expense_items = {}
    @years_range = @count.years_range

    @search = @count.movements.where(movement_type: 'out').ransack(params[:q])
    movements = @search.result

    @year = params[:q].present? ? params[:q][:year_eq] : nil
    months = (1..12).to_a

    @count.expense_items.each_with_object({}) do |expense_item, hash|
      @movements_global_amount_by_expense_items[expense_item] = {'total' => 0}
    end

    @movements_max_amount = 0
    time_ranges = @year.present? ? months : @years_range
    time_ranges.each do | time_range |
      # Calcolo la giacenza finale sul conto a fine di ogni mese / anno
      if @year.present?
        @grouped_count_final_amounts[italian_month(time_range)] = @count.initial_amount_by_date(@year, time_range + 1, 1)
      else
        @grouped_count_final_amounts[time_range] = @count.initial_amount_by_date(time_range + 1, 1, 1)
      end

      # Calcolo l'ammontare complessivo delle varie spese durante ogni mese / anno
      @movements_global_amount_by_expense_items.keys.each do | expense_item |
        movements_by_expense_item = movements.where(expense_item_id: expense_item.id)
        movements_by_expense_item = @year.present? ? movements_by_expense_item.where(month: time_range) : movements_by_expense_item.where(year: time_range)
        global_amount_by_expense_items = movements_by_expense_item.sum(&:amount).to_f.round(2)
        global_amount_by_expense_items = global_amount_by_expense_items * -1 if global_amount_by_expense_items < 0
        @movements_global_amount_by_expense_items[expense_item][@year.present? ? italian_month(time_range) : time_range] = global_amount_by_expense_items
        @movements_global_amount_by_expense_items[expense_item]['total'] = @movements_global_amount_by_expense_items[expense_item]['total'] + global_amount_by_expense_items
        @movements_max_amount = [@movements_max_amount, global_amount_by_expense_items].max
      end
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_count
      @count = Count.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def count_params
      params.require(:count).permit(:name, :description, :iban, :initial_amount, :ordering_number)
    end
end
