# frozen_string_literal: true

require "json"
require "oj"
require "rspec/expectations"
require "rspec/support/differ"

module RSpec
  module EnrichedJson
    @all_test_values = {}

    def self.all_test_values
      @all_test_values
    end

    def self.clear_test_values
      @all_test_values = {}
    end

    module ExpectationHelperWrapper
      def self.install!
        RSpec::Expectations::ExpectationHelper.singleton_class.prepend(self)
        RSpec::Expectations::PositiveExpectationHandler.singleton_class.prepend(PositiveHandlerWrapper)
        RSpec::Expectations::NegativeExpectationHandler.singleton_class.prepend(NegativeHandlerWrapper)
      end

      module Serializer
        extend self

        OJ_OPTIONS = {
          mode: :object,
          circular: true,
          class_cache: false,
          create_additions: false,
          symbol_keys: false,
          auto_define: false,
          create_id: nil,
          use_to_json: false,
          use_as_json: false,
          use_raw_json: false,
          bigdecimal_as_decimal: true,
          nan: :word
        }

        def serialize_value(value)
          if value.is_a?(Regexp)
            return Oj.dump(value.inspect, mode: :compat)
          end

          Oj.dump(value, OJ_OPTIONS)
        rescue => e
          Oj.dump({
            "_serialization_error" => e.message,
            "_class" => value.class.name,
            "_to_s" => begin
              value.to_s
            rescue
              "[to_s failed]"
            end
          }, mode: :compat)
        end
      end

      def handle_failure(matcher, message, failure_message_method)
        original_message = nil
        if message
          original_message = matcher.send(failure_message_method)
        end

        super
      rescue RSpec::Expectations::ExpectationNotMetError => e
        expected_raw = extract_value(matcher, :expected, failure_message_method)
        actual_raw = extract_value(matcher, :actual, failure_message_method)
        negated = failure_message_method == :failure_message_when_negated

        details = {
          expected: Serializer.serialize_value(expected_raw),
          actual: Serializer.serialize_value(actual_raw),
          original_message: original_message,
          matcher_name: matcher.class.name,
          diffable: matcher.respond_to?(:diffable?) && matcher.diffable?,
          negated: negated
        }

        if details[:diffable] && expected_raw && actual_raw
          diff = generate_diff(actual_raw, expected_raw)
          details[:diff] = diff unless diff.nil? || diff.strip.empty?
        end

        raise EnrichedExpectationNotMetError.new(e.message, details)
      end

      private

      def extract_value(matcher, method_name, failure_message_method = nil)
        if matcher.is_a?(RSpec::Matchers::BuiltIn::BePredicate) || matcher.is_a?(RSpec::Matchers::BuiltIn::Has)
          case method_name
          when :expected
            !(failure_message_method == :failure_message_when_negated)
          when :actual
            if matcher.instance_variable_defined?(:@predicate_result)
              matcher.instance_variable_get(:@predicate_result)
            end
          end
        else
          return nil unless matcher.respond_to?(method_name)
          value = matcher.send(method_name)
          (value == matcher && !value.nil?) ? nil : value
        end
      rescue
        nil
      end

      def generate_diff(actual, expected)
        differ = RSpec::Support::Differ.new(
          object_preparer: lambda { |obj|
            RSpec::Matchers::Composable.surface_descriptions_in(obj)
          },
          color: RSpec.configuration.color_enabled?
        )
        differ.diff(actual, expected)
      rescue
        nil
      end
    end

    module HandlerWrapperShared
      def capture_test_values(actual, initial_matcher, negated: false)
        return unless initial_matcher && RSpec.current_example

        begin
          if initial_matcher.is_a?(RSpec::Matchers::BuiltIn::BePredicate) || initial_matcher.is_a?(RSpec::Matchers::BuiltIn::Has)
            expected_value = !negated

            if negated && initial_matcher.respond_to?(:does_not_match?)
              initial_matcher.does_not_match?(actual)
            else
              initial_matcher.matches?(actual)
            end

            actual_value = if initial_matcher.instance_variable_defined?(:@predicate_result)
              initial_matcher.instance_variable_get(:@predicate_result)
            end
          else
            expected_value = initial_matcher.respond_to?(:expected) ? initial_matcher.expected : nil
            actual_value = actual
          end

          key = RSpec.current_example.id
          RSpec::EnrichedJson.all_test_values[key] = {
            expected: ExpectationHelperWrapper::Serializer.serialize_value(expected_value),
            actual: ExpectationHelperWrapper::Serializer.serialize_value(actual_value),
            matcher_name: initial_matcher.class.name,
            passed: nil
          }

          RSpec::EnrichedJson.all_test_values[key][:negated] = true if negated
        rescue => e
          if defined?(RSpec.configuration) && RSpec.configuration.reporter
            RSpec.configuration.reporter.message("Warning: Error capturing test values: #{e.message}")
          elsif ENV["DEBUG"]
            puts "Error capturing test values: #{e.message}"
          end
        end
      end

      def mark_as_passed(initial_matcher)
        return unless initial_matcher && RSpec.current_example

        key = RSpec.current_example.id
        if RSpec::EnrichedJson.all_test_values[key]
          RSpec::EnrichedJson.all_test_values[key][:passed] = true
        end
      end
    end

    module PositiveHandlerWrapper
      include HandlerWrapperShared

      def handle_matcher(actual, initial_matcher, custom_message = nil, &block)
        capture_test_values(actual, initial_matcher, negated: false)
        result = super
        mark_as_passed(initial_matcher)
        result
      end
    end

    module NegativeHandlerWrapper
      include HandlerWrapperShared

      def handle_matcher(actual, initial_matcher, custom_message = nil, &block)
        capture_test_values(actual, initial_matcher, negated: true)
        result = super
        mark_as_passed(initial_matcher)
        result
      end
    end
  end
end

RSpec::EnrichedJson::ExpectationHelperWrapper.install!
