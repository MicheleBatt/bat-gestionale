class CountsController < ApplicationController
  before_action :set_count, only: %i[ edit update destroy stats ]

  include ApplicationHelper

  # GET /counts or /counts.json
  def index
    @counts = Count.all
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
    @count_final_amount_by_month = {}
    @movements_global_amount_by_expense_items_and_month = {}
    all_movements = @count.movements.where(movement_type: 'out')
    @min_year = all_movements.minimum('year')
    @max_year = all_movements.maximum('year')

    if params[:q].present? && params[:q][:year_eq].present?
      @search = all_movements.ransack(params[:q])
      movements = @search.result

      @year = params[:q][:year_eq]
      months = (1..12).to_a

      @count.expense_items.each_with_object({}) do |expense_item, hash|
        @movements_global_amount_by_expense_items_and_month[expense_item] = {'total' => 0}
      end

      @movements_max_amount = 0
      months.each do | month |
        @count_final_amount_by_month[italian_month(month)] = @count.initial_amount_by_date(@year, month + 1, 1)
        @movements_global_amount_by_expense_items_and_month.keys.each do | expense_item |
          global_amount_by_expense_items = movements.where(month: month, expense_item_id: expense_item.id).sum(&:amount).to_f.round(2)
          global_amount_by_expense_items = global_amount_by_expense_items * -1 if global_amount_by_expense_items < 0
          @movements_global_amount_by_expense_items_and_month[expense_item][italian_month(month)] = global_amount_by_expense_items
          @movements_global_amount_by_expense_items_and_month[expense_item]['total'] = @movements_global_amount_by_expense_items_and_month[expense_item]['total'] + global_amount_by_expense_items
          @movements_max_amount = [@movements_max_amount, global_amount_by_expense_items].max
        end
      end
      @movements_max_amount += 100
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
