require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe User do

  describe "find_or_create_from_facebook" do
    it "should create a new user" do
      unique_email = Factory.build(:user).email
      user = User.find_or_create_from_facebook(unique_email, 123)

      user.email.should == unique_email
      user.facebook_id.should == 123
    end

    it "should save the user even without password" do
      user = User.find_or_create_from_facebook('a@b.com', 123)

      user.password.should be_nil
      user.should_not be_new_record
    end

    it "should update user's facebook id if there's one user with the same email" do
      user = Factory(:user)
      User.find_or_create_from_facebook(user.email, 123)

      user.reload.facebook_id.should == 123
    end
  end

end
