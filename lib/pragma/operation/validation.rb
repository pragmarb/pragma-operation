# frozen_string_literal: true
module Pragma
  module Operation
    # Provides integration with {https://github.com/pragmarb/pragma-contract Pragma::Contract}.
    #
    # @author Alessandro Desantis
    module Validation
      def self.included(base)
        base.extend ClassMethods
        base.include InstanceMethods
      end

      module ClassMethods # :nodoc:
        # Sets the contract to use for validating this operation.
        #
        # @param klass [Class] a subclass of +Pragma::Contract::Base+
        def contract(klass)
          @contract = klass
        end

        # Returns the contract class.
        #
        # @return [Class]
        def contract_klass
          @contract
        end

        # Builds the contract for the given resource, using the previous defined contract class.
        #
        # @param resource [Object]
        #
        # @return [Pragma::Contract::Base]
        #
        # @see #contract
        def build_contract(resource)
          contract_klass.new(resource)
        end
      end

      module InstanceMethods # :nodoc:
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
          # rubocop:disable Metrics/LineLength
          contract = if defined?(Pragma::Contract::Base) && validatable.is_a?(Pragma::Contract::Base)
            validatable
          else
            build_contract(validatable)
          end
          # rubocop:enable Metrics/LineLength

          contract.validate(params)
        end

        # Validates this operation on the provided contract or resource. If the operation is not
        # valid, responds with 422 Unprocessable Entity and an error body and halts the execution.
        #
        # @param validatable [Object|Pragma::Contract::Base] contract or resource
        def validate!(validatable)
          # rubocop:disable Metrics/LineLength
          contract = if defined?(Pragma::Contract::Base) && validatable.is_a?(Pragma::Contract::Base)
            validatable
          else
            build_contract(validatable)
          end
          # rubocop:enable Metrics/LineLength

          return if validate(contract)

          respond_with!(
            status: :unprocessable_entity,
            resource: {
              error_type: :contract_not_respected,
              error_message: 'The contract for this operation was not respected.',
              meta: {
                errors: contract.errors.messages
              }
            }
          )
        end
      end
    end
  end
end
