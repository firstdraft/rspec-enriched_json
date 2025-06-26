# frozen_string_literal: true

require "json"
require "rspec/expectations"

module RSpec
  module EnrichedJson
    # Universal wrapper to catch ALL matchers and attach structured data
    module ExpectationHelperWrapper
      MAX_SERIALIZATION_DEPTH = 5
      MAX_ARRAY_SIZE = 100
      MAX_HASH_SIZE = 100
      MAX_STRING_LENGTH = 1000
      def self.install!
        RSpec::Expectations::ExpectationHelper.singleton_class.prepend(self)
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
          when nil, Numeric, TrueClass, FalseClass
            value
          when String
            truncate_string(value)
          when Symbol
            value.to_s
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
        enriched_with = {
          expected: Serializer.serialize_value(expected_raw),
          actual: Serializer.serialize_value(actual_raw),
          original_message: original_message,  # Only populated when custom message overrides it
          matcher_name: matcher.class.name,
          diff_info: {
            diffable: values_diffable?(expected_raw, actual_raw, matcher)
          }
        }

        # Raise new exception with data attached
        raise EnrichedExpectationNotMetError.new(e.message, enriched_with)
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
    end
  end
end

# Auto-install when this file is required
RSpec::EnrichedJson::ExpectationHelperWrapper.install!
