# frozen_string_literal: true

require "json"
require "rspec/expectations"
require "rspec/support/differ"

module RSpec
  module EnrichedJson
    # Storage for all test values (pass or fail)
    @all_test_values = {}
    
    def self.all_test_values
      @all_test_values
    end
    
    def self.clear_test_values
      @all_test_values = {}
    end
    
    # Universal wrapper to catch ALL matchers and attach structured data
    module ExpectationHelperWrapper
      MAX_SERIALIZATION_DEPTH = 5
      MAX_ARRAY_SIZE = 100
      MAX_HASH_SIZE = 100
      MAX_STRING_LENGTH = 1000
      def self.install!
        RSpec::Expectations::ExpectationHelper.singleton_class.prepend(self)
        # Also hook into the expectation handlers to capture ALL values
        RSpec::Expectations::PositiveExpectationHandler.singleton_class.prepend(PositiveHandlerWrapper)
        RSpec::Expectations::NegativeExpectationHandler.singleton_class.prepend(NegativeHandlerWrapper)
      end

      # Make serialize_value accessible for other components
      module Serializer
        extend self

        MAX_SERIALIZATION_DEPTH = 5
        MAX_ARRAY_SIZE = 100
        MAX_HASH_SIZE = 100
        MAX_STRING_LENGTH = 1000

        def serialize_value(value, depth = 0)
          return "[Max depth exceeded]" if depth > MAX_SERIALIZATION_DEPTH

          case value
          when Numeric, TrueClass, FalseClass
            value
          when String
            unescape_string_double_quotes(
              truncate_string(value)
            )
          when Symbol
            serialize_object(value)
          when nil
            serialize_object(value)
          when Array
            return "[Large array: #{value.size} items]" if value.size > MAX_ARRAY_SIZE
            value.map { |v| serialize_value(v, depth + 1) }
          when Hash
            return "[Large hash: #{value.size} keys]" if value.size > MAX_HASH_SIZE
            value.transform_values { |v| serialize_value(v, depth + 1) }
          else
            serialize_object(value, depth)
          end
        rescue => e
          {
            "class" => value.class.name,
            "serialization_error" => e.message
          }
        end

        def serialize_object(obj, depth = 0)
          result = {
            "class" => obj.class.name,
            "inspect" => safe_inspect(obj),
            "to_s" => safe_to_s(obj)
          }

          # Handle Structs specially
          if obj.is_a?(Struct)
            result["struct_values"] = obj.to_h.transform_values { |v| serialize_value(v, depth + 1) }
          end

          # Include instance variables only for small objects
          ivars = obj.instance_variables
          if ivars.any? && ivars.length <= 10
            result["instance_variables"] = ivars.each_with_object({}) do |ivar, hash|
              hash[ivar.to_s] = serialize_value(obj.instance_variable_get(ivar), depth + 1)
            end
          end

          result
        end

        def truncate_string(str)
          return str if str.length <= MAX_STRING_LENGTH
          "#{str[0...MAX_STRING_LENGTH]}... (truncated)"
        end

        def unescape_string_double_quotes(str)
          if str.start_with?('"') && str.end_with?('"')
            begin
              # Only undump if it's a valid dumped string
              # Check if the string is properly escaped by attempting undump
              str.undump
            rescue RuntimeError => e
              # If undump fails, just return the original string
              # This handles cases where the string has quotes but isn't a valid dump format
              str
            end
          else
            str
          end
        end

        def safe_inspect(obj)
          truncate_string(obj.inspect)
        rescue => e
          "[inspect failed: #{e.class}]"
        end

        def safe_to_s(obj)
          truncate_string(obj.to_s)
        rescue => e
          "[to_s failed: #{e.class}]"
        end
      end

      def handle_failure(matcher, message, failure_message_method)
        # If a custom message is provided, capture the original message first
        original_message = nil
        if message
          original_message = matcher.send(failure_message_method)
        end

        # Call original handler with the original message
        super
      rescue RSpec::Expectations::ExpectationNotMetError => e
        # Extract raw values for diff analysis
        expected_raw = extract_value(matcher, :expected)
        actual_raw = extract_value(matcher, :actual)

        # Collect structured data
        details = {
          expected: Serializer.serialize_value(expected_raw),
          actual: Serializer.serialize_value(actual_raw),
          original_message: original_message, # Only populated when custom message overrides it
          matcher_name: matcher.class.name,
          diffable: values_diffable?(expected_raw, actual_raw, matcher)
        }

        # Generate diff if values are diffable
        if details[:diffable] && expected_raw && actual_raw
          diff = generate_diff(actual_raw, expected_raw)
          details[:diff] = diff unless diff.nil? || diff.strip.empty?
        end

        # Capture matcher-specific instance variables
        matcher_data = extract_matcher_specific_data(matcher)
        details.merge!(matcher_data) unless matcher_data.empty?

        # Raise new exception with data attached
        raise EnrichedExpectationNotMetError.new(e.message, details)
      end

      private

      def extract_value(matcher, method_name)
        return nil unless matcher.respond_to?(method_name)

        value = matcher.send(method_name)
        # Don't return nil if the value itself is nil
        # Only return nil if the value is the matcher itself (self-referential)
        (value == matcher && !value.nil?) ? nil : value
      rescue
        nil
      end

      def extract_matcher_specific_data(matcher)
        # Skip common instance variables that are already captured
        skip_vars = [
          :@expected, :@actual, :@args, :@name,
          # Skip internal implementation details
          :@matcher, :@matchers, :@target,
          :@delegator, :@base_matcher,
          :@block, :@event_proc,
          # Skip verbose internal state
          :@pairings_maximizer, :@best_solution,
          :@expected_captures, :@match_captures,
          :@failures, :@errors,
          # Skip RSpec internals
          :@matcher_execution_context,
          :@chained_method_with_args_combos
        ]

        # Define meaningful variables we want to keep
        useful_vars = [
          :@missing_items, :@extra_items,  # ContainExactly
          :@expecteds, :@actuals,           # Include
          :@operator, :@delta, :@tolerance, # Comparison matchers
          :@expected_before, :@expected_after, :@actual_before, :@actual_after, # Change matcher
          :@from, :@to, :@minimum, :@maximum, :@count, # Various matchers
          :@failure_message, :@failure_message_when_negated,
          :@description
        ]

        # Get all instance variables
        ivars = matcher.instance_variables - skip_vars
        return {} if ivars.empty?

        # Build a hash of matcher-specific data
        matcher_data = {}

        ivars.each do |ivar|
          # Only include if it's in our useful list or looks like user data
          unless useful_vars.include?(ivar) || ivar.to_s.match?(/^@(missing|extra|failed|unmatched|matched)_/)
            next
          end

          value = matcher.instance_variable_get(ivar)

          # Skip if value is nil or the matcher itself
          next if value.nil? || value == matcher

          # Skip procs and complex objects unless they're simple collections
          if value.is_a?(Proc) || (value.is_a?(Object) && !value.is_a?(Enumerable) && !value.is_a?(Numeric) && !value.is_a?(String) && !value.is_a?(Symbol))
            next
          end

          # Convert instance variable name to a more readable format
          # @missing_items -> missing_items
          key = ivar.to_s.delete_prefix("@").to_sym

          # Serialize the value
          matcher_data[key] = Serializer.serialize_value(value)
        rescue
          # Skip this instance variable if we can't serialize it
          next
        end

        matcher_data
      end

      def values_diffable?(expected, actual, matcher)
        # First check if the matcher itself declares diffability
        if matcher.respond_to?(:diffable?)
          return matcher.diffable?
        end

        # If either value is nil, not diffable
        return false if expected.nil? || actual.nil?

        # For different classes, generally not diffable
        return false unless actual.instance_of?(expected.class)

        # Check if both values are of the same basic diffable type
        case expected
        when String, Array, Hash
          # These types are inherently diffable when compared to same type
          true
        else
          # For other types, they're diffable if they respond to to_s
          # and their string representations would be meaningful
          expected.respond_to?(:to_s) && actual.respond_to?(:to_s)
        end
      rescue
        # If any error occurs during checking, assume not diffable
        false
      end

      def generate_diff(actual, expected)
        # Use RSpec's own differ for consistency
        differ = RSpec::Support::Differ.new(
          object_preparer: lambda { |obj|
            RSpec::Matchers::Composable.surface_descriptions_in(obj)
          },
          color: false # Always disable color for JSON output
        )
        differ.diff(actual, expected)
      rescue
        # If diff generation fails, return nil rather than crashing
        nil
      end
    end
    
    # Wrapper for positive expectations to capture ALL values
    module PositiveHandlerWrapper
      def handle_matcher(actual, initial_matcher, custom_message=nil, &block)
        result = super
        
        # Capture values for ALL tests (pass or fail)
        if initial_matcher && RSpec.current_example
          begin
            expected_value = initial_matcher.respond_to?(:expected) ? initial_matcher.expected : nil
            actual_value = initial_matcher.respond_to?(:actual) ? initial_matcher.actual : actual
            
            key = "#{RSpec.current_example.location}:#{RSpec.current_example.description}"
            RSpec::EnrichedJson.all_test_values[key] = {
              expected: ExpectationHelperWrapper::Serializer.serialize_value(expected_value),
              actual: ExpectationHelperWrapper::Serializer.serialize_value(actual_value),
              matcher_name: initial_matcher.class.name,
              passed: result.nil? ? false : true
            }
          rescue => e
            # Silently ignore errors in value capture
          end
        end
        
        result
      end
    end
    
    # Wrapper for negative expectations to capture ALL values
    module NegativeHandlerWrapper
      def handle_matcher(actual, initial_matcher, custom_message=nil, &block)
        result = super
        
        # Capture values for ALL tests (pass or fail)
        if initial_matcher && RSpec.current_example
          begin
            expected_value = initial_matcher.respond_to?(:expected) ? initial_matcher.expected : nil
            actual_value = initial_matcher.respond_to?(:actual) ? initial_matcher.actual : actual
            
            key = "#{RSpec.current_example.location}:#{RSpec.current_example.description}"
            RSpec::EnrichedJson.all_test_values[key] = {
              expected: ExpectationHelperWrapper::Serializer.serialize_value(expected_value),
              actual: ExpectationHelperWrapper::Serializer.serialize_value(actual_value),
              matcher_name: initial_matcher.class.name,
              passed: result.nil? ? false : true,
              negated: true
            }
          rescue => e
            # Silently ignore errors in value capture
          end
        end
        
        result
      end
    end
  end
end

# Auto-install when this file is required
RSpec::EnrichedJson::ExpectationHelperWrapper.install!
