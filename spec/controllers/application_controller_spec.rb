require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe ApplicationController do

  describe "white_label_request?" do
    it "returns true if the request url includes whitelabel" do
      controller.request.host = 'whitelabel.allourideas.org'

      controller.should be_white_label_request
    end

    it "returns false if the request url doesn't include whitelabel" do
      controller.request.host = 'somethingelse.allourideas.org'

      controller.should_not be_white_label_request
    end
  end

end
