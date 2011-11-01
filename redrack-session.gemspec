# encoding: utf-8
$:.push File.expand_path("../lib", __FILE__)
require "redrack/session/version"

Gem::Specification.new do |s|
  s.name        = "redrack-session"
  s.version     = Redrack::Session::VERSION
  s.authors     = ["Kendall Gifford"]
  s.email       = ["zettabyte@gmail.com"]
  s.homepage    = "https://github.com/zettabyte/redrack-session"
  s.summary     = "Redis session store for rack applications."
  s.description = <<-DESC.gsub(/^\s*/, "")
    Redis session store for rack applications.

    This was inspired by the Rack::Session::Memcached session store.
  DESC

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- spec/*`.split("\n")
  s.require_paths = ["lib"]

  s.add_development_dependency "bundler",         "~> 1.0.21"
  s.add_development_dependency "rspec",           "~> 2.7.0"
  s.add_development_dependency "rack-test",       "~> 0.6.1"
  s.add_runtime_dependency     "rack",            "~> 1.3.5"
  s.add_runtime_dependency     "redis",           "~> 2.2.2"
  s.add_runtime_dependency     "redis-namespace", "~> 1.1.0"
end
