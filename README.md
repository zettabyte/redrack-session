## redrack-session

Redis session store for rack applications.

This provides browser sessions for your rack application, storing a unique
session ID in a cookie in the client's browser and the session data in a redis
server.

### Usage

This gem may be used in much the same way as you might use the
`Rack::Session::Memcached` middleware provided by the rack gem, or any other
rack session middleware for that matter. Just add it to your rack middleware
stack and then you can read and write objects to the hash provided in
`env["rack.session"]`.

### To Do

- Flush out this README and improvide inline code documentation
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
