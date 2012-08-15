module AuthenticationHelpers
  def sign_in
    sign_in_as Factory(:user)
  end

  def sign_in_as_admin
    sign_in_as Factory(:admin)
  end

  def sign_in_as(user)
    controller.current_user = user
  end
end

