module ApiAuthHelpers
  AUTH_TOKEN_HEADERS = [ "access-token", "client", "uid", "expiry", "token-type" ].freeze

  def auth_headers_for(user)
    user.create_new_auth_token
  end

  def sign_in_headers_for(user, password: "password123")
    post "/auth/sign_in",
      params: { email: user.email, password: password },
      as: :json

    assert_response :success

    response.headers.slice(*AUTH_TOKEN_HEADERS)
  end
end
