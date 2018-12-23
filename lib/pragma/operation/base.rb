# frozen_string_literal: true

module Pragma
  module Operation
    # This is the base class all your operations should extend.
    #
    # @author Alessandro Desantis
    class Base < Trailblazer::Operation
      class << self
        # Returns the name of this operation.
        #
        # For instance, if the operation is called +API::V1::Post::Operation::Create+, returns
        # +create+.
        #
        # @return [Symbol]
        def operation_name
          name.split('::').last
            .gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2')
            .gsub(/([a-z\d])([A-Z])/, '\1_\2')
            .tr('-', '_')
            .downcase
            .to_sym
        end

        def respond(skill, *args)
          if args.size == 1 && args.first.is_a?(Hash)
            options = args[0]
            response = Pragma::Operation::Response.new(status: options.fetch(:status, 200))
          elsif args.size >= 1 && args.size <= 2
            response = args[0]
            options = args[1] || {}

            unless response.is_a?(Pragma::Operation::Response)
              response = Pragma::Operation::Response.const_get(response).new
            end
          else
            fail ArgumentError, "Expected 2..3 arguments, #{args.size + 1} given"
          end

          response.entity = options[:entity] if options.key?(:entity)
          response.headers = response.headers.merge(options[:headers]) if options[:headers]

          response.decorate_with(options[:decorator]) if options[:decorator]

          skill['result.response'] = response
        end

        def error(skill, *args)
          if args.size == 1 && args.first.is_a?(Hash)
            options = args[0]

            error = Pragma::Operation::Error.new(
              error_type: options.fetch(:error_type),
              error_message: options.fetch(:error_message),
              meta: options.fetch(:meta, {})
            )
          elsif args.size >= 1 && args.size <= 2
            error = args[0]
            options = args[1] || {}
          else
            fail ArgumentError, "Expected 2..3 arguments, #{args.size + 1} given"
          end

          if defined?(Pragma::Decorator::Error) && !options.key?(:decorator)
            options[:decorator] = Pragma::Decorator::Error
          end

          response = Pragma::Operation::Response.const_get(error.error_type).new(entity: error)

          respond(skill, response, options)
        end
      end
    end
  end
end
