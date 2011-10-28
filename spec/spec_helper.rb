# encoding: utf-8
require 'rubygems'
require 'bundler/setup'
require 'redrack-session'
require 'rspec'

#
# Load all support files...
#
Dir[File.join(File.expand_path("..", __FILE__), "support", "**", "*.rb")].each { |f| require f }

#
# Configure RSpec to include Rack::Test methods and to always provide easy
# access to an instance of our test rack app, wrapped with the middleware we're
# testing (Redrack::Session::Middleware) and Rack::Lint.
#
RSpec.configure do |config|
  require 'rack/test'
  config.include Rack::Test::Methods
  def app
    Redrack::Session::RackApp.app
  end
end
