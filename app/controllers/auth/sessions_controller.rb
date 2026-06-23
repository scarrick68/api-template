module Auth
  class SessionsController < DeviseTokenAuth::SessionsController
    include Auth::NullSessionForgery
  end
end
