# encoding: utf-8
module Redrack

  #
  # This is a namespacing module. Use Redrack::Session::Middleware for your redis session
  # storage needs in your rack app.
  #
  #   myapp = MyRackApp.new
  #   sessioned = Redrack::Session::Middleware.new(myapp, :redis_host => "redis.example.tld", ...)
  #
  module Session
    autoload :VERSION,    'redrack/session/version'
    autoload :Middleware, 'redrack/session/middleware'
  end
end
