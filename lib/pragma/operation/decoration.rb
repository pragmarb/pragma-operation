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
        # Sets the decorator to use for validating this operation.
        #
        # @param klass [Class] a subclass of +Pragma::Decorator::Base+
        def decorator(klass)
          @decorator = klass
        end

        # Returns the decorator class.
        #
        # @return [Class]
        def decorator_klass
          @decorator
        end

        # Builds the decorator for the given resource, using the previously defined decorator class.
        #
        # Works with both singular resources and collections.
        #
        # @param resource [Object]
        #
        # @return [Pragma::Decorator::Base]
        #
        # @see #decorator
        def build_decorator(resource)
          decorator_klass.represent(resource)
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
          self.class.build_decorator(resource)
        end

        # If a decorator is defined, acts as an alias for {#build_decorator}. If not, simply returns
        # the provided resource.
        # @param decoratable [Object]
        #
        # @return [Pragma::Decorator::Base|Object]
        #
        # @see #build_decorator
        def decorate(decoratable)
          return true unless self.class.decorator_klass
          build_decorator(decoratable)
        end
      end
    end
  end
end
