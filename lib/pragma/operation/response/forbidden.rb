# frozen_string_literal: true

module Pragma
  module Operation
    class Response
      class Forbidden < Response
        def initialize(
          entity: {
            error_type: :forbidden,
            error_message: 'You are not authorized to access the requested resource.'
          },
          headers: {}
        )
          super(status: 403, entity: entity, headers: headers)
        end
      end
    end
  end
end
