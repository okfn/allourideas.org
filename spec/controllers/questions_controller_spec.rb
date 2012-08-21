require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe QuestionsController do

  def mock_question(stubs={})
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
        question_params = { 'name' => 'question', 'ideas' => 'ideas', 'url' => 'url' }

        post :create, :question => question_params

        question_params.each_pair do |key, value|
          assigns[:question].send(key).should == value
        end
      end

      it "ignores any param that's not name, ideas or url" do
        params = { 'name' => 'question', 'ideas' => 'ideas', 'url' => 'url',
                   'email' => 'email', 'password' => 'password' }

        post :create, :question => params

        assigns[:question].attributes[:email].should be_nil
        assigns[:question].attributes[:password].should be_nil
      end

      it "creates and sign in as a new user if not signed in" do
        Question.stub!(:new).and_return(mock_question(:save => false, :valid? => true, :attributes => {}))
        post :create, :question => { :email => 'some@email.com', :password => 'password', :url => 'url', :ideas => 'ideas' }

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
        question = Factory(:earl).question
        Question.stub!(:new).and_return(question)
        post :create, :question => {'url' => 'music'}
        session[:standard_flash].should match(/.*#{earl_url('music')}.*#{admin_question_path(question)}/)
      end

      it "redirects to the created earl" do
        sign_in_as_admin
        question = Factory(:earl).question
        Question.stub!(:new).and_return(question)
        post :create, :question => {'url' => 'music'}
        response.should redirect_to(earl_url('music', :just_created => true))
      end
    end

    describe "with invalid params" do
      it "assigns a newly created but unsaved question as @question" do
        post :create, :question => {'name' => 'question', 'url' => 'url'}
        assigns[:question].name.should == 'question'
      end

      it "re-renders the 'new' template" do
        Question.stub!(:new).and_return(mock_question(:save => false, :valid? => true))
        post :create, :question => {}
        response.should render_template('new')
      end
    end

  end

  describe "PUT update" do
    before do
      sign_in_as_admin
      @earl = Factory(:earl)
      @question = @earl.question
    end

    describe "with valid params" do
      it "updates the requested question's earl" do
        put :update, :id => @earl.id, :earl => {:welcome_message => 'some_message'}
        @earl.reload.welcome_message.should == 'some_message'
      end

      it "assigns the requested question as @question" do
        put :update, :id => @earl.id, :earl => {}
        assigns[:question].should == @question
      end

      it "redirects to the question's admin page" do
        put :update, :id => @earl.id, :earl => {}
        response.should redirect_to(admin_question_url(@question))
      end
    end

    describe "with invalid params" do
      before do
        Question.stub!(:find).and_return(@question)
        @question.stub!(:earl).and_return(@earl)
        @earl.stub(:update_attributes!).and_return(false)
      end

      it "assigns the requested question as @question" do
        put :update, :id => @earl.id, :earl => {}
        assigns[:question].should == @question
      end

      it "redirects to the question's admin page" do
        put :update, :id => @earl.id, :earl => {}
        response.should redirect_to(admin_question_url(@question))
      end
    end

  end

  describe "GET admin" do
    it "assigns the requested question as @question, and its earl as @earl" do
      earl = Factory(:earl)
      sign_in_as earl.user
      question = earl.question

      get :admin, :id => earl.id

      assigns[:question].should == question
      assigns[:earl].should == earl
    end

    it "redirects to the earl's url and flash a notice if the user is unauthorized" do
      sign_in
      earl = Factory(:earl)

      get :admin, :id => earl.id

      response.should redirect_to(earl_url(earl))
      flash[:notice].should_not be_nil
    end

  end

  describe "POST toggle" do
    it "should deactivate the earl, if the question was active" do
      earl = Factory(:earl, :active => true)
      sign_in_as earl.user
      post :toggle, :format => 'js', :id => earl.id

      JSON.parse(response.body).should == {"message" => "You've just deactivated your question", "verb" => "Deactivated"}
      earl.reload.should_not be_active
    end

    it "should activate the question, if it was inactive" do
      earl = Factory(:earl, :active => false)
      sign_in_as earl.user
      post :toggle, :format => 'js', :id => earl.id

      JSON.parse(response.body).should == {"message" => "You've just activated your question", "verb" => "Activated"}
      earl.reload.should be_active
    end
  end

end
