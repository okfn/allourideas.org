class FacebookCanvas
  def initialize(app)
    @app = app
  end

  def call(env)
    env['REQUEST_METHOD'] = 'GET' if env['HTTP_ORIGIN'] =~ /\.facebook\.com/

    @app.call(env)
  end
end
