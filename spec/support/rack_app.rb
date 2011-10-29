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
        session["counter"] ||= 0 # Always at least initialize the session
        if request.path == "/add"
          session["counter"] += 1 # Add one to counter
        elsif request.path == "/set-deep-hash"
          session[:a] = :b
          session[:c] = { :d => :e }
          session[:f] = { :g => { :h => :i } }
        elsif request.path == "/mutate-deep-hash"
          session[:f][:g][:h] = :j
        elsif request.path == "/drop-counter"
          session.delete "counter"
          session["foo"] = "bar"
        end
        Rack::Response.new do |response|
          response.write "<!doctype html>\n<html>\n<head><title>Redrack::Session Test App</title></head>\n<body>\n<pre>"
          if session["counter"]
            response.write "Session Counter: #{session["counter"]}"
          elsif session["foo"]
            response.write "Session Foo: #{session["foo"]}"
          else
            response.write "Nothing"
          end
          response.write "\n</pre>\n</body>\n</html>\n"
        end.finish
      end

      #
      # Define helper class method that creates an instance of our simple rack
      # application with our session middleware available.
      #
      def self.app(options = {})
        Rack::Lint.new(Redrack::Session::Middleware.new(new, options))
      end

      #
      # Define helper class that gets an instance of our simple rack app wrapped
      # in a context that sets "rack.session.options" :drop setting to true.
      #
      def self.drop_app(options = {})
        main_app        = new()
        drop_middleware = proc { |env| env["rack.session.options"][:drop] = true; main_app.call(env) }
        Rack::Lint.new(Rack::Utils::Context.new(Redrack::Session::Middleware.new(main_app, options), drop_middleware))
      end

      #
      # Define helper class that gets an instance of our simple rack app wrapped
      # in a context that sets "rack.session.options" :renew setting to true.
      #
      def self.renew_app(options = {})
        main_app         = new()
        renew_middleware = proc { |env| env["rack.session.options"][:renew] = true; main_app.call(env) }
        Rack::Lint.new(Rack::Utils::Context.new(Redrack::Session::Middleware.new(main_app, options), renew_middleware))
      end

      #
      # Define helper class that gets an instance of our simple rack app wrapped
      # in a context that sets "rack.session.options" :defer setting to true.
      #
      def self.defer_app(options = {})
        main_app         = new()
        defer_middleware = proc { |env| env["rack.session.options"][:defer] = true; main_app.call(env) }
        Rack::Lint.new(Rack::Utils::Context.new(Redrack::Session::Middleware.new(main_app, options), defer_middleware))
      end

      #
      # Define helper class that gets an instance of our simple rack app wrapped
      # in a context that emulates the disconjoinment of multithreaded access.
      #
      def self.threaded_app(options = {})
        main_app            = new()
        threaded_middleware = proc do |env|
          env["rack.session"] = env["rack.session"].dup
          Thread.stop
          env["rack.session"][(Time.now.usec * rand).to_i] = true
          main_app.call(env)
        end
        Rack::Lint.new(Rack::Utils::Context.new(Redrack::Session::Middleware.new(main_app, options), threaded_middleware))
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
