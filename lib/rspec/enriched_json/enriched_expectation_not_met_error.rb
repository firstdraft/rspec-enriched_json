# frozen_string_literal: true

require "rspec/expectations"

module RSpec
  module EnrichedJson
    # Custom exception that carries structured data alongside the message
    class EnrichedExpectationNotMetError < RSpec::Expectations::ExpectationNotMetError
      attr_reader :enriched_with

      def initialize(message, enriched_with = {})
        super(message)
        @enriched_with = enriched_with
      end
    end
  end
end
