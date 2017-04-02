# frozen_string_literal: true

module Pragma
  module Operation
    class Response
      class NoContent < Response
        def initialize(headers: {})
          super(status: 204, entity: nil, headers: headers)
        end
      end
    end
  end
end
