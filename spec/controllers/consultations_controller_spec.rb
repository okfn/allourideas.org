require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe ConsultationsController do

  describe "GET show" do
    before { sign_in }

    it "redirects to login page if we're not logged in" do
      sign_out

      get :show, :id => :consultation_id

      response.should redirect_to(new_session_url)
    end

    it "assigns the requested consultation" do
      consultation = Factory(:consultation, :user => controller.current_user)

      get :show, :id => consultation.id

      assigns[:consultation].should == consultation
    end

    it "don't assign if the user's not allowed to" do
      consultation = Factory(:consultation)

      lambda {
        get :show, :id => consultation.id
      }.should raise_error(ActiveRecord::RecordNotFound)

      assigns[:consultation].should be_nil
    end
  end

  describe "GET new" do
    it "assigns a new consultation" do
      get :new

      assigns[:consultation].should be_an_instance_of(Consultation)
      assigns[:consultation].should be_new_record
    end

    it "builds a new user, if not signed in" do
      sign_out

      get :new

      user = assigns[:consultation].user
      user.should be_an_instance_of(User)
      user.should be_new_record
    end

    it "don't assign a new user, if signed in" do
      sign_in

      get :new

      assigns[:consultation].user.should == controller.current_user
    end
  end

  describe "POST create" do
    it "creates consultation" do
      lambda {
        post :create, :consultation => { :name => "Consultation" }
      }.should change(Consultation, :count).by(1)

      assigns[:consultation].name.should == "Consultation"
    end

    it "creates and assigns the consultation to a new user, if not signed id" do
      lambda {
        user_attributes = { :email => 'some@email.com', :password => 'password' }
        post :create, :consultation => { :name => "Consultation",
                                         :user_attributes => user_attributes }
      }.should change(User, :count).by(1)

      assigns[:consultation].user.email.should == 'some@email.com'
      controller.current_user.should == assigns[:consultation].user
    end

    it "assigns the consultation to the current user" do
      sign_in
      user = controller.current_user

      lambda {
        post :create, :consultation => { :name => "Consultation" }
      }.should change(user.consultations, :count).by(1)
    end

    it "redirects to consultation's show page" do
      post :create, :consultation => { :name => "Consultation" }

      response.should redirect_to(consultation_url(assigns[:consultation]))
    end

    it "renders new if couldn't save consultation" do
      post :create, :consultation => {}

      response.should render_template("consultations/new")
    end
  end

  describe "PUT update" do
    before { sign_in }

    it "redirects to login page if we're not logged in" do
      sign_out

      put :update, :id => :consultation_id

      response.should redirect_to(new_session_url)
    end

    it "updates the requested consultation" do
      consultation = Factory(:consultation, :user => controller.current_user)

      put :update, :id => consultation.id,
                   :consultation => { :name => "new name" }

      response.response_code.should == 200
      consultation.reload.name.should == "new name"
    end

    it "updates the requested consultation" do
      consultation = Factory(:consultation, :user => controller.current_user)

      put :update, :id => consultation.id,
                   :consultation => { :name => "" }

      response.response_code.should == 403
    end
  end

  describe "POST create_earl" do
    before do
      @current_user = sign_in
      @consultation = Factory(:consultation_without_earls, :user => @current_user)
    end

    it "assigns the consultation and earl" do
      post :create_earl, :id => @consultation.id, :earl => {}

      assigns[:consultation].should_not be_nil
      assigns[:earl].should_not be_nil
    end

    it "redirects to consultation url if successful" do
      post :create_earl, :id => @consultation.id, :earl => { :name => "Earl" }

      response.should redirect_to(consultation_url(@consultation))
    end

    it "renders consultation's show page if unsuccessful" do
      post :create_earl, :id => @consultation.id, :earl => {}

      response.should render_template("consultations/show")
    end

    it "creates a new earl and assign it to the consultation" do
      post :create_earl, :id => @consultation.id, :earl => { :name => "Earl" }

      @consultation.earls.should_not be_empty
      @consultation.earls.last.name.should == "Earl"
      @consultation.earls.last.user_id.should == @current_user.id
    end

    it "assigns the request session id as the question's visitor identifier" do
      question_attributes = { :ideas => "idea" }
      earl_attributes = { :name => "Earl",
                          :question_attributes => question_attributes }

      post :create_earl, :id => @consultation.id, :earl => earl_attributes

      earl = @consultation.earls.first
      earl.question.local_identifier.to_i.should == @current_user.id
    end
  end

end
