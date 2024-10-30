# frozen_string_literal: true

class Ability
  include CanCan::Ability

  def initialize(user)
    # Define abilities for the passed in user here. For example:
    user ||= User.new

    if user.admin?
      can :manage, :all
    elsif user.memberships.present?
      can :manage, [Count, Movement, ExpenseItem, Deadline]
      cannot :manage, [Organization, Membership]
      can [:edit, :update], User
      cannot [:idex, :add, :destroy], User
    end
  end
end
