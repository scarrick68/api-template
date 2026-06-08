class UserPolicy < ApplicationPolicy
  def create?
    true
  end

  def index?
    !!user&.admin?
  end

  def show?
    return false unless user

    user.admin? || user == record
  end

  def update?
    return false unless user

    user.admin? || user == record
  end

  def destroy?
    return false unless user

    user.admin? || user == record
  end
end
