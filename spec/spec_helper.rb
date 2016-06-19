require 'travis/states/cache'
require 'support/matchers'
require 'support/logging'

RSpec.configure do |c|
  c.mock_with :mocha
  c.include Support::Logging
end
