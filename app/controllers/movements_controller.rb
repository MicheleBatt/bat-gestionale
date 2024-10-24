class MovementsController < ApplicationController
  before_action :set_count
  before_action :set_movement, only: %i[ edit update destroy ]

  include ApplicationHelper

  # GET /movements or /movements.json
  def index
    @new_movement = Movement.new

    @year = params[:q].present? ? params[:q][:year_eq] : nil
    @month = params[:q].present? ? params[:q][:month_eq] : nil
    @year_and_month_filter_active = @year.present? && @month.present?
    
    @search = @count.movements.ransack(params[:q])
    @movements = @search.result

    out_movements = @movements.where(movement_type: 'out')
    in_movements = @movements.where(movement_type: 'in')
    @total_out_movements_amount = out_movements.sum(&:amount)
    @total_in_movements_amount = in_movements.sum(&:amount)
    @total_movements_amount = @total_in_movements_amount + @total_out_movements_amount
    @movements_amounts_by_expense_items = out_movements.joins(:expense_item).group(:expense_item).sum(:amount)
    @movements_amounts_by_expense_items.sort_by{ | expense_item, amount | expense_item.description }

    if @year_and_month_filter_active
      @start_amount = @count.month_final_amount(@year, @month)
      @final_amount = @start_amount + @total_movements_amount
    end

    @movements = @movements.order(emitted_at: :asc, id: :asc).includes(:expense_item)

    respond_to do |format|
      format.html { render 'index' }
      format.json { render json: @movements, status: :ok }
      format.xlsx {
        movements_file_name = "#{@month} - #{italian_month(@month)}.xlsx"
        render xlsx: 'index'
        response.headers['Content-Disposition'] = "attachment; filename=#{movements_file_name}"
      }
    end
  end

  # GET /movements/1/edit
  def edit
  end

  # POST /movements or /movements.json
  def create
    @movement = Movement.new(movement_params)

    respond_to do |format|
      if @movement.save
        format.html { redirect_to @count.movements_default_path, notice: "Movimento di cassa aggiunto correttamente" }
        format.json { render :show, status: :created, location: @movement }
      else
        format.turbo_stream do
          render turbo_stream: turbo_stream.update('new_movement_error_messages', partial: "layouts/error_messages", locals: { obj: @movement })
        end
        format.html { redirect_to @count.movements_default_path, status: :unprocessable_entity }
        format.json { render json: @movement.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /movements/1 or /movements/1.json
  def update
    respond_to do |format|
      if @movement.update(movement_params)
        format.html { redirect_to @count.movements_default_path, notice: "Movimento di cassa aggiornato correttamente" }
        format.json { render :show, status: :ok, location: @movement }
      else
        format.turbo_stream do
          render turbo_stream: turbo_stream.update("movement_#{@movement.id}_error_messages", partial: "layouts/error_messages", locals: { obj: @movement })
        end
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @movement.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /movements/1 or /movements/1.json
  def destroy
    @movement.destroy!

    respond_to do |format|
      format.html { redirect_to @count.movements_default_path, status: :see_other, notice: "Movimento di cassa rimoso" }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_movement
      @movement = @count.movements.find(params[:id])
    end

    def set_count
      @count = Count.find(params[:count_id])
    end

    # Only allow a list of trusted parameters through.
    def movement_params
      params.require(:movement).permit(:count_id, :expense_item_id, :amount, :causal, :movement_type, :emitted_at, :year, :month)
    end
end
