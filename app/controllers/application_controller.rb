# Copyright (c) 2009-2011 Cyril Rohr, INRIA Rennes - Bretagne Atlantique
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

class ApplicationController < ActionController::Base
  include ApplicationHelper

  before_filter :lookup_credentials
  before_filter :parse_json_payload, :only => [:create, :update, :destroy]
  before_filter :set_default_format

  # abasu : additional classes introduced to handle all possible exceptions - 02.04.2015
  # abasu : as per status codes https://api.grid5000.fr/doc/stable/reference/spec.html
  # abasu : class & subclasses to handle client-side exceptions (Error codes 4xx)
  class ClientError < ActionController::ActionControllerError; end
  class BadRequest < ClientError; end             # Error code 400
  class AuthorizationRequired < ClientError; end  # Error code 401
  class Forbidden < ClientError; end              # Error code 403
  class NotFound < ClientError; end               # Error code 404
  class MethodNotAllowed < ClientError; end       # Error code 405
  class NotAcceptable < ClientError; end          # Error code 406
  class PreconditionFailed < ClientError; end     # Error code 412

  # abasu : class & subclasses to handle server-side exceptions (Error codes 5xx)
  class ServerError < ActionController::ActionControllerError; end
  class UnsupportedMediaType < ServerError; end   # Error code 415 (moved to server-side)
  class BadGateway < ServerError; end             # Error code 50x (to be refined later)

  # This thing must alway come first, or it will override other rescue_from.
  rescue_from Exception, :with => :server_error

  # abasu : exception-handlers for client-side exceptions - 02.04.2015
  rescue_from BadRequest, :with => :bad_request                        # for 400
  rescue_from AuthorizationRequired, :with => :authorization_required  # for 401
  rescue_from Forbidden, :with => :forbidden                           # for 403
  rescue_from NotFound, :with => :not_found                            # for 404
  rescue_from ActiveRecord::RecordNotFound, :with => :not_found        # for 404
  rescue_from MethodNotAllowed, :with => :method_not_allowed           # for 405
  rescue_from NotAcceptable, :with => :not_acceptable                  # for 406
  rescue_from PreconditionFailed, :with => :precondition_failed        # for 412

  # abasu : exception-handlers for client-side exceptions - 02.04.2015
  rescue_from UnsupportedMediaType, :with => :server_error             # for 415
  # abasu : agreed to send exception to server_error (instead of unsupported_media_type)
  rescue_from ServerError, :with => :server_error                      # for 500
  rescue_from BadGateway, :with => :bad_gateway                        # for 502

  protected
  def set_default_format
    params[:format] ||= begin
      first_mime_type = (
        (request.accept || "").split(",")[0] || ""
      ).split(";")[0]
      Mime::Type.lookup(first_mime_type).to_sym || :g5kjson
    end
  end

  def lookup_credentials
    invalid_values = ["", "unknown", "(unknown)"]
    cn = request.env["HTTP_#{Rails.my_config(:header_user_cn).gsub("-","_").upcase}"] ||
      ENV["HTTP_#{Rails.my_config(:header_user_cn).gsub("-","_").upcase}"]
    if cn.nil? || invalid_values.include?(cn)
      @credentials = {
        :cn => nil,
        :privileges => []
      }
    else
      @credentials = {
        :cn => cn.downcase,
        :privileges => []
      }
    end
  end

  def ensure_authenticated!
    @credentials[:cn] || raise(Forbidden)
  end

  def authorize!(user_id)
    raise Forbidden if user_id != @credentials[:cn]
  end

  # Analyses the response status of the given HTTP response.
  #
  # Raise BadGateway if status is 0.
  # Raise ServerError if status is not in the expected status codes in options[:is] .
  def continue_if!(http, options = {})
    # Allow the list of "non-error" http codes
    allowed_status = [options[:is] || (200..299).to_a].flatten

    status = http.response_header.status  # get the status from the http response

    if status.between?(400, 599) # error status
      # http.method always returns nil. Bug?
      # msg = "#{http.method} #{http.uri} failed with status #{status}"
      msg = "Request to #{http.uri.to_s} failed with status #{status}: #{http.response}"
      Rails.logger.error msg
    end

    case status
      when *allowed_status   # Status codes (200, ..., 299)
        true
      when 400
        raise BadRequest, msg
      when 401
        raise AuthorizationRequired, msg
      when 403
        raise Forbidden, msg
      when 404
        raise NotFound, msg
      when 405
        raise MethodNotAllowed, msg
      when 406
        raise NotAcceptable, msg
      when 412
        raise PreconditionFailed, msg
      when 415
        raise UnsupportedMediaType, msg
      when 502
        raise BadGateway, msg
      else
        msg = "Request to #{http.uri.to_s} failed with status #{status}: #{http.response}"
        raise ServerError, msg
    end
  end

  # Automatically parse JSON payload when request content type is JSON
  def parse_json_payload
    if request.content_type =~ /application\/.*json/i
      json = JSON.parse(request.body.read)
      params.merge!(json)
    end
  ensure
    request.body.rewind
  end

  def render_error(exception, options = {})
    log_exception(exception)
    message = options[:message] || exception.message
    render  :text => message,
            :status => options[:status],
            :content_type => 'text/plain'
  end

  def log_exception(exception)
    Rails.logger.warn exception.message
    Rails.logger.debug exception.backtrace.join(";")
  end

  # ===============
  # = HTTP Errors =
  # ===============
  # abasu : Most of the new methods added are just stubs for introduced for
  # abasu : the sake of completeness  of HTTP error codes handling.
  # abasu : If such error conditions become prominent in the the future,
  # abasu : they should be overloaded in subclasses.
  def bad_request(exception)
    opts = {:status => 400}
    opts[:message] = "Bad Request" if exception.message == exception.class.name
    render_error(exception, opts)
  end

  def authorization_required(exception)
    opts = {:status => 401}
    opts[:message] = "Authorization Required" if exception.message == exception.class.name
    render_error(exception, opts)
  end

  def forbidden(exception)
    opts = {:status => 403}
    opts[:message] = "You are not authorized to access this resource" if exception.message == exception.class.name
    render_error(exception, opts)
  end

  def not_found(exception)
    opts = {:status => 404}
    opts[:message] = "Not Found" if exception.message == exception.class.name
    render_error(exception, opts)
  end

  def method_not_allowed(exception)
    opts = {:status => 405}
    opts[:message] = "Method Not Allowed" if exception.message == exception.class.name
    render_error(exception, opts)
  end

  def not_acceptable(exception)
    opts = {:status => 406}
    opts[:message] = "Not Acceptable" if exception.message == exception.class.name
    render_error(exception, opts)
  end

  def precondition_failed(exception)
    opts = {:status => 412}
    opts[:message] = "Precondition Failed" if exception.message == exception.class.name
    render_error(exception, opts)
  end

  def unsupported_media_type(exception)
    opts = {:status => 415}
    opts[:message] = "Unsupported Media Type" if exception.message == exception.class.name
    render_error(exception, opts)
  end

  def server_error(exception)
    opts = {:status => 500}
    opts[:message] = "Internal Server Error" if exception.message == exception.class.name
    render_error(exception, opts)
  end

  def bad_gateway(exception)
    opts = {:status => 502}
    opts[:message] = "Bad Gateway" if exception.message == exception.class.name
    render_error(exception, opts)
  end

  # ================
  # = HTTP Headers =
  # ================
  def allow(*args)
    response.headers['Allow'] = args.flatten.map{|m| m.to_s.upcase}.join(",")
  end
  def vary_on(*args)
    response.headers['Vary'] ||= ''
    response.headers['Vary'] = [
      response.headers['Vary'].split(","),
      args
    ].flatten.join(",")
  end
  def etag(*args)
    response.etag = args.join(".")
  end
  def last_modified(time)
    response.last_modified = time.utc
  end

  # ===========
  # = Payload =
  # ===========
  def payload
    params.reject{ |k,v| %w{site_id id format controller action}.include?(k) }
  end
end
