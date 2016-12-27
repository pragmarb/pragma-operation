# frozen_string_literal: true
module Pragma
  module Operation
    # Provides integration with {https://github.com/pragmarb/pragma-policy Pragma::Policy}.
    #
    # @author Alessandro Desantis
    module Authorization
      def self.included(base)
        base.extend ClassMethods
        base.include InstanceMethods
      end

      module ClassMethods # :nodoc:
        # Sets the policy to use for authorizing this operation.
        #
        # @param klass [Class] a subclass of +Pragma::Policy::Base+
        def policy(klass)
          @policy = klass
        end

        # Returns the policy class.
        #
        # @return [Class]
        def policy_klass
          @policy
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
          policy_klass.new(user: user, resource: resource)
        end
      end

      module InstanceMethods # :nodoc:
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
        # If no policy was defined, simply returns true.
        #
        # @param authorizable [Pragma::Policy::Base|Object] resource or policy
        #
        # @return [Boolean] whether the operation is authorized
        def authorize(authorizable)
          return true unless self.class.policy_klass

          policy = if authorizable.is_a?(self.class.policy_klass)
            authorizable
          else
            build_policy(authorizable)
          end

          policy.send("#{self.class.operation_name}?")
        end

        # Authorizes this operation on the provided resource or policy. If the user is not
        # authorized to perform the operation, responds with 403 Forbidden and an error body and
        # halts the execution.
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
      end
    end
  end
end
