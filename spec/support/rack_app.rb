# encoding: utf-8
require 'redrack-session'

#
# Define simple rack application that expects to be used with the
# Redrack::Session middleware in an underlying layer for testing our middleware.
#
module Redrack
  module Session
    class RackApp

      #
      # Rack application definition
      #
      def call(env)
        request = Rack::Request.new(env)
        session = env["rack.session"]
        Rack::Response.new do |response|
          response.write "<!doctype html>\n<html>\n<head><title>Redrack::Session Test App</title></head>\n<body>\n<pre>"
          response.write "Session? #{!session.nil?}"
          response.write "\n</pre>\n</body>\n</html>\n"
        end.finish
      end

      #
      # Define helper class method that creates an instance of our simple rack
      # application with our session middleware available.
      #
      def self.app
        # Use redis defaults: server at 127.0.0.1:6379, using database #0, no namespace
        Rack::Lint.new(Redrack::Session::Middleware.new(new))
      end

    end
  end
end

#
# If "running" this file, then run an instance of Redrack::Session::RackApp in
# WEBrick. Got this "trick" from the Rack::Lobster example rack app.
#
if $0 == __FILE__
  require 'rack'

  # Exit when asked...
  %w{ HUP INT TERM }.each do |sig|
    trap(sig) do
      STDERR.puts "Recieved signal: #{sig}"
      Rack::Handler::WEBrick.shutdown
    end
  end

  # Run WEBrick server...
  Rack::Handler::WEBrick.run(
    Rack::ShowExceptions.new(Redrack::Session::RackApp.app),
    :Port => 3000 # use default rails development port
    )

end
