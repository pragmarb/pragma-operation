# frozen_string_literal: true
module Pragma
  module Operation
    module Authorization
      def self.included(base)
        base.extend ClassMethods
        base.include InstanceMethods
      end

      module ClassMethods
        # Sets the policy to use for authorizing this operation.
        #
        # @param klass [Class] a subclass of +Pragma::Policy::Base+
        def policy(klass)
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
      end

      module InstanceMethods
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
      end
    end
  end
end
