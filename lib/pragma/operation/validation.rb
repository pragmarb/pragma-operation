# frozen_string_literal: true
module Pragma
  module Operation
    module Validation
      def self.included(base)
        base.extend ClassMethods
        base.include InstanceMethods
      end

      module ClassMethods
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
      end

      module InstanceMethods
        # Builds the policy for the current user and the given resource, using the previously
        # defined policy class.
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
        # @param validatable [Pragma::Policy::Base|Object] resource or policy
        #
        # @return [Boolean] whether the operation is authorized
        def authorize(validatable)
          policy = if defined?(Pragma::Policy::Base) && validatable.is_a?(Pragma::Policy::Base)
            validatable
          else
            build_policy(validatable)
          end

          policy.send("#{self.class.operation_name}?")
        end

        # Authorizes this operation on the provided resource or policy. If the user is not
        # authorized to perform the operation, responds with 403 Forbidden and an error body and
        # halts the execution.
        #
        # @param validatable [Pragma::Policy::Base|Object] resource or policy
        def authorize!(validatable)
          return if authorize(validatable)

          respond_with!(
            status: :forbidden,
            resource: {
              error_type: :forbidden,
              error_message: 'You are not authorized to perform this operation.'
            }
          )
        end
      end
    end
  end
end
