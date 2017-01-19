# frozen_string_literal: true
module Pragma
  module Operation
    # Provides integration with {https://github.com/pragmarb/pragma-decorator Pragma::Decorator}.
    #
    # @author Alessandro Desantis
    module Decoration
      def self.included(base)
        base.extend ClassMethods
        base.include InstanceMethods
      end

      module ClassMethods # :nodoc:
        # Sets the decorator to use for decorating this operation.
        #
        # @param klass [Class] a subclass of +Pragma::Decorator::Base+
        #
        # @yield A block which will be called with the operation's context which should return
        #   the decorator class. The block can also return +nil+ if decoration should be skipped.
        def decorator(klass = nil, &block)
          if !klass && !block_given?
            fail ArgumentError, 'You must pass either a decorator class or a block'
          end

          @decorator = klass || block
        end

        # Returns the decorator class.
        #
        # @return [Class]
        def decorator_klass
          @decorator
        end
      end

      module InstanceMethods # :nodoc:
        # Builds the decorator for the given resource, using the previously defined decorator class.
        #
        # This is just an instance-level alias of {.build_decorator}. You should use this from
        # inside the operation.
        #
        # @param resource [Object]
        #
        # @return [Pragma::Decorator::Base]
        #
        # @see #decorate
        def build_decorator(resource)
          resource = resource.to_a if resource.is_a?(Enumerable)
          compute_decorator_klass.represent(resource)
        end

        # If a decorator is defined, acts as an alias for {#build_decorator}. If not, simply returns
        # the provided resource.
        # @param decoratable [Object]
        #
        # @return [Pragma::Decorator::Base|Object]
        #
        # @see #build_decorator
        def decorate(decoratable)
          return decoratable unless compute_decorator_klass
          build_decorator(decoratable)
        end

        private

        def compute_decorator_klass
          if self.class.decorator_klass.is_a?(Proc)
            self.class.decorator_klass.call(context)
          else
            self.class.decorator_klass
          end
        end
      end
    end
  end
end
