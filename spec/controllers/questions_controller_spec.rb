require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe QuestionsController do

  def mock_question(stubs={})
    stubs.reverse_merge!(:valid? => true)
    @mock_question ||= mock_model(Question, stubs)
  end

  describe "GET index" do
    it "assigns all questions as @questions" do
      sign_in_as_admin
      Question.stub!(:find).with(:all).and_return([mock_question])
      get :index
      assigns[:questions].should == [mock_question]
    end
  end

  describe "GET new" do
    it "assigns a new question as @question" do
      Question.stub!(:new).and_return(mock_question)
      get :new
      assigns[:question].should equal(mock_question)
    end
  end

  describe "POST create" do

    describe "with valid params" do
      it "assigns a newly created question as @question" do
        expected_params = { 'name' => 'question', 'ideas' => 'ideas', 'url' => 'url' }
        Question.stub!(:new).with(hash_including(expected_params)).and_return(mock_question)
        post :create, :question => expected_params
        assigns[:question].should equal(mock_question)
      end

      it "ignores any param that's not name, ideas or url" do
        params = { 'name' => 'question', 'ideas' => 'ideas', 'url' => 'url',
                   'email' => 'email', 'password' => 'password' }
        expected_params = params.slice('email', 'password')
        Question.stub!(:new).and_return(mock_question)
        Question.should_not_receive(:new).with(hash_including(expected_params))
        post :create, :question => params
      end

      it "creates and sign in as a new user if not signed in" do
        post :create, :question => { :email => 'some@email.com', :password => 'password' }

        controller.current_user.should == assigns[:user]
        assigns[:user].should_not be_new_record
        assigns[:user].email.should == 'some@email.com'
        assigns[:user].password.should == 'password'
      end

      it "doesn't create a new user if already signed in" do
        sign_in
        params = { :email => 'email', :password => 'password' }
        expected_params = params.merge(:password_confirmation => 'password')
        Question.stub!(:new).and_return(mock_question(:valid? => false))
        User.should_not_receive(:new)

        post :create, :question => params
      end

      it "creates a new earl and add the newly created question to it" do
        user = Factory(:user)
        sign_in_as user

        post :create, :question => {'name' => 'music question', 'ideas' => 'idea', 'url' => 'music'}

        user.earls.last.question.name.should == 'music question'
      end

      it "flashes a message with links to the newly created earl's page, and question's admin page" do
        sign_in_as_admin
        Question.stub!(:new).and_return(mock_question(:save => true, :attributes => {}))
        post :create, :question => {'url' => 'music'}
        session[:standard_flash].should match(/.*#{earl_url('music')}.*#{admin_question_url('music')}/)
      end

      it "redirects to the created earl" do
        sign_in_as_admin
        Question.stub!(:new).and_return(mock_question(:save => true, :attributes => {}))
        post :create, :question => {'url' => 'music'}
        response.should redirect_to(earl_url('music', :just_created => true))
      end

      it "assigns the current user as the question's creator" do
        sign_in
        post :create, :question => {}
        assigns[:question].creator_id.should == controller.current_user.id
      end
    end

    describe "with invalid params" do
      it "assigns a newly created but unsaved question as @question" do
        post :create, :question => {'name' => 'question'}
        assigns[:question].name.should == 'question'
      end

      it "re-renders the 'new' template" do
        Question.stub!(:new).and_return(mock_question(:save => false))
        post :create, :question => {}
        response.should render_template('new')
      end
    end

  end

  describe "PUT update" do
    before do
      sign_in_as_admin
      @earl = Factory(:earl)
      @earl.stub!(:question).and_return(mock_question)
      Earl.stub!(:find).with(@earl.id.to_s).and_return(@earl)
    end

    describe "with valid params" do
      it "updates the requested earl" do
        put :update, :id => @earl.id, :earl => {:welcome_message => 'some_message'}
        @earl.welcome_message.should == 'some_message'
      end

      it "assigns the requested question as @question" do
        put :update, :id => @earl.id, :earl => {}
        assigns[:question].should == @earl.question
      end

      it "redirects to the question's admin page" do
        put :update, :id => @earl.id, :earl => {}
        response.should redirect_to(admin_question_url(@earl.question))
      end
    end

    describe "with invalid params" do
      it "assigns the requested question as @question" do
        @earl.stub!(:update_attributes).and_return(false)
        put :update, :id => @earl.id, :earl => {}
        assigns[:question].should == @earl.question
      end

      it "redirects to the question's admin page" do
        @earl.stub!(:update_attributes).and_return(false)
        put :update, :id => @earl.id, :earl => {}
        response.should redirect_to(admin_question_url(@earl.question))
      end
    end

  end

end
