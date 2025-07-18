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
              # Add enhanced metadata
              add_metadata(hash, notification.example)

              e = notification.example.exception

              if e
                hash[:exception] = {
                  class: e.class.name,
                  message: e.message,
                  backtrace: notification.formatted_backtrace
                }

                # Add structured data if available
                if e.is_a?(RSpec::EnrichedJson::EnrichedExpectationNotMetError) && e.details
                  hash[:details] = safe_structured_data(e.details)
                end

                if hash.key?(:details) && hash[:details].key?(:expected) && hash[:details].key?(:actual)
                  exception_message = hash[:exception][:message]
                  if exception_message.include?("\nDiff:")
                    hash[:exception][:message] = exception_message.sub(/Diff:.*/m, "").strip
                  end
                end
              else
                # For passing tests, check if we have captured values
                key = notification.example.id
                if RSpec::EnrichedJson.all_test_values.key?(key)
                  captured_values = RSpec::EnrichedJson.all_test_values[key]
                  hash[:details] = safe_structured_data(captured_values)
                end
              end
            end
          end
        end

        private

        def add_metadata(hash, example)
          metadata = example.metadata.dup

          # Extract custom tags (all symbols and specific keys)
          custom_tags = {}
          metadata.each do |key, value|
            # Include all symbol keys (like :focus, :slow, etc.)
            if key.is_a?(Symbol) && value == true
              custom_tags[key] = true
            # Include specific metadata that might be useful
            elsif [:type, :priority, :severity, :db, :js].include?(key)
              custom_tags[key] = value
            end
          end

          # Add enhanced metadata
          hash[:metadata] = {
            # Location information
            location: example.location,
            absolute_file_path: File.expand_path(example.metadata[:file_path]),
            rerun_file_path: example.location_rerun_argument,

            # Example hierarchy
            example_group: example.example_group.description,
            example_group_hierarchy: extract_group_hierarchy(example),

            # Described class if available
            described_class: metadata[:described_class]&.to_s,

            # Custom tags and metadata
            tags: custom_tags.empty? ? nil : custom_tags,

            # Shared example information if applicable
            shared_group_inclusion_backtrace: metadata[:shared_group_inclusion_backtrace]
          }.compact # Remove nil values
        end

        def extract_group_hierarchy(example)
          hierarchy = []
          current_group = example.example_group

          while current_group
            hierarchy.unshift(current_group.description)
            current_group = (current_group.superclass < RSpec::Core::ExampleGroup) ? current_group.superclass : nil
          end

          hierarchy
        end

        def safe_structured_data(details)
          # Start with core fields - only use Oj for expected/actual
          result = {
            expected: safe_serialize(details[:expected]),
            actual: safe_serialize(details[:actual])
          }

          # Add all other fields as regular JSON values
          details.each do |key, value|
            next if [:expected, :actual].include?(key)
            result[key] = value
          end

          result.compact
        end

        def safe_serialize(value)
          # Delegate to the existing serialization logic in ExpectationHelperWrapper
          # This already handles Regexp objects specially
          serialized = RSpec::EnrichedJson::ExpectationHelperWrapper::Serializer.serialize_value(value)
          
          # The Serializer returns JSON strings, so we need to double-encode for the formatter
          serialized.to_json
        rescue => e
          # Better error recovery - provide context about what failed
          begin
            obj_class = value.class.name
          rescue
            obj_class = "Unknown"
          end

          {
            "serialization_error" => true,
            "error_class" => e.class.name,
            "error_message" => e.message,
            "object_class" => obj_class,
            "fallback_value" => safe_fallback_value(value)
          }.to_json
        end

        def safe_fallback_value(value)
          # Try multiple fallback strategies
          value.to_s
        rescue
          begin
            value.class.name
          rescue
            "Unable to serialize"
          end
        end

        # Override close to clean up memory after formatter is done
        def close(_notification)
          super
          # Clean up captured test values to prevent memory leaks
          RSpec::EnrichedJson.clear_test_values
        end
      end
    end
  end
end
