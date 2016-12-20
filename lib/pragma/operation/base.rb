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

      STATUSES = {
        200 => :ok,
        201 => :created,
        202 => :accepted,
        203 => :non_authoritative_information,
        204 => :no_content,
        205 => :reset_content,
        206 => :partial_content,
        207 => :multi_status,
        208 => :already_reported,
        300 => :multiple_choices,
        301 => :moved_permanently,
        302 => :found,
        303 => :see_other,
        304 => :not_modified,
        305 => :use_proxy,
        307 => :temporary_redirect,
        400 => :bad_request,
        401 => :unauthorized,
        402 => :payment_required,
        403 => :forbidden,
        404 => :not_found,
        405 => :method_not_allowed,
        406 => :not_acceptable,
        407 => :proxy_authentication_required,
        408 => :request_timeout,
        409 => :conflict,
        410 => :gone,
        411 => :length_required,
        412 => :precondition_failed,
        413 => :request_entity_too_large,
        414 => :request_uri_too_large,
        415 => :unsupported_media_type,
        416 => :request_range_not_satisfiable,
        417 => :expectation_failed,
        418 => :im_a_teapot,
        422 => :unprocessable_entity,
        423 => :locked,
        424 => :failed_dependency,
        425 => :unordered_collection,
        426 => :upgrade_required,
        428 => :precondition_required,
        429 => :too_many_requests,
        431 => :request_header_fields_too_large,
        449 => :retry_with,
        500 => :internal_server_error,
        501 => :not_implemented,
        502 => :bad_gateway,
        503 => :service_unavailable,
        504 => :gateway_timeout,
        505 => :http_version_not_supported,
        506 => :variant_also_negotiates,
        507 => :insufficient_storage,
        509 => :bandwidth_limit_exceeded,
        510 => :not_extended,
        511 => :network_authentication_required
      }.freeze

      class << self
        # Sets the policy to use for authorizing this operation.
        #
        # @param klass [Class] a subclass of +Pragma::Policy::Base+
        def policy(klass) # rubocop:disable Style/TrivialAccessors
          @policy = klass
        end

        # Builds the policy for the given user and resource, using the previous defined policy
        # class.
        #
        # @param user [Object]
        # @param resource [Object]
        #
        # @return [Pragma::Policy::Base]
        #
        # @see #policy
        def build_policy(user:, resource:)
          @policy.new(user: user, resource: resource)
        end

        # Sets the contract to use for validating this operation.
        #
        # @param klass [Class] a subclass of +Pragma::Contract::Base+
        def contract(klass)
          @contract = klass
        end

        # Builds the contract for the given resource, using the previous defined contract class.
        #
        # @param resource [Object]
        #
        # @return [Pragma::Contract::Base]
        #
        # @see #contract
        def build_contract(resource)
          @contract.new(resource)
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

        def inherited(child)
          child.class_eval do
            before :setup_context

            around :handle_halt

            after :mark_result
            after :consolidate_status
            after :validate_status
            after :set_default_status
          end
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

      # Builds the policy for the current user and the given resource, using the previously defined
      # policy class.
      #
      # @param resource [Object]
      #
      # @return [Pragma::Policy::Base]
      #
      # @see .policy
      # @see .build_policy
      def build_policy(resource)
        self.class.build_policy(user: current_user, resource: resource)
      end

      # Authorizes this operation on the provided resource or policy.
      #
      # @param authorizable [Pragma::Policy::Base|Object] resource or policy
      #
      # @return [Boolean] whether the operation is authorized
      def authorize(authorizable)
        policy = if defined?(Pragma::Policy::Base) && authorizable.is_a?(Pragma::Policy::Base)
          authorizable
        else
          build_policy(authorizable)
        end

        policy.send("#{self.class.operation_name}?")
      end

      # Authorizes this operation on the provided resource or policy. If the user is not authorized
      # to perform the operation, responds with 403 Forbidden and an error body and halts the
      # execution.
      #
      # @param authorizable [Pragma::Policy::Base|Object] resource or policy
      def authorize!(authorizable)
        return if authorize(authorizable)

        respond_with!(
          status: :forbidden,
          resource: {
            error_type: :forbidden,
            error_message: 'You are not authorized to perform this operation.'
          }
        )
      end

      # Builds the contract for the given resource, using the previously defined contract class.
      #
      # This is just an instance-level alias of {.build_contract}. You should use this from inside
      # the operation.
      #
      # @param resource [Object]
      #
      # @return [Pragma::Contract::Base]
      #
      # @see .contract
      # @see .build_contract
      def build_contract(resource)
        self.class.build_contract(resource)
      end

      # Validates this operation on the provided contract or resource.
      #
      # @param validatable [Object|Pragma::Contract::Base] contract or resource
      #
      # @return [Boolean] whether the operation is valid
      def validate(validatable)
        contract = if defined?(Pragma::Contract::Base) && validatable.is_a?(Pragma::Contract::Base)
          validatable
        else
          build_contract(validatable)
        end

        contract.validate(params)
      end

      # Validates this operation on the provided contract or resource. If the operation is not
      # valid, responds with 422 Unprocessable Entity and an error body and halts the execution.
      #
      # @param validatable [Object|Pragma::Contract::Base] contract or resource
      def validate!(validatable)
        contract = if defined?(Pragma::Contract::Base) && validatable.is_a?(Pragma::Contract::Base)
          validatable
        else
          build_contract(validatable)
        end

        return if validate(contract)

        respond_with!(
          status: :unprocessable_entity,
          resource: {
            error_type: :contract_not_respected,
            error_message: 'The contract for this operation was not respected.',
            meta: {
              errors: contract.errors
            }
          }
        )
      end

      private

      def setup_context
        context.params ||= {}
      end

      def handle_halt(interactor)
        interactor.call
      rescue Halt # rubocop:disable Lint/HandleExceptions
      end

      def set_default_status
        return if context.status
        context.status = context.resource ? :ok : :no_content
      end

      def validate_status
        if context.status.is_a?(Integer)
          fail InvalidStatusError, context.status unless STATUSES.key?(context.status)
        else
          fail InvalidStatusError, context.status unless STATUSES.invert.key?(context.status.to_sym)
        end
      end

      def consolidate_status
        context.status = if context.status.is_a?(Integer)
          STATUSES[context.status]
        else
          context.status.to_sym
        end
      end

      def mark_result
        return if /\A(2|3)\d{2}\z/ =~ STATUSES.invert[context.status].to_s
        context.fail!
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

    # This error is raised when an invalid status is set for an operation.
    #
    # @author Alessandro Desantis
    class InvalidStatusError < StandardError
      # Initializes the error.
      #
      # @param [Integer|Symbol] an invalid HTTP status code
      def initialize(status)
        super "'#{status}' is not a valid HTTP status code."
      end
    end

    # This error is raised when the operation's execution should be stopped. It is silently
    # rescued by the operation.
    #
    # @author Alessandro Desantis
    class Halt < StandardError
    end
  end
end
