require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe User do

  describe "find_or_create_from_facebook" do
    it "should create a new user" do
      unique_email = Factory.build(:user).email
      user = User.find_or_create_from_facebook(unique_email, 123, 'abc')

      user.email.should == unique_email
      user.facebook_id.should == 123
      user.facebook_oauth_token.should == 'abc'
      user.password.should_not be_nil
    end

    it "should update user's facebook id and oauth token if there's one user with the same email" do
      user = Factory(:user)
      User.find_or_create_from_facebook(user.email, 123, 'abc')

      user.reload
      user.facebook_id.should == 123
      user.facebook_oauth_token.should == 'abc'
    end

    it "should not change the user's password if it's existing" do
      user = Factory(:user)
      encrypted_password = user.encrypted_password

      User.find_or_create_from_facebook(user.email, 123, 'abc')

      user.reload.encrypted_password.should == encrypted_password
    end
  end

end
