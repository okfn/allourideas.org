require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe FacebookAuthenticationHelper do
  def stub_facebook_oauth_with!(parsed_signed_request)
    oauth_mock = mock(:parse_signed_request => parsed_signed_request)
    Koala::Facebook::OAuth.stub!(:new).and_return(oauth_mock)
  end

  describe "authentication" do
    before do
      helper.class_eval do
        attr_accessor :current_user
      end
      params['signed_request'] = 'signed_request'

      @facebook_user_data = { 'email' => 'some@email.com', 'id' => 123 }
      api_mock = mock(:get_object => @facebook_user_data)
      Koala::Facebook::API.stub!(:new).and_return(api_mock)
    end

    it "should sign in as the user if the user has authorized the app" do
      stub_facebook_oauth_with!({ 'oauth_token' => 'oauth_token' })

      helper.should_receive(:sign_in) { |user| user }

      current_user = helper.authenticate_facebook

      current_user.should_not be_nil
      current_user.email.should == @facebook_user_data['email']
      current_user.facebook_id.should == @facebook_user_data['id']
      current_user.should_not be_new_record
    end

    it "should not try to sign in if the user has not authorized the app" do
      stub_facebook_oauth_with!({})

      helper.should_not_receive(:sign_in)

      helper.authenticate_facebook
    end
  end

  describe "facebook request" do
    it "should be true if there's a signed_request param" do
      params['signed_request'] = {}

      helper.facebook_request?.should be_true
    end

    it "should be false if there's no signed_request param" do
      params.delete('signed_request')

      helper.facebook_request?.should be_false
    end
  end
end
