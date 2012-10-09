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

  describe "PUT update" do
    before do
      sign_in_as_admin
      @earl = Factory(:earl)
      @question = @earl.question
    end

    describe "with valid params" do
      it "updates the requested question's earl" do
        put :update, :id => @question.id, :earl => {:welcome_message => 'some_message'}
        @earl.reload.welcome_message.should == 'some_message'
      end

      it "assigns the requested question as @question" do
        put :update, :id => @question.id, :earl => {}
        assigns[:question].should == @question
      end

      it "redirects to the question's admin page" do
        put :update, :id => @question.id, :earl => {}
        response.should redirect_to(admin_question_url(@question))
      end
    end

    describe "with invalid params" do
      before do
        Question.stub!(:find).and_return(@question)
        @question.stub!(:earl).and_return(@earl)
        @earl.stub(:update_attributes).and_return(false)
      end

      it "assigns the requested question as @question" do
        put :update, :id => @question.id, :earl => {}
        assigns[:question].should == @question
      end

      it "redirects to the question's admin page" do
        put :update, :id => @question.id, :earl => {}
        response.should redirect_to(admin_question_url(@question))
      end
    end

  end

  describe "GET admin" do
    it "assigns the requested question as @question, and its earl as @earl" do
      earl = Factory(:earl)
      sign_in_as earl.user
      question = earl.question

      get :admin, :id => question.id

      assigns[:question].should == question
      assigns[:earl].should == earl
    end

    it "redirects to the earl's url and flash a notice if the user is unauthorized" do
      sign_in
      earl = Factory(:earl)

      get :admin, :id => earl.question.id

      response.should redirect_to(consultation_earl_url(earl.consultation, earl))
      flash[:notice].should_not be_nil
    end

  end

  describe "GET add_idea" do
    it "should require the user to be signed in" do
      sign_out

      post :add_idea, :id => :question_id

      response.should redirect_to(new_session_url)
    end

    it "should publish into the user's facebook" do
      sign_in
      earl = Factory(:earl)
      Choice.any_instance.stubs(:create).returns(Choice.new)

      message = I18n.t('facebook.idea_creation_sharing_message')
      controller.should_receive(:publish_into_facebook).with(controller.current_user, message)

      post :add_idea, :id => earl.question.id
    end
  end

  describe "POST toggle" do
    it "should deactivate the earl, if the question was active" do
      consultation = Factory.build(:consultation_without_earls, :active => true)
      earl = Factory(:earl, :consultation => consultation, :active => true)
      sign_in_as earl.user
      post :toggle, :format => 'js', :id => earl.question_id

      JSON.parse(response.body).should == {"message" => "You've just deactivated your question", "verb" => "Deactivated"}
      earl.reload.should_not be_active
    end

    it "should activate the earl, if it was inactive" do
      consultation = Factory.build(:consultation_without_earls, :active => true)
      earl = Factory(:earl, :consultation => consultation, :active => false)
      sign_in_as earl.user
      post :toggle, :format => 'js', :id => earl.question_id

      JSON.parse(response.body).should == {"message" => "You've just activated your question", "verb" => "Activated"}
      earl.reload.should be_active
    end

    it "should activate the earl's consultation, if it was inactive" do
      consultation = Factory.build(:consultation_without_earls, :active => false)
      earl = Factory(:earl, :consultation => consultation)
      sign_in_as earl.user
      post :toggle, :format => 'js', :id => earl.question_id

      consultation.reload.should be_active
    end
  end

end
