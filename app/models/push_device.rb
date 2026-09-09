# frozen_string_literal: true

# Stores client push token registrations for authenticated users.
class PushDevice < ApplicationRecord
  belongs_to :user

  validates :push_token, presence: true
  validates :platform, presence: true
end
