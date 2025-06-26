# frozen_string_literal: true

require "rspec/expectations"

module RSpec
  module EnrichedJson
    # Custom exception that carries structured data alongside the message
    class EnrichedExpectationNotMetError < RSpec::Expectations::ExpectationNotMetError
      attr_reader :details

      def initialize(message, details = {})
        super(message)
        @details = details
      end
    end
  end
end
