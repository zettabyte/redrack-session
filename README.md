## redrack-session

Redis session store for rack applications.

This provides browser sessions for your rack application, storing a unique
session ID in a cookie in the client's browser and the session data in a redis
server.

If you want to use this gem in a rails app, check out
[redrails-session](https://github.com/zettabyte/redrails-session) for an
easy-to-use wrapper.

### Usage

This gem may be used in much the same way as you might use the
`Rack::Session::Memcached` middleware provided by the rack gem, or any other
rack session middleware for that matter. Just create an instance of the
`Redrack::Session::Middleware` class and add it to your rack middleware stack
and then you can read and write objects to the hash provided in
`env["rack.session"]`.

#### Supported Options

When instantiating an instance of the `Redrack::Session::Middleware` class, you
can provide any/all of the same options supported by the generic
`Rack::Session::Cookie` or `Rack::Session::Pool` session stores. You may
additionally specify the following options:

- `:redis_host` -- specify IP address or hostname of host running the redis service (default: `'127.0.0.1'`)
- `:redis_port` -- specify port that the redis service is listening on (default: `6379`)
- `:redis_path` -- alternatively specify filename of socket that redis server is listening on (default: `nil`)
- `:redis_database` -- specify which database number to store session data in (default: `0`)
- `:redis_timeout` -- specify maximum number of seconds to wait before connection times out (default: `5`)
- `:redis_namespace` -- optionally specify a string to prefix to all session keys in case you're storing other datasets in the redis database (default: `nil`)
- `:redis_password` -- optionally specify a string to use to authenticate with the server (default: `nil`)

Some examples of the configuration options also supported in common with
`Rack::Session::Cookie` include:

- `:key` -- specify name of cookie stored on client's browser (default: ``rack.session'`)
- `:expire_after` -- specify how long, in seconds, to persist inactive sessions (default: `nil` meaning never expire)
- `:path` -- cookie's `:path` option (default: `'/'`)
- `:domain` -- cookie's `:domain` option
- `:secure` -- cookie's `:secure` option
- `:httponly` -- cookie's `:httponly` option

#### Example: rackup (config.ru) style rack application

If you've got a rack stack for a rack application configured using a `rackup`
style `config.ru`, you can use `redrack-session` in a manner similar to this
example rack application:

- `./Gemfile` -- I'm using bundler in this simple example
- `./config.ru` -- This configures the rack stack
- `./lib/rackapp.rb` -- Contains code for the example rack app

```ruby
# Gemfile
source :rubygems
gem 'rack'
gem 'redrack-session'
```

```ruby
# config.ru
require 'rubygems'
require 'bundler/setup'
$:.push File.expand_path("../lib", __FILE__)
require 'rackapp'

use Rack::ShowExceptions
use Rack::Lint
use Redrack::Session::Middleware
run Rackapp.new
```

```ruby
# lib/rackapp.rb
require 'redrack-session'
require 'rack/request'
require 'rack/response'

class Rackapp
  def call(env)
    request = Rack::Request.new(env)
    session = env["rack.session"]
    session["counter"] ||= 0
    session["counter"]  += 1
    session["history"] ||= []
    session["history"]  << request.path
    Rack::Response.new do |response|
      response.write "<!DOCTYPE html>\n<html><head><title>Rackapp</title></head>\n<body><pre>\n"
      response.write "Counter: #{session['counter']}\n"
      response.write "History:\n" + session["history"].map { |h| "  - #{h}" }.join("\n")
      response.write "\n</pre></body></html>\n"
    end.finish
  end
end
```

Once the files are in place and the `bundler` gem is installed, you can then
complete setup and run the example rack app by doing the following:

```bash
user@host:~/projects/rackapp$ bundle install
user@host:~/projects/rackapp$ bundle exec rackup
```

This will then run a WEBrick server on localhost port `9292`.

### TODO

The ultimate intent, starting with this gem, is develop several `redrack-*` gems
for storing various datasets in redis, including cache, i18n (translation), and
throttling information (black, white, and grey lists and abuse information).

Additionally I'd like to make equivalent `redrails-*` gems that essentially
provide the convenient packaging around their `redrack-*` namesakes for
integrating these gems into rails apps.

Finally, I'd like to create a master `redrack` and a `redrails` meta-gem that
depends on the full gamut and perhaps includes other conveniences (factory
methods, glue code) for the most common cases of usage.

#### Gems TODO:

- Create redrack-cache gem
- Create redrack-throttle gem
- Create redrack-localize gem
- Create redrack gem to package all of the above as single rack middleware
- Create redrails-session gem
- Create redrails-throttle gem
- Create redrails-localize gem
- Create redrails gem to package all of the redrails-* gems above, linking all redrack-* middleware into a rails app

### Credits and License

Though "authored" by myself (Kendall Gifford), this gem was heavily inspired by
by the `Rack::Session::Memcached` rack middleware included in the rack gem. The
RSpec tests were even more heavily inspired by the rack gem and are basically a
translation of the test cases in the rack codebase that test
`Rack::Session::Memcached`.

Licensed using the standard
[MIT License](http://en.wikipedia.org/wiki/MIT_License). See the file
[LICENSE](http://github.com/zettabyte/redrack-session/blob/master/LICENSE) in
the root folder of the project.
