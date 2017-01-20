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
        #
        # @yield A block which will be called with the operation's context which should return
        #   the policy class. The block can also return +nil+ if authorization should be skipped.
        def policy(klass = nil, &block)
          if !klass && !block_given?
            fail ArgumentError, 'You must pass either a policy class or a block'
          end

          @policy = klass || block
        end

        # Returns the policy class.
        #
        # @return [Class]
        def policy_klass
          @policy
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
          policy_klass = compute_policy_klass
          return resource unless policy_klass

          policy_klass.new(user: current_user, resource: resource)
        end

        # Authorizes this operation on the provided resource or policy.
        #
        # If no policy was defined, simply returns true.
        #
        # @param authorizable [Pragma::Policy::Base|Object] resource or policy
        #
        # @return [Boolean] whether the operation is authorized
        def authorize(authorizable)
          return true unless compute_policy_klass

          # rubocop:disable Metrics/LineLength
          policy = if Object.const_defined?('Pragma::Policy::Base') && authorizable.is_a?(Pragma::Policy::Base)
            authorizable
          else
            build_policy(authorizable)
          end
          # rubocop:enable Metrics/LineLength

          params.each_pair do |name, value|
            next unless policy.resource.respond_to?("#{name}=")
            policy.resource.send("#{name}=", value)
          end

          policy.send("#{self.class.operation_name}?").tap do |result|
            after_authorization result
          end
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

        # Runs after authorization is done.
        #
        # @param result [Boolean] the result of the authorization
        def after_authorization(result)
        end

        # Scopes the provided collection.
        #
        # If no policy class is defined, simply returns the collection.
        #
        # @param collection [Enumerable]
        #
        # @return [Pragma::Decorator::Base|Enumerable]
        def authorize_collection(collection)
          policy_klass = compute_policy_klass
          return collection unless policy_klass

          policy_klass.accessible_by(
            user: current_user,
            scope: collection
          )
        end

        def compute_policy_klass
          if self.class.policy_klass.is_a?(Proc)
            self.class.policy_klass.call(context)
          else
            self.class.policy_klass
          end
        end
      end
    end
  end
end
