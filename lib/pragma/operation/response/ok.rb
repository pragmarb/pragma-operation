# frozen_string_literal: true

module Pragma
  module Operation
    class Response
      class Ok < Response
        def initialize(entity: nil, headers: {})
          super(status: 200, entity: entity, headers: headers)
        end
      end
    end
  end
end
