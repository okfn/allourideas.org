require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe FacebookCanvas do
  it "should change the request method to GET, if it comes from facebook" do
    app = lambda { |env| env['REQUEST_METHOD'].should == 'GET' }

    facebook_canvas = FacebookCanvas.new(app)
    facebook_canvas.call({ 'REQUEST_METHOD' => 'POST',
                           'HTTP_ORIGIN' => 'http://apps.facebook.com' })
  end

  it "should not change the request method, if it doesn't come from facebook" do
    app = lambda { |env| env['REQUEST_METHOD'].should == 'PUT' }

    facebook_canvas = FacebookCanvas.new(app)
    facebook_canvas.call({ 'REQUEST_METHOD' => 'PUT' })
  end
end
