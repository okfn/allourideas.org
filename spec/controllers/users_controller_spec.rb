require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe UsersController do

  describe "POST create" do
    it "creates a new user with the passed email" do
      email = Factory.build(:user).email

      lambda {
        post :create, :user => { :email => email, :password => 'pass' }
      }.should change(User, :count).by(1)

      created_user = User.last
      created_user.email.should == email
    end

    it "sign in as the user" do
      user = User.new
      user.stub!(:save).and_return(true)
      User.stub!(:new).and_return(user)

      controller.should_receive(:sign_in).with(user)

      post :create
    end

    it "redirects to the callback url, if received one" do
      user = double('user').as_null_object
      user.stub!(:save).and_return(true)
      User.stub!(:new).and_return(user)

      post :create, :callback => 'http://callback_url'

      controller.should redirect_to 'http://callback_url'
    end

    it "redirects to the root url, if haven't received a callback" do
      user = double('user').as_null_object
      user.stub!(:save).and_return(true)
      User.stub!(:new).and_return(user)

      post :create

      controller.should redirect_to root_url
    end

    it "renders the new template if couldn't save the user" do
      user = double('user').as_null_object
      user.stub!(:save).and_return(false)
      User.stub!(:new).and_return(user)

      post :create

      controller.should render_template('users/new')
    end
  end

end
