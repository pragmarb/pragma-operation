# frozen_string_literal: true

module Pragma
  module Operation
    class Response
      class ServiceUnavailable < Response
        def initialize(
          entity: Error.new(
            error_type: :service_unavailable,
            error_message: 'This resource is not available right now. Try later.'
          ),
          headers: {}
        )
          super(status: 503, entity: entity, headers: headers)
        end
      end
    end
  end
end
