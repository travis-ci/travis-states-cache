require 'logger'

module Support
  module Logging
    def self.included(base)
      base.class_eval do
        let(:io)     { StringIO.new }
        let(:logger) { Logger.new(io) }
        let(:stdout) { io.string }
      end
    end
  end
end
