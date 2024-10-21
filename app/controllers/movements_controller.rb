class MovementsController < ApplicationController
  before_action :set_count
  before_action :set_movement, only: %i[ edit update destroy ]

  # GET /movements or /movements.json
  def index
    @movements = @count.movements.all
    @new_movement = Movement.new
  end

  # GET /movements/1/edit
  def edit
  end

  # POST /movements or /movements.json
  def create
    @movement = Movement.new(movement_params)

    respond_to do |format|
      if @movement.save
        format.html { redirect_to count_movements_path(count_id: @count.id), notice: "Movement was successfully created." }
        format.json { render :show, status: :created, location: @movement }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @movement.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /movements/1 or /movements/1.json
  def update
    respond_to do |format|
      if @movement.update(movement_params)
        format.html { redirect_to count_movements_path(count_id: @count.id), notice: "Movement was successfully updated." }
        format.json { render :show, status: :ok, location: @movement }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @movement.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /movements/1 or /movements/1.json
  def destroy
    @movement.destroy!

    respond_to do |format|
      format.html { redirect_to count_movements_path(count_id: @count.id), status: :see_other, notice: "Movement was successfully destroyed." }
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
