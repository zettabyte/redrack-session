# encoding: utf-8
require 'rack/session/abstract/id'
require 'redis'
require 'redis-namespace'

module Redrack
  module Session
    class Middleware < Rack::Session::Abstract::ID

      attr_reader :redis # provide raw access to redis database (for testing)

      # redis-specific default options (following the Abstract::ID pattern)
      DEFAULT_OPTIONS = Rack::Session::Abstract::ID::DEFAULT_OPTIONS.merge(
        :redis_password  =>  nil,        # optional authentication password for redis server
        :redis_namespace =>  nil,        # optional namespace under which session keys are stored
        :redis_path      =>  nil,        # specify this if connecting to redis server via socket
        :redis_host      => "127.0.0.1", # hostname or IP of redis database server
        :redis_port      =>  6379,       # port to connect to redis database server
        :redis_database  =>     0,       # default redis database to hold sessions
        :redis_timeout   =>     5        # default redis connection timeout (seconds)
        )

      def initialize(app, options = {})
        super
        @mutex = Mutex.new

        # process redis-specific options
        if @default_options[:redis_path].is_a?(String)
          redis_options = { :path => @default_options[:redis_path] }
        else
          redis_options = {
            :host => (@default_options[:redis_host] || "127.0.0.1"),
            :port => (@default_options[:redis_port] ||  6379)
          }
        end
        redis_options[:db]       = @default_options[:redis_database] || 0
        redis_options[:timeout]  = @default_options[:redis_timeout]  || 5
        redis_options[:password] = @default_options[:redis_password] if @default_options[:redis_password].is_a?(String)

        # create connection to our redis database and ensure we're connected
        @redis = ::Redis.new(redis_options.merge(:thread_safe => true))
        @redis.ping

        # store session keys under specified namespace (if any)
        if @default_options[:redis_namespace]
          @redis = ::Redis::Namespace.new(@default_options[:redis_namespace], :redis => @redis)
        end
      end

      private
      def generate_sid
        # Atomically test if sid available and reserve it if it is
        sid = super # first iteration
        sid = super until @redis.setnx(sid, Marshal.dump({}))
        # Set our allocated sid to expire if it isn't used any time soon
        expiry = (@default_options[:expire_after] || 0).to_i
        @redis.expire(sid, expiry <= 0 ? 600 : expiry)
        sid
      end

      def get_session(env, sid)
        with_lock(env, [nil, {}]) do
          if sid and @redis.exists(sid)
            session = Marshal.load(@redis.get(sid))
          else
            sid, session = generate_sid, {}
          end
          [sid, session]
        end
      end

      def set_session(env, session_id, new_session, options)
        expiry = options[:expire_after]
        expiry = expiry.nil? ? 0 : expiry + 1

        with_lock(env, false) do
          @redis.del(session_id)
          @redis.set(session_id, Marshal.dump(new_session.to_hash))
          @redis.expire(session_id, expiry) if expiry > 0
          session_id
        end
      end

      def destroy_session(env, session_id, options)
        with_lock(env) do
          @redis.del(session_id)
          generate_sid unless options[:drop]
        end
      end

      def with_lock(env, default = nil)
        @mutex.lock if env["rack.multithread"]
        yield
      rescue
        default
      ensure
        @mutex.unlock if @mutex.locked?
      end

    end
  end
end
