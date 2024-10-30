class ApplicationController < ActionController::Base
  before_action :authenticate_user!
  before_action :set_organization

  rescue_from CanCan::AccessDenied do |exception|
    redirect_to '/404.html'
  end

  protected
    def set_organization
      if user_signed_in?
        organization_id = params[:organization_id]
        organization_id = current_user.memberships&.first&.organization_id if organization_id.blank?
        organization_id = Organization&.first&.id if organization_id.blank?
        @organization = Organization.find(organization_id)

        redirect_to '/404.html' if !current_user.admin? && !@organization.memberships.pluck(:user_id).include?(current_user.id)
      end
    end
end
