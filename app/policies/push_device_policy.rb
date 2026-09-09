# frozen_string_literal: true

# Authorizes authenticated users to manage their push-device registrations.
class PushDevicePolicy < ApplicationPolicy
  def create?
    user.present?
  end

  def destroy?
    user.present?
  end
end
