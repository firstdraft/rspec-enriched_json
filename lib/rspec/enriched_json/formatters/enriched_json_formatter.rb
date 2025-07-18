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
              add_metadata(hash, notification.example)
              e = notification.example.exception

              if e
                hash[:exception] = {
                  class: e.class.name,
                  message: e.message,
                  backtrace: notification.formatted_backtrace
                }

                if e.is_a?(RSpec::EnrichedJson::EnrichedExpectationNotMetError) && e.details
                  hash[:details] = e.details
                end

                if hash.key?(:details) && hash[:details].key?(:expected) && hash[:details].key?(:actual)
                  exception_message = hash[:exception][:message]
                  if exception_message.include?("\nDiff:")
                    hash[:exception][:message] = exception_message.sub(/Diff:.*/m, "").strip
                  end
                end
              else
                key = notification.example.id
                if RSpec::EnrichedJson.all_test_values.key?(key)
                  captured_values = RSpec::EnrichedJson.all_test_values[key]
                  hash[:details] = captured_values
                end
              end
            end
          end
        end

        private

        def add_metadata(hash, example)
          metadata = example.metadata.dup

          custom_tags = {}
          metadata.each do |key, value|
            if key.is_a?(Symbol) && value == true
              custom_tags[key] = true
            elsif [:type, :priority, :severity, :db, :js].include?(key)
              custom_tags[key] = value
            end
          end

          hash[:metadata] = {
            location: example.location,
            absolute_file_path: File.expand_path(example.metadata[:file_path]),
            rerun_file_path: example.location_rerun_argument,
            example_group: example.example_group.description,
            example_group_hierarchy: extract_group_hierarchy(example),
            described_class: metadata[:described_class]&.to_s,
            tags: custom_tags.empty? ? nil : custom_tags,
            shared_group_inclusion_backtrace: metadata[:shared_group_inclusion_backtrace]
          }.compact
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

        def close(_notification)
          super
          RSpec::EnrichedJson.clear_test_values
        end
      end
    end
  end
end
