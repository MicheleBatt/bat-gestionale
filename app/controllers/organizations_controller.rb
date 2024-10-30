class OrganizationsController < ApplicationController
  authorize_resource
  before_action :set_current_organization, only: %i[ update destroy stats ]

  include ApplicationHelper

  # GET /organizations or /organizations.json
  def index
    @search = Organization.all.ransack(params[:q])
    @organizations = @search.result
    @organizations_count = @organizations.length
    @organizations =
      @organizations
      .order(name: :asc)
      .includes(memberships: :user)
      .page(params[:page] || DEFAULT_PAGE)
      .per(params[:per_page] || DEFAULT_PER_PAGE_PARAM)
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
          render turbo_stream: turbo_stream.update("#{modal_id}_error_messages", partial: "layouts/error_messages", locals: { obj: @organization })
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
          render turbo_stream: turbo_stream.update("#{modal_id}_error_messages", partial: "layouts/error_messages", locals: { obj: @organization })
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
    @search = @organization.movements.ransack(params[:q])
    movements = @search.result

    @count = @organization.counts.find(params[:q][:count_id_eq]) if params[:q].present? && params[:q][:count_id_eq].present?

    @years_range,
    @final_amounts_by_date,
    @movements_global_amount_by_expense_items,
    @year,
    @movements_max_amount,
    @in_out_global_amounts = stats_for_charts(@count || @organization, movements, params)

    if @count.blank?
      @movements_global_amount_by_counts = {}
      @savings_global_amount_by_counts = {}
      @organization.counts.each do | count |
        if @year.present?
          global_amount = count.initial_amount_by_date(@year.to_i + 1, 1, 1)
        else
          global_amount = count.initial_amount_by_date(count.max_year + 1, 1, 1)
        end
        @movements_global_amount_by_counts[count.name] = global_amount
        @savings_global_amount_by_counts[count.name] = global_amount if count.count_type != 'bank_account'
      end
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_current_organization
      @organization = Organization.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def organization_params
      params.require(:organization).permit(:name)
    end
end
