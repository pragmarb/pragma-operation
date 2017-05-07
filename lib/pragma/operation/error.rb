# frozen_string_literal: true

module Pragma
  module Operation
    class Error
      attr_reader :error_type, :error_message, :meta

      def initialize(error_type:, error_message:, meta: {})
        @error_type = error_type
        @error_message = error_message
        @meta = meta
      end
    end
  end
end
