# frozen_string_literal: true
module Pragma
  module Operation
    # This is the base class all your operations should extend.
    #
    # @author Alessandro Desantis
    #
    # @abstract Subclass and override {#call} to implement an operation.
    class Base
      include Interactor

      class << self
        def inherited(child)
          child.class_eval do
            include Status
            include Authorization
            include Validation

            before :setup_context
            around :handle_halt
          end
        end

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
      end

      # Runs the operation.
      def call
        fail NotImplementedError
      end

      protected

      # Returns the params this operation is being run with.
      #
      # This is just a shortcut for +context.params+.
      #
      # @return [Hash]
      def params
        context.params
      end

      # Sets the status and resource to respond with.
      #
      # You can achieve the same result by setting +context.status+ and +context.resource+ wherever
      # you want in {#call}.
      #
      # Note that calling this method doesn't halt the execution of the operation and that this
      # method can be called multiple times, overriding the previous context.
      #
      # @param status [Integer|Symbol] an HTTP status code
      # @param resource [Object] an object responding to +#to_json+
      def respond_with(status:, resource:)
        context.status = status
        context.resource = resource
      end

      # Same as {#respond_with}, but also halts the execution of the operation.
      #
      # @param status [Integer|Symbol] an HTTP status code
      # @param resource [Object] an object responding to +#to_json+
      #
      # @see #respond_with
      def respond_with!(status:, resource:)
        respond_with status: status, resource: resource
        fail Halt
      end

      # Sets the status to respond with.
      #
      # You can achieve the same result by setting +context.status+ wherever you want in {#call}.
      #
      # Note that calling this method doesn't halt the execution of the operation and that this
      # method can be called multiple times, overriding the previous context.
      #
      # @param status [Integer|Symbol] an HTTP status code
      def head(status)
        context.status = status
      end

      # Same as {#head}, but also halts the execution of the operation.
      #
      # @param status [Integer|Symbol] an HTTP status code
      #
      # @see #head
      def head!(status)
        head status
        fail Halt
      end

      # Returns the current user.
      #
      # This is just a shortcut for +context.current_user+.
      #
      # @return [Object]
      def current_user
        context.current_user
      end

      private

      def setup_context
        context.params ||= {}
      end

      def handle_halt(interactor)
        interactor.call
      rescue Halt # rubocop:disable Lint/HandleExceptions
      end

      def with_hooks
        # This overrides the default behavior, which is not to run after hooks if an exception is
        # raised either in +#call+ or one of the before hooks. See:
        # https://github.com/collectiveidea/interactor/blob/master/lib/interactor/hooks.rb#L210)
        run_around_hooks do
          begin
            run_before_hooks
            yield
          ensure
            run_after_hooks
          end
        end
      end
    end

    # This error is raised when the operation's execution should be stopped. It is silently
    # rescued by the operation.
    #
    # @author Alessandro Desantis
    Halt = Class.new(StandardError)
  end
end
