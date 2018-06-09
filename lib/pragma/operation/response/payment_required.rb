# frozen_string_literal: true

module Pragma
  module Operation
    class Response
      class PaymentRequired < Response
        def initialize(
          entity: Error.new(
            error_type: :payment_required,
            error_message: 'This resource requires payment.'
          ),
          headers: {}
        )
          super(status: 402, entity: entity, headers: headers)
        end
      end
    end
  end
end
