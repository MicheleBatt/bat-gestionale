class CountsController < ApplicationController
  before_action :set_count, only: %i[ edit update destroy ]

  # GET /counts or /counts.json
  def index
    @counts = Count.all.includes(:movements)
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
        format.html { redirect_to counts_path, notice: "Count was successfully created." }
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
        format.html { redirect_to counts_path, notice: "Count was successfully updated." }
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
      format.html { redirect_to counts_path, status: :see_other, notice: "Count was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_count
      @count = Count.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def count_params
      params.require(:count).permit(:name, :description, :iban, :initial_amount)
    end
end
