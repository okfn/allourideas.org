require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe ApplicationController do

  describe "white_label_request" do
    it "returns true if white_label param is true" do
      controller.params[:white_label] = 'true'
      controller.stub!(:facebook_request?).and_return(false)

      controller.white_label_request?.should be_true
    end

    it "returns true if coming from facebook" do
      controller.params[:white_label] = 'false'
      controller.stub!(:facebook_request?).and_return(true)

      controller.white_label_request?.should be_true
    end

    it "returns false if haven't received the white_label param and is not coming from facebook" do
      controller.params[:white_label] = 'false'
      controller.stub!(:facebook_request?).and_return(false)

      controller.white_label_request?.should be_false
    end

    it "returns the value from white_label cookie" do
      controller.session[:white_label] = :some_value

      controller.white_label_request?.should == :some_value
    end
  end

end
