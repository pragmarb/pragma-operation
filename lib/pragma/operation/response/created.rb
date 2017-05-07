# frozen_string_literal: true

module Pragma
  module Operation
    class Response
      class Created < Response
        def initialize(entity: nil, headers: {})
          super(status: 201, entity: entity, headers: headers)
        end
      end
    end
  end
end
