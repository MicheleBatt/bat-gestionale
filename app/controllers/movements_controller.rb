class MovementsController < ApplicationController
  before_action :set_count
  before_action :set_timerange, only: %i[ index ]
  before_action :check_timerange_report, only: %i[ index ]
  before_action :set_movement, only: %i[ update destroy ]

  include ApplicationHelper
  include MovementsHelper
  include ExpenseItemsHelper

  # GET /movements or /movements.json
  def index
    @new_out_movement = Movement.new
    @new_out_movement.movement_type = 'out'
    @new_in_movement = Movement.new
    @new_in_movement.movement_type = 'in'

    @search = @count.movements.ransack(params[:q])
    @movements = @search.result
    @movements_count = @movements.length

    out_movements = @movements.where(movement_type: 'out')
    in_movements = @movements.where(movement_type: 'in')
    @total_out_movements_amount = out_movements.sum(&:amount)
    @total_in_movements_amount = in_movements.sum(&:amount)
    @total_movements_amount = @total_in_movements_amount + @total_out_movements_amount
    @movements_amounts_by_expense_items = out_movements.joins(:expense_item).group(:expense_item).sum(:amount)
    @movements_amounts_by_expense_items.sort_by{ | expense_item, amount | expense_item.description }

    if @time_range_report
      @start_amount = @count.initial_amount_by_date(@splitted_emitted_at_gteq[0], @splitted_emitted_at_gteq[1], @splitted_emitted_at_gteq[2])
      @final_amount = @start_amount + @total_movements_amount
    end

    @movement_types = movement_types_for_select
    @expense_items = expense_items_for_select

    @page = params[:page] || 1
    @per_page = params[:per_page] || DEFAULT_PER_PAGE_PARAM
    frame_name = "movements-container-#{@page.to_i}"

    @movements = @movements.order(emitted_at: :asc, id: :asc).includes(:expense_item)

    @table_titles = @count.movements_list_table_titles(@year, @month, params[:q] ? params[:q][:emitted_at_gteq] : nil, params[:q] ? params[:q][:emitted_at_lteq] : nil)

    respond_to do |format|
      format.turbo_stream do
        @movements = @movements.page(@page).per(@per_page)
        render turbo_stream: turbo_stream.update(frame_name, partial: "movements/index", locals: { movements: @movements, count: @count, movement_types: @movement_types, expense_items: @expense_items, page: @page.to_i + 1, per_page: @per_page })
      end
      format.html {
        @movements = @movements.page(@page).per(@per_page)
        render 'index'
      }
      format.json { render json: @movements, status: :ok }
      format.xlsx {
        movements_file_name = @table_titles[:xlsx_file_name]
        render xlsx: 'index'
        response.headers['Content-Disposition'] = "attachment; filename=#{movements_file_name}"
      }
    end
  end

  # POST /movements or /movements.json
  def create
    modal_id = params[:movement][:modal_id]
    params[:movement].delete(:modal_id)
    @movement = Movement.new(movement_params)

    respond_to do |format|
      if @movement.save
        format.html { redirect_to @count.movements_path_by_month(@movement.year, @movement.month), notice: "Movimento di cassa aggiunto correttamente" }
        format.json { render :show, status: :created, location: @movement }
      else
        format.turbo_stream do
          render turbo_stream: turbo_stream.update("#{modal_id}_error_messages", partial: "layouts/error_messages", locals: { obj: @movement })
        end
        format.html { redirect_to @count.movements_default_path, status: :unprocessable_entity }
        format.json { render json: @movement.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /movements/1 or /movements/1.json
  def update
    modal_id = params[:movement][:modal_id]
    params[:movement].delete(:modal_id)

    respond_to do |format|
      if @movement.update(movement_params)
        format.html { redirect_to @count.movements_path_by_month(@movement.year, @movement.month), notice: "Movimento di cassa aggiornato correttamente" }
        format.json { render :show, status: :ok, location: @movement }
      else
        format.turbo_stream do
          render turbo_stream: turbo_stream.update("#{modal_id}_error_messages", partial: "layouts/error_messages", locals: { obj: @movement })
        end
        format.html { redirect_to @count.movements_default_path, status: :unprocessable_entity }
        format.json { render json: @movement.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /movements/1 or /movements/1.json
  def destroy
    year = @movement.year
    month = @movement.month
    @movement.destroy!

    respond_to do |format|
      format.html { redirect_to @count.movements_path_by_month(year, month), status: :see_other, notice: "Movimento di cassa rimoso" }
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

    def set_timerange
      if params[:q].blank? || params[:q][:emitted_at_gteq].blank?
        params[:q] = {} if params[:q].blank?
        first_movement_emission_date = @count.first_movement_emission_date
        params[:q][:emitted_at_gteq] = "#{first_movement_emission_date.year}-#{first_movement_emission_date.month}-#{first_movement_emission_date.day}"
      end

      if params[:q].blank? || params[:q][:emitted_at_lteq].blank?
        params[:q] = {} if params[:q].blank?
        last_movement_emission_date = @count.last_movement_emission_date
        params[:q][:emitted_at_lteq] = "#{last_movement_emission_date.year}-#{last_movement_emission_date.month}-#{last_movement_emission_date.day}"
      end
    end

    def check_timerange_report
      q = params[:q]
      if q.present? && q[:emitted_at_gteq].present? && q[:emitted_at_lteq].present? && blank_keys?(q, q.keys - %w[emitted_at_gteq emitted_at_lteq])
        @time_range_report = true
        @splitted_emitted_at_gteq = q[:emitted_at_gteq].split('-')
        splitted_emitted_at_lteq = q[:emitted_at_lteq].split('-')
        from_date = Date.new(@splitted_emitted_at_gteq[0].to_i, @splitted_emitted_at_gteq[1].to_i, @splitted_emitted_at_gteq[2].to_i)
        to_date = Date.new(splitted_emitted_at_lteq[0].to_i, splitted_emitted_at_lteq[1].to_i, splitted_emitted_at_lteq[2].to_i)
        from_date_year = from_date.year
        to_date_year = to_date.year
        from_date_month = from_date.month
        to_date_month = to_date.month
        from_date_day = from_date.day
        to_date_day = to_date.day

        check = from_date_year == to_date_year

        monthly_report =
            check &&
            from_date_month == to_date_month &&
            from_date_day == from_date.beginning_of_month.day &&
            to_date_day == to_date.end_of_month.day

        if monthly_report
          @year = from_date_year
          @month = from_date_month
        else
          annual_report =
            check &&
            from_date_month == 1 &&
            to_date_month == 12 &&
            from_date_day == from_date.beginning_of_year.day &&
            to_date_day == to_date.end_of_year.day

          @year = from_date_year if annual_report
        end
      else
        return [ false, nil, nil ]
      end
    end

    def blank_keys?(hash, keys)
      keys.each do |key|
        return false if hash[key].present?
      end
      return true
    end
end
