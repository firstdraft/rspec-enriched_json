# frozen_string_literal: true

require "json"
require "rspec/core/formatters/json_formatter"

module RSpec
  module EnrichedJson
    module Formatters
      class EnrichedJsonFormatter < RSpec::Core::Formatters::JsonFormatter
        RSpec::Core::Formatters.register self, :message, :dump_summary, :dump_profile, :stop, :seed, :close

        def stop(group_notification)
          @output_hash[:examples] = group_notification.notifications.map do |notification|
            format_example(notification.example).tap do |hash|
              e = notification.example.exception

              if e
                hash[:exception] = {
                  class: e.class.name,
                  message: e.message,
                  backtrace: notification.formatted_backtrace
                }

                # Add structured data if available
                if e.is_a?(RSpec::EnrichedJson::EnrichedExpectationNotMetError) && e.structured_data
                  hash[:structured_data] = {
                    expected: e.structured_data[:expected],
                    actual: e.structured_data[:actual],
                    matcher_name: e.structured_data[:matcher_name],
                    original_message: e.structured_data[:original_message]
                  }
                end
              end
            end
          end
        end
      end
    end
  end
end
