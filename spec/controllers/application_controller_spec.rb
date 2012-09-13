require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe ApplicationController do

  describe "white_label_request" do
    it "returns true if received white_label param" do
      controller.params[:white_label] = 'anything'
      controller.session[:white_label] = false
      controller.stub!(:facebook_request?).and_return(false)

      controller.should be_white_label_request
    end

    it "returns true if the white_label cookie is true" do
      controller.params.delete(:white_label)
      controller.session[:white_label] = true
      controller.stub!(:facebook_request?).and_return(false)

      controller.should be_white_label_request
    end

    it "returns true if coming from facebook" do
      controller.params.delete(:white_label)
      controller.session[:white_label] = false
      controller.stub!(:facebook_request?).and_return(true)

      controller.should be_white_label_request
    end

    it "returns false if haven't received the white_label param, the white_label cookie is false, and isn't coming from facebook" do
      controller.params.delete(:white_label)
      controller.session[:white_label] = false
      controller.stub!(:facebook_request?).and_return(false)

      controller.should_not be_white_label_request
    end
  end

end
