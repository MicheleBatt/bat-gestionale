class ExpenseItemsController < ApplicationController
  before_action :set_expense_item, only: %i[ update destroy ]

  # GET /expense_items or /expense_items.json
  def index
    @search = ExpenseItem.all.ransack(params[:q])
    @expense_items = @search.result.order(description: :asc).includes(:movements)
  end

  # POST /expense_items or /expense_items.json
  def create
    modal_id = params[:expense_item][:modal_id]
    params[:expense_item].delete(:modal_id)
    @expense_item = ExpenseItem.new(expense_item_params)

    respond_to do |format|
      if @expense_item.save
        format.html { redirect_to expense_items_path, notice: "Voce di spesa aggiunta correttamente alla lista" }
        format.json { render :index, status: :created, location: @expense_item }
      else
        format.turbo_stream do
          render turbo_stream: turbo_stream.update("#{modal_id}_error_messages", partial: "layouts/error_messages", locals: { obj: @expense_item })
        end
        format.html { redirect_to expense_items_path, status: :unprocessable_entity }
        format.json { render json: @expense_item.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /expense_items/1 or /expense_items/1.json
  def update
    modal_id = params[:expense_item][:modal_id]
    params[:expense_item].delete(:modal_id)
    
    respond_to do |format|
      if @expense_item.update(expense_item_params)
        format.html { redirect_to expense_items_path, notice: "Voce di spesa aggiornata correttamente" }
        format.json { render :index, status: :ok, location: @expense_item }
      else
        format.turbo_stream do
          render turbo_stream: turbo_stream.update("#{modal_id}_error_messages", partial: "layouts/error_messages", locals: { obj: @expense_item })
        end
        format.html { redirect_to expense_items_path, status: :unprocessable_entity }
        format.json { render json: @expense_item.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /expense_items/1 or /expense_items/1.json
  def destroy
    @expense_item.destroy!

    respond_to do |format|
      format.html { redirect_to expense_items_path, status: :see_other, notice: "Voce di spesa rimossa dalla lista" }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_expense_item
      @expense_item = ExpenseItem.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def expense_item_params
      params.require(:expense_item).permit(:description, :color)
    end
end
