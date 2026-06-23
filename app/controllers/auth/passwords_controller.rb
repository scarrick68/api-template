module Auth
  class PasswordsController < DeviseTokenAuth::PasswordsController
    include Auth::NullSessionForgery
  end
end
