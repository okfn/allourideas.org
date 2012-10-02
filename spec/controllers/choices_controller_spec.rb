require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe ChoicesController do

  def mock_choice(attributes={})
    default_attributes = {:id => 42}.merge(attributes)
    double("choice", default_attributes).as_null_object
  end

  describe "PUT update" do
    it "should deny access if the user is not authorized" do
      controller.class.send(:alias_method, :deny_access_original, :deny_access)
      controller.should_receive(:deny_access) { controller.deny_access_original }

      put :update, :id => :choice_id, :question_id => Factory(:earl).question_id
    end

    it "updates data and saves choice" do
      sign_in_as_admin
      choice = mock
      Earl.stub!(:find_by_question_id).and_return(mock.as_null_object)
      Question.stub!(:find).and_return(mock.as_null_object)
      Choice.stub!(:find).and_return(choice)

      choice.expects(:data=).with(:new_name)
      choice.expects(:related_choice_id=).with(:related_choice_id)
      choice.expects(:question_id=).with(:new_question_id)
      choice.expects(:save)

      put :update, :id => :choice_id, :question_id => :question_id,
                   :choice => { :data => :new_name, :related_choice_id => :related_choice_id,
                                :question_id => :new_question_id }
    end

    it "redirects to choice's question admin page" do
      sign_in_as_admin
      earl = Factory(:earl)
      Earl.stub!(:find_by_question_id).with(:question_id).and_return(earl)
      Choice.stub!(:find).and_return(mock.as_null_object)

      put :update, :id => :choice_id, :question_id => :question_id

      response.should redirect_to admin_question_url(:question_id)
    end
  end

  describe "GET show" do
    it "loads the choice with all versions" do
      question = double("question", :id => 42).as_null_object
      Question.stub!(:find).and_return(question)

      expected_params = [:choice_id, {:params => hash_including({:version => 'all'})}]
      Choice.should_receive(:find).with(*expected_params).and_return(mock_choice)
      Choice.stub!(:find).and_return([mock_choice])

      get :show, :id => :choice_id, :question_id => question.id, :locale => 'en'
    end

    it "assigns all question's choices but the current one to choices" do
      question = double("question", :id => 42).as_null_object
      Question.stub!(:find).and_return(question)
      choice = mock_choice(:id => 1)
      other_choice = mock_choice(:id => 2)

      expected_params = [:choice_id, {:params => hash_including({:version => 'all'})}]
      Choice.should_receive(:find).with(*expected_params).and_return(choice)
      Choice.stub!(:find).and_return([choice, other_choice])

      get :show, :id => :choice_id, :question_id => question.id, :locale => 'en'
      assigns[:choices].should_not include(choice)
    end

    describe "can edit" do
      before do
        @earl = Factory(:earl)
        @choice = mock_choice(:id => :choice_id)
        Choice.stub!(:find).with(@choice.id, anything()).and_return(@choice)
        Choice.stub!(:find).with(:all, anything()).and_return([@choice])
      end

      it "is true if the user is admin" do
        sign_in_as_admin

        get :show, :question_id => @earl.question_id, :id => @choice.id

        assigns[:can_edit].should be_true
      end

      it "is true if the user is signed in and owns the question's earl" do
        sign_in_as @earl.user

        get :show, :question_id => @earl.question_id, :id => @choice.id

        assigns[:can_edit].should be_true
      end

      it "is false if the user don't owns the question's earl" do
        sign_in

        get :show, :question_id => @earl.question_id, :id => @choice.id

        assigns[:can_edit].should be_false
      end

      it "is false if the user isn't signed in" do
        sign_out

        get :show, :question_id => @earl.question_id, :id => @choice.id

        assigns[:can_edit].should be_false
      end

    end
  end

end
