# frozen_string_literal: true

module Pragma
  module Operation
    class Response
      class Unauthorized < Response
        def initialize(
          entity: Error.new(
            error_type: :unauthorized,
            error_message: 'This resource requires authentication.',
          ),
          headers: {}
        )
          super(status: 401, entity: entity, headers: headers)
        end
      end
    end
  end
end
