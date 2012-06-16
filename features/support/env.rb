# encoding: utf-8
$:.unshift File.expand_path("../../../lib", __FILE__)
require 'redrack-session'
require 'rack/test'
require 'rack/response'
require 'redis'

module RackApp

  def app(middleware = nil)
    result = lambda do |env|
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
    return result unless middleware
    [middleware].flatten.reverse.each { |m| result = m.new(result) }
    result
  end

  def redis_server(host, port)
    result = Redis.new :host => host, :port => port
    result.ping
    result
  end

end

World RackApp
World Rack::Test::Methods

