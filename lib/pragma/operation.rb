# frozen_string_literal: true

require 'json'

require 'trailblazer/operation'

require 'pragma/operation/version'
require 'pragma/operation/base'
require 'pragma/operation/error'

require 'pragma/operation/response'
require 'pragma/operation/response/bad_request'
require 'pragma/operation/response/not_found'
require 'pragma/operation/response/forbidden'
require 'pragma/operation/response/unprocessable_entity'
require 'pragma/operation/response/created'
require 'pragma/operation/response/ok'
require 'pragma/operation/response/no_content'
require 'pragma/operation/response/unauthorized'
require 'pragma/operation/response/service_unavailable'
require 'pragma/operation/response/internal_server_error'
require 'pragma/operation/response/conflict'
require 'pragma/operation/response/payment_required'

module Pragma
  # Operations provide business logic encapsulation for your JSON API.
  #
  # @author Alessandro Desantis
  module Operation
  end
end
