# frozen_string_literal: true

require "rspec/expectations"

module RSpec
  module EnrichedJson
    # Custom exception that carries structured data alongside the message
    class EnrichedExpectationNotMetError < RSpec::Expectations::ExpectationNotMetError
      attr_reader :structured_data

      def initialize(message, structured_data = {})
        super(message)
        @structured_data = structured_data
      end
    end
  end
end
