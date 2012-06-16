# encoding: utf-8

Given /^a rack app that uses sessions$/ do
  app
end

Given /^a redis server at "([^:"]+):(\d+)"$/ do |host, port|
  @server = redis_server(host, port)
end

When /^I configure my rack app to use the redrack\-session middleware$/ do
  @app = app(Redrack::Session::Middleware)
end

Then /^my app's session data is stored in my redis database$/ do
  get "/"
  puts @server.get(rack_mock_session.cookie_jar["rack.session"])
end

