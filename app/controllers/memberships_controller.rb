class MembershipsController < ApplicationController
  authorize_resource
  before_action :set_membership, only: %i[ update destroy ]
  before_action :set_user_id, only: %i[ update create ]

  # POST /memberships or /memberships.json
  def create
    modal_id = params[:membership][:modal_id]
    params[:membership].delete(:modal_id)
    @membership = Membership.new(membership_params)

    respond_to do |format|
      if @membership.save
        format.html { redirect_to organizations_path, notice: "Membro aggiunto correttamente all'organizzazione" }
        format.json { render :show, status: :created, location: @membership }
      else
        format.turbo_stream do
          render turbo_stream: turbo_stream.update("#{modal_id}_error_messages", partial: "layouts/error_messages", locals: { obj: @membership })
        end
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @membership.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /memberships/1 or /memberships/1.json
  def update
    modal_id = params[:membership][:modal_id]
    params[:membership].delete(:modal_id)

    respond_to do |format|
      if @membership.update(membership_params)
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.replace("membership_#{@membership.id}", partial: "memberships/membership", locals: { membership: @membership, organization: @organization }),
            turbo_stream.append("modal-closer", partial: "layouts/modal_closing")
          ]
        end
        format.html { redirect_to organizations_path, notice: "Ruolo aggiornato correttamente" }
        format.json { render :show, status: :ok, location: @membership }
      else
        format.turbo_stream do
          render turbo_stream: turbo_stream.update("#{modal_id}_error_messages", partial: "layouts/error_messages", locals: { obj: @membership })
        end
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @membership.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /memberships/1 or /memberships/1.json
  def destroy
    @membership.destroy!

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace("membership_#{@membership.id}", partial: "layouts/modal_closing")
      end
      format.html { redirect_to organizations_path, status: :see_other, notice: "Membro rimosso dall'organizzazione" }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_organization
      @organization = Organization.find(params[:organization_id])
    end

    def set_membership
      @membership = @organization.memberships.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def membership_params
      params.require(:membership).permit(:role, :user_id, :organization_id)
    end

    def set_user_id
      if params[:membership].present? && params[:membership][:email].present?
        params[:membership][:user_id] = User.find_by(email: params[:membership][:email])&.id
        params[:membership].delete(:email)
      end
    end
end
