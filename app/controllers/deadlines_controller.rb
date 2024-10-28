class DeadlinesController < ApplicationController
  before_action :set_deadline, only: %i[ update destroy ]

  # GET /deadlines or /deadlines.json
  def index
    @search = Deadline.all.ransack(params[:q])
    @dealines = @search.result
    @deadlines_count = @dealines.length
    @deadlines_by_year = @dealines.order(expired_at: :asc).group_by(&:year)

    respond_to do |format|
      format.html { render 'index' }
      format.json { render json: @deadlines_by_year, status: :ok }
      format.xlsx {
        render xlsx: 'index'
        response.headers['Content-Disposition'] = "attachment; filename=SCADENZIARIO.xlsx"
      }
    end
  end

  # POST /deadlines or /deadlines.json
  def create
    modal_id = params[:deadline][:modal_id]
    params[:deadline].delete(:modal_id)
    @deadline = Deadline.new(deadline_params)

    respond_to do |format|
      if @deadline.save
        format.html { redirect_to deadlines_path, notice: "Nuova scadenza aggiunta correttamente allo scadenziario" }
        format.json { render :show, status: :created, location: @deadline }
      else
        format.turbo_stream do
          render turbo_stream: turbo_stream.update("#{modal_id}_error_messages", partial: "layouts/error_messages", locals: { obj: @deadline })
        end
        format.html { redirect_to deadlines_path, status: :unprocessable_entity }
        format.json { render json: @deadline.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /deadlines/1 or /deadlines/1.json
  def update
    modal_id = params[:deadline][:modal_id]
    params[:deadline].delete(:modal_id)

    respond_to do |format|
      if @deadline.update(deadline_params)
        format.html { redirect_to deadlines_path, notice: "Scadenza aggiornata correttamente" }
        format.json { render :show, status: :ok, location: @deadline }
      else
        format.turbo_stream do
          render turbo_stream: turbo_stream.update("#{modal_id}_error_messages", partial: "layouts/error_messages", locals: { obj: @deadline })
        end
        format.html { redirect_to deadlines_path, status: :unprocessable_entity }
        format.json { render json: @deadline.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /deadlines/1 or /deadlines/1.json
  def destroy
    @deadline.destroy!

    respond_to do |format|
      format.html { redirect_to deadlines_path, status: :see_other, notice: "Scadenza rimossa dallo scadenziario" }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_deadline
      @deadline = Deadline.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def deadline_params
      params.require(:deadline).permit(:description, :expired_at, :year)
    end
end
