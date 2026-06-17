class Admin < ApplicationRecord
  belongs_to :user, optional: true

  devise :database_authenticatable,
    :recoverable,
    :rememberable,
    :validatable,
    :lockable,
    :timeoutable,
    :trackable
end
