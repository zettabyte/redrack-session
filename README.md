## redrack-session

Redis session store for rack applications.

TODO:

- Fix failing spec issue with nested session hash keys only accessible using strings, not symbols. Solution must be recursive...
- Fix failing spec issue with multithreading: running spec detects a deadlock. Specs imported/converted from the one used
  for Rack::Session::Memcached.
- Import the remainder of the final spec from the testing code (in rack gem) for Rack::Session::Memcached.
- Create redrack-cache
- Create redrack-throttle
- Create redrack-localize
- Create redrack to package all of the above as single rack middleware
- Create redrails-session
- Create redrails-throttle
- Create redrails-localize
- Create redrail to package all of the redrails-* above, linking all redrack-* middleware into a rails app

