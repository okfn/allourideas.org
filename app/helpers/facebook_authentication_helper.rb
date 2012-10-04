module FacebookAuthenticationHelper

  def authenticate_with_facebook
    authenticate_facebook or authenticate_without_facebook
  end

  def authenticate_facebook
    sign_in_facebook or redirect_to(facebook_authorization_url) if facebook_request?
  end

  def sign_in_facebook
    sign_in(facebook_user) if authorized_in_facebook?
  end

  private
  def facebook_authorization_url
    Koala::Facebook::OAuth.new.url_for_oauth_code(:permissions => 'email',
                                                  :callback => "#{facebook_host_url}/#{request.path}")
  end

  def facebook_request?
    params.include?('signed_request')
  end

  def facebook_host_url
    "https://apps.facebook.com/#{Facebook::APP_NAMESPACE}"
  end

  def authorized_in_facebook?
    signed_request.include?('oauth_token') if facebook_request?
  end

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
