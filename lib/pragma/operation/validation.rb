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
        # If no contract has been defined for this operation, simply returns the resource.
        #
        # @param resource [Object]
        #
        # @return [Pragma::Contract::Base]
        #
        # @see #contract
        def build_contract(resource)
          return resource unless contract_klass
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
        # If no contract has been defined for this operation, tries to call +#validate+ on the
        # resource. If the resource does not respond to +#validate+, returns true.
        #
        # @param validatable [Object|Pragma::Contract::Base] contract or resource
        #
        # @return [Boolean] whether the operation is valid
        def validate(validatable)
          contract = if self.class.contract_klass && validatable.is_a?(self.class.contract_klass)
            validatable
          else
            build_contract(validatable)
          end
          # rubocop:enable Metrics/LineLength

          if contract.is_a?(Pragma::Contract::Base)
            contract.validate(params)
          else
            contract.respond_to?(:validate) ? contract.validate : true
          end
        end

        # Validates this operation on the provided contract or resource. If the operation is not
        # valid, responds with 422 Unprocessable Entity and an error body and halts the execution.
        #
        # @param validatable [Object|Pragma::Contract::Base] contract or resource
        def validate!(validatable)
          contract = if self.class.contract_klass && validatable.is_a?(self.class.contract_klass)
            validatable
          else
            build_contract(validatable)
          end
          # rubocop:enable Metrics/LineLength

          respond_with_validation_errors!(contract) unless validate(contract)
        end

        # Sets a response suitable for reporting validation errors.
        #
        # The response will be a 422 Unprocessable Entity, contain the +error_type+, +error_message+
        # and +meta+ keys. +meta.errors+ will contain the validation errors.
        #
        # @param validatable [Object] a validatable object
        def respond_with_validation_errors(validatable)
          respond_with validation_errors_response(validatable)
        end

        # Same as {#respond_with_validation_errors}, but also halts the execution of the operation.
        #
        # @param validatable [Object] a validatable object
        #
        # @see #respond_with_validation_errors
        def respond_with_validation_errors!(validatable)
          respond_with! validation_errors_response(validatable)
        end

        private

        def validation_errors_response(validatable)
          {
            status: :unprocessable_entity,
            resource: {
              error_type: :contract_not_respected,
              error_message: 'The contract for this operation was not respected.',
              meta: {
                errors: validatable.errors.messages
              }
            }
          }
        end
      end
    end
  end
end
