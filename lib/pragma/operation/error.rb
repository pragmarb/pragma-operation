module Pragma
  module Operation
    class Error
      def initialize(error_type:, error_message:, meta: {})
        @error_type = error_type
        @error_message = error_message
        @meta = meta
      end
    end
  end
end
