# frozen_string_literal: true

require "json"
require "rspec/core/formatters/json_formatter"

module RSpec
  module EnrichedJson
    module Formatters
      class EnrichedJsonFormatter < RSpec::Core::Formatters::JsonFormatter
        EXCEPTION_DETECTOR_REGEX = /(Exception|Error|undefined method|uninitialized constant)/
        PATH_AND_LINE_NUMBER_REGEX = /#?(?<path>.+?):(?<line_number>\d+)(?::in `.*')?/
        EXCEPTION_CLASS_AND_MESSAGE_REGEX = /^(?<exception_class>[A-Z]\w*Error|Exception):$\n(?<exception_message>(^\s\s.*\n?)+)/

        RSpec::Core::Formatters.register self, :message, :dump_summary, :dump_profile, :stop, :seed, :close

        def initialize(output)
          super
          @output_hash = {
            errors: []
          }
        end

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

        def message(notification)
          super

          if notification.message.match?(EXCEPTION_DETECTOR_REGEX)
            ansi_escape = /\e\[[0-9;]*[mGKHF]/
            clean_message = notification.message.gsub(ansi_escape, "")

            error_info = {
              message: clean_message
            }

            if match = clean_message.match(PATH_AND_LINE_NUMBER_REGEX)
              error_info[:path] = match.named_captures["path"]
              error_info[:line_number] = match.named_captures["line_number"]
            end

            if match = clean_message.match(EXCEPTION_CLASS_AND_MESSAGE_REGEX)
              error_info[:exception_class] = match.named_captures["exception_class"]
              error_info[:exception_message] = match.named_captures["exception_message"]
            end

            @output_hash[:errors] << error_info
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
