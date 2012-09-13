module FacebookAuthenticationHelper

  def authenticate_facebook
    sign_in(facebook_user) if facebook_request?
  end

  def facebook_request?
    params.include?('signed_request')
  end

  private
  def facebook_user
    User.find_or_create_from_facebook(email_from_facebook, facebook_id)
  end

  def email_from_facebook
    facebook_user_data['email']
  end

  def facebook_id
    facebook_user_data['id']
  end

  def facebook_user_data
    @facebook_user_data ||= Koala::Facebook::API.new(signed_request['oauth_token']).get_object('me')
  end

  def signed_request
    @signed_request ||= Koala::Facebook::OAuth.new.parse_signed_request(params['signed_request'])
  end

end
