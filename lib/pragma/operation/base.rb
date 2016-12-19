# frozen_string_literal: true
module Pragma
  module Operation
    class Base
      include Interactor

      STATUSES = {
        100 => :continue,
        101 => :switching_protocols,
        102 => :processing,
        200 => :ok,
        201 => :created,
        202 => :accepted,
        203 => :non_authoritative_information,
        204 => :no_content,
        205 => :reset_content,
        206 => :partial_content,
        207 => :multi_status,
        208 => :already_reported,
        300 => :multiple_choices,
        301 => :moved_permanently,
        302 => :found,
        303 => :see_other,
        304 => :not_modified,
        305 => :use_proxy,
        307 => :temporary_redirect,
        400 => :bad_request,
        401 => :unauthorized,
        402 => :payment_required,
        403 => :forbidden,
        404 => :not_found,
        405 => :method_not_allowed,
        406 => :not_acceptable,
        407 => :proxy_authentication_required,
        408 => :request_timeout,
        409 => :conflict,
        410 => :gone,
        411 => :length_required,
        412 => :precondition_failed,
        413 => :request_entity_too_large,
        414 => :request_uri_too_large,
        415 => :unsupported_media_type,
        416 => :request_range_not_satisfiable,
        417 => :expectation_failed,
        418 => :im_a_teapot,
        422 => :unprocessable_entity,
        423 => :locked,
        424 => :failed_dependency,
        425 => :nocode,
        426 => :upgrade_required,
        428 => :precondition_required,
        429 => :too_many_requests,
        431 => :request_header_fields_too_large,
        449 => :retrywith,
        500 => :internal_server_error,
        501 => :not_implemented,
        502 => :bad_gateway,
        503 => :service_unavailable,
        504 => :gateway_timeout,
        505 => :http_version_not_supported,
        506 => :variant_also_negotiates,
        507 => :insufficient_storage,
        509 => :bandwidth_limit_exceeded,
        510 => :not_extended,
        511 => :network_authentication_required
      }.freeze

      before :setup_context

      around :handle_halt

      after :set_default_status
      after :validate_status
      after :consolidate_status
      after :mark_result

      protected

      def params
        context.params
      end

      def respond_with(status:, resource:)
        context.status = status
        context.resource = resource
      end

      def respond_with!(status:, resource:)
        respond_with status: status, resource: resource
        fail Halt
      end

      def head(status)
        context.status = status
      end

      def head!(status)
        head status
        fail Halt
      end

      private

      def setup_context
        context.params ||= {}
      end

      def handle_halt(interactor)
        interactor.call
      rescue Halt
      end

      def set_default_status
        return if context.status
        context.status = context.resource ? :ok : :no_content
      end

      def validate_status
        if context.status.is_a?(Integer)
          fail InvalidStatusError, context.status unless STATUSES.key?(context.status)
        else
          fail InvalidStatusError, context.status unless STATUSES.invert.key?(context.status.to_sym)
        end
      end

      def conslidate_status
        context.status = if context.status.is_a?(Integer)
          STATUSES[context.status]
        else
          context.status.to_sym
        end
      end

      def mark_result
        return if /\A(2|3)\d{2}\z/ =~ STATUSES.invert[context.status]
        context.fail!
      end

      class InvalidStatusError < StandardError
        def initialize(status)
          super "'#{status}' is not a valid HTTP status code."
        end
      end

      Halt = StandardError
    end
  end
end
