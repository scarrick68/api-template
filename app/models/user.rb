# frozen_string_literal: true

class User < ApplicationRecord
  default_scope { where(deleted_at: nil) }

  before_validation :normalize_email
  validates :email, presence: true, uniqueness: { case_sensitive: false }

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable, :confirmable
  include DeviseTokenAuth::Concerns::User

  private

  def normalize_email
    self.email = email.to_s.strip.downcase.presence
  end
end
