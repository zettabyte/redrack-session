# encoding: utf-8
require File.expand_path("../../spec_helper", __FILE__)

module Redrack
  describe Session do

    it "faults on no connection" do
      expect { app(:redis_host => "nosuchserver") }.to raise_error(SocketError)
    end

    it "connects to existing server" do
      expect { app() }.to_not raise_error
    end

    it "passes options to Redis" do
      main_app = Redrack::Session::Middleware.new(Redrack::Session::RackApp.new, :redis_namespace => "test:rack:session")
      main_app.redis.namespace.should == "test:rack:session"
    end

    it "creates a new cookie" do
      get "/"
      rack_mock_session.cookie_jar["rack.session"].should be_a(String)
    end

    it "determines session from a cookie" do
      get("/add") { |r| r.body.should match /Session Counter: 1/ }
      get("/add") { |r| r.body.should match /Session Counter: 2/ }
      get("/add") { |r| r.body.should match /Session Counter: 3/ }
    end

    it "determines session only from a cookie by default" do
      get "/add"
      sid = rack_mock_session.cookie_jar["rack.session"]
      clear_cookies
      get("/add", "rack.session" => sid) { |r| r.body.should match /Session Counter: 1/ }
      sid = rack_mock_session.cookie_jar["rack.session"]
      clear_cookies
      get("/add", "rack.session" => sid) { |r| r.body.should match /Session Counter: 1/ }
    end

    it "determines session from params" do
      mock_session = Rack::MockSession.new(app(:cookie_only => false))
      session      = Rack::Test::Session.new(mock_session)
      session.get "/add"
      sid = mock_session.cookie_jar["rack.session"]
      session.clear_cookies
      session.get("/add", "rack.session" => sid) { |r| r.body.should match /Session Counter: 2/ }
      session.get("/add", "rack.session" => sid) { |r| r.body.should match /Session Counter: 3/ }
    end

    it "survives nonexistant cookies" do
      rack_mock_session.set_cookie("rack.session=badsessionid")
      get("/add") { |r| r.body.should match /Session Counter: 1/ }
      rack_mock_session.cookie_jar["rack.session"].should_not match /badsessionid/
    end

    it "maintains freshness" do
      mock_session = Rack::MockSession.new(app(:expire_after => 3))
      session      = Rack::Test::Session.new(mock_session)
      session.get("/add") { |r| r.body.should match /Session Counter: 1/ }
      sid = mock_session.cookie_jar["rack.session"]
      session.get("/add") { |r| r.body.should match /Session Counter: 2/ }
      mock_session.cookie_jar["rack.session"].should == sid
      puts "Sleeping to expire session..." if $DEBUG
      sleep 5
      session.get("/add") { |r| r.body.should match /Session Counter: 1/ }
      mock_session.cookie_jar["rack.session"].should_not == sid
    end

    it "does not send the same session id if it did not change" do
      get("/add") { |r| r.body.should match /Session Counter: 1/ }
      sid = rack_mock_session.cookie_jar["rack.session"]
      get("/add") do |r|
        r.headers["Set-Cookie"].should be_nil
        r.body.should match /Session Counter: 2/
      end
      get("/add") do |r|
        r.headers["Set-Cookie"].should be_nil
        r.body.should match /Session Counter: 3/
      end
    end

    it "deletes cookies with :drop option" do
      main_mock_session = Rack::MockSession.new(app())
      drop_mock_session = Rack::MockSession.new(drop_app())
      main_session      = Rack::Test::Session.new(main_mock_session)
      drop_session      = Rack::Test::Session.new(drop_mock_session)
      main_session.get("/add") { |r| r.body.should match /Session Counter: 1/ }
      sid = main_mock_session.cookie_jar["rack.session"]
      drop_mock_session.set_cookie("rack.session=#{sid}")
      drop_session.get("/add") do |r|
        r.header["Set-Cookie"].should be_nil
        r.body.should match /Session Counter: 2/
      end
      main_session.get("/add") { |r| r.body.should match /Session Counter: 1/ }
      main_mock_session.cookie_jar["rack.session"].should_not == sid
    end

    it "provides new session id with :renew option" do
      main_mock_session  = Rack::MockSession.new(app())
      renew_mock_session = Rack::MockSession.new(renew_app())
      main_session       = Rack::Test::Session.new(main_mock_session)
      renew_session      = Rack::Test::Session.new(renew_mock_session)
      main_session.get("/add")  { |r| r.body.should match /Session Counter: 1/ }
      old_sid = main_mock_session.cookie_jar["rack.session"]
      renew_mock_session.set_cookie("rack.session=#{old_sid}")
      renew_session.get("/add") { |r| r.body.should match /Session Counter: 2/ }
      new_sid = renew_mock_session.cookie_jar["rack.session"]
      new_sid.should_not == old_sid
      main_mock_session.clear_cookies
      main_mock_session.set_cookie("rack.session=#{new_sid}")
      main_session.get("/add") { |r| r.body.should match /Session Counter: 3/ }
      main_mock_session.clear_cookies
      main_mock_session.set_cookie("rack.session=#{old_sid}")
      main_session.get("/add") { |r| r.body.should match /Session Counter: 1/ }
    end

    it "omits cookie with :defer option" do
      mock_session = Rack::MockSession.new(defer_app())
      session      = Rack::Test::Session.new(mock_session)
      session.get("/add") { |r| r.body.should match /Session Counter: 1/ }
      mock_session.cookie_jar["rack.session"].should be_nil
    end

    it "updates deep hashes correctly" do
      main_app     = Redrack::Session::Middleware.new(Redrack::Session::RackApp.new)
      mock_session = Rack::MockSession.new(main_app)
      session      = Rack::Test::Session.new(mock_session)
      session.get("/set-deep-hash")
      sid    = mock_session.cookie_jar["rack.session"]
      first  = main_app.redis.get(sid)
      session.get("/mutate-deep-hash")
      first.should_not equal(main_app.redis.get(sid))
    end

    it "cleanly merges sessions when multithreaded" do
      main_app            = Redrack::Session::Middleware.new(Redrack::Session::RackApp.new)
      main_mock_session   = Rack::MockSession.new(main_app)
      thread_mock_session = Rack::MockSession.new(threaded_app())
      main_session        = Rack::Test::Session.new(main_mock_session)
      thread_session      = Rack::Test::Session.new(thread_mock_session)
      num_threads         = lambda { rand(7).to_i + 5 }
      main_session.get("/add") { |r| r.body.should match /Session Counter: 1/ }
      sid = main_mock_session.cookie_jar["rack.session"]
      thread_mock_session.set_cookie("rack.session=#{sid}")

      # do several, multi-threaded requests...
      threads  = num_threads.call
      requests = Array.new(threads) do
        Thread.new(thread_session, thread_mock_session) do |session, mock|
          session.get("/add", {}, "rack.multithreaded" => true)
          [mock.last_response.body, mock.cookie_jar["rack.session"]]
        end
      end.reverse.map { |t| t.run.join.value }
      requests.each do |response|
        response.first.should match /Session Counter: 2/ # the response body
        response.last.should == sid                      # the session ID (cookie value)
      end

      # verify all our timestamps were written by the threaded_app
      session = Marshal.dump(main_app.redis.get(sid))
      session.size.should       == threads + 1
      session["counter"].should == 2
    end

  end
end
