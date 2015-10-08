# encoding: utf-8

$:.unshift File.expand_path('../lib', __FILE__)
require 'travis/states/cache/version'

Gem::Specification.new do |s|
  s.name          = "travis-states-cache"
  s.version       = Travis::States::VERSION
  s.authors       = ["Sven Fuchs"]
  s.email         = ["me@svenfuchs.com"]
  s.homepage      = "https://github.com/travis-ci/travis-states-cache"
  s.summary       = "[summary]"
  s.description   = "[description]"

  s.files         = Dir['{lib/**/*,spec/**/*,MIT-LICENSE,README.md,Gemfile}']
  s.platform      = Gem::Platform::RUBY
  s.require_paths = ['lib']
  s.rubyforge_project = '[none]'

  s.add_dependency 'connection_pool', '~> 2.2'
  s.add_dependency 'dalli',           '~> 2.7'
end
