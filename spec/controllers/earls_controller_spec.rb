require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe EarlsController do
  describe "GET show" do
    it "assigns the earl scoped by consultation" do
      other_earl = Factory(:earl)
      earl = Factory(:earl, :name => other_earl.name)

      get :show, :consultation_id => earl.consultation_id, :id => earl.slug.name

      assigns[:earl].should == earl
    end
  end
end
