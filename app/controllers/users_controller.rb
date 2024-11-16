class UsersController < ApplicationController
  authorize_resource
  before_action :set_user, only: %i[ edit update destroy ]

  include ApplicationHelper

  # GET /users or /users.json
  def index
    @search = User.all.ransack(params[:q])
    @users = @search.result
    @users_count = @users.length
    @users =
      @users
      .order(first_name: :asc, last_name: :asc, email: :asc)
      .page(params[:page] || DEFAULT_PAGE)
      .per(params[:per_page] || DEFAULT_PER_PAGE_PARAM)
  end

  # POST /users/add or /users/add.json
  def add
    modal_id = params[:user][:modal_id]
    params[:user].delete(:modal_id)
    @user = User.new(user_params)

    respond_to do |format|
      if @user.save
        format.html { redirect_to users_path, notice: "Utente aggiunto correttamente a sistema" }
        format.json { render :index, status: :created, location: @user }
      else
        format.turbo_stream do
          render turbo_stream: turbo_stream.update("#{modal_id}_error_messages", partial: "layouts/error_messages", locals: { obj: @user })
        end
        format.html { redirect_to users_path, status: :unprocessable_entity }
        format.json { render json: @user.errors, status: :unprocessable_entity }
      end
    end
  end

  def edit
  end

  # PATCH/PUT /users/1 or /users/1.json
  def update
    modal_id = params[:user][:modal_id]
    params[:user].delete(:modal_id)

    respond_to do |format|
      outcome = @user.update(user_params) if params.dig(:user, :password).present?
      outcome = @user.update_without_password(user_params) if params.dig(:user, :password).blank?
      if outcome
        format.turbo_stream do
          if modal_id.present?
            render turbo_stream: turbo_stream.replace("user_#{@user.id}", partial: "users/user", locals: { user: @user })
          else
            redirect_to edit_user_path(@user), notice: "Account aggiornato correttamente"
          end
        end
        format.html { redirect_to edit_user_path(@user), notice: "Account aggiornato correttamente" }
        format.json { render :index, status: :ok, location: @user }
      else
        format.turbo_stream do
          render turbo_stream: turbo_stream.update("#{modal_id}_error_messages", partial: "layouts/error_messages", locals: { obj: @user })
        end
        format.html { redirect_to users_path, status: :unprocessable_entity }
        format.json { render json: @user.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /users/1 or /users/1.json
  def destroy
    @user.destroy!

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace("user_#{@user.id}", partial: "layouts/modal_closing")
      end
      format.html { redirect_to users_path, status: :see_other, notice: "Utente rimosso dal sistema" }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_user
      @user = User.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def user_params
      params.require(:user).permit(:first_name, :last_name, :email, :password, :password_confirmation, :role)
    end
end
