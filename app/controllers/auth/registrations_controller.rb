module Auth
  class RegistrationsController < DeviseTokenAuth::RegistrationsController
    include Auth::NullSessionForgery
  end
end
