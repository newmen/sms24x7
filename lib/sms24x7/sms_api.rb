require 'curb-fu'
require 'json'
require 'active_support/core_ext/module/attribute_accessors'

module SmsApi
  SMS_HOST = 'api.sms24x7.ru'
  API_VERSION = '1.1'

  class BaseError < ::StandardError; end
  class AccountBlockedError < BaseError; end
  class AccountNotFoundError < BaseError; end
  class ActionRejectedError < BaseError; end
  class ApiVersionError < BaseError; end
  class ArgumentsError < BaseError; end
  class AuthError < BaseError; end
  class BalanceError < BaseError; end
  class DeliveryError < BaseError; end
  class DomainBusyError < BaseError; end
  class EncodingError < BaseError; end
  class InterfaceError < BaseError; end
  class InternalError < BaseError; end
  class MessagesNotDeliveryError < BaseError; end
  class NoGateError < BaseError; end
  class NoLoginError < BaseError; end
  class OtherError < BaseError; end
  class PasswordError < BaseError; end
  class SaveError < BaseError; end
  class SenderNameError < BaseError; end
  class SessionExpiredError < BaseError; end
  class SpamError < BaseError; end
  class TarifNotFoundError < BaseError; end
  class TimeoutError < BaseError; end
  class UnauthorizedPartnerError < BaseError; end
  class UndefinedError < BaseError; end

  # Login info
  mattr_accessor :email
  mattr_accessor :password

  # Session cookie
  mattr_reader :cookie

  module_function

  def setup
    yield self
  end

  # Public: Sends request to API
  #
  # request - Associative array to pass to API, :format key will be overridden
  # cookie - Cookies string to be passed
  #
  # Returns:
  # {
  #   :error_code => error_code,
  #   :data => data
  # }
  # If response was OK, data is an associative array, error_code is an error numeric code.
  # Otherwise exception will be raised.
  #
  def _communicate(request, cookie = nil, secure = true)
    request[:format] = 'json'
    protocol = secure ? 'https' : 'http'
    curl = CurbFu.post({ :host => SMS_HOST, :protocol => protocol }, request) do |curb|
      curb.cookies = cookie if cookie
    end
    raise InterfaceError, 'cURL request failed' unless curl.success?

    json = JSON.parse(curl.body)
    unless (response = json['response']) && (msg = response['msg']) && (error_code = msg['err_code'])
      raise InterfaceError, 'Empty some necessary data fields'
    end

    error_code = error_code.to_i
    if error_code > 0
      raise_error = -> error, text { raise error, msg['text'] || text }

      case error_code
        when 2 then raise_error[AuthError, 'Wrong login or password']
        when 3 then raise_error[TimeoutError, 'You have been inactive for more than 24 minutes']

        when 4 then raise_error[AccountBlockedError, 'Your account is blocked']
        when 5 then raise_error[UndefinedError, 'Undefined method']
        when 6 then raise_error[ApiVersionError, 'Wrong API version']
        when 7 then raise_error[ArgumentsError, 'Not all necessary parameters are set']
        when 10 then raise_error[UnauthorizedPartnerError, 'Partner is not authorized']
        when 11 then raise_error[SaveError, 'Error saving']
        when 15 then raise_error[ActionRejectedError, 'Action rejected']
        when 16 then raise_error[PasswordError, 'Wrong password']
        when 18 then raise_error[SessionExpiredError, 'Session expired']
        when 19 then raise_error[InternalError, 'Internal operator error']

        when 22 then raise_error[AccountNotFoundError, 'Account is not found']

        when 29 then raise_error[NoGateError, 'Mobile operator gateway is not connected']
        when 35 then raise_error[EncodingError, 'Wrong encoding']
        when 36 then raise_error[BalanceError, 'Not enough money']
        when 37, 38, 59 then raise_error[SpamError, 'Spam detected']

        when 39 then raise_error[SenderNameError, 'Invalid sender name']
        when 40 then raise_error[DeliveryError, 'Undeliverable']
        when 42 then raise_error[NoLoginError, 'Login to continue']

        when 43 then raise_error[DomainBusyError, 'Domain busy']
        when 45 then raise_error[BaseError, 'Basic settings is not found']
        when 44, 47 then raise_error[TarifNotFoundError, 'Tarif is not found']

        when 58 then raise_error[MessagesNotDeliveryError, 'Messages are not delivered']

        else raise_error[OtherError, "Communication to API failed. Error code: #{error_code}"]
      end
    end

    { :error_code => error_code, :data => response['data'] }
  end

  # Public: Sends a message via sms24x7 API, combining authenticating and sending message in one request.
  #
  # phone - Recipient phone number in international format (like 7xxxyyyzzzz)
  # text - Message text, ASCII or UTF-8.
  # params - Additional parameters as key => value array, see API doc.
  #
  # Returns:
  # {
  #   :n_raw_sms => n_raw_sms, - Number of SMS parts in message
  #   :credits => credits - Price for a single part
  # }
  #
  def push_msg_nologin(phone, text, params = {})
    request = {
        :api => API_VERSION,
        :method => 'push_msg',
        :email => @@email,
        :password => @@password,
        :phone => phone,
        :text => text
    }.merge(params)
    responce = _communicate(request)
    check_and_result_push_msg(responce)
  end

  # Public: Logs in API, producing a session ID to be sent back in session cookie.
  #
  # Returns:
  # cookie - Is a string "sid=#{session_id}" to be passed to cURL if no block given
  #
  def login
    request = {
        :api => API_VERSION,
        :method => 'login',
        :email => @@email,
        :password => @@password
    }
    responce = _communicate(request)
    raise InterfaceError, "Login request OK, but no 'sid' set" unless (sid = responce[:data]['sid'])
    @@cookie = "sid=#{CGI::escape(sid)}"

    if block_given?
      yield
      @@cookie = nil
    end

    @@cookie
  end

  # Public: Sends message via API, using previously obtained cookie to authenticate.
  # That is, must first call the login method.
  #
  # phone - Target phone
  # text - Message text, ASCII or UTF-8
  # params - Dictionary of optional parameters, see API documentation of push_msg method
  #
  # Returns:
  # {
  #   :n_raw_sms => n_raw_sms, - Number of SMS parts in message
  #   :credits => credits - Price for a single part
  # }
  #
  def push_msg(phone, text, params = {})
    raise NoLoginError, 'Must first call the login method' unless @@cookie
    request = {
        :api => API_VERSION,
        :method => 'push_msg',
        :phone => phone,
        :text => text
    }.merge(params)
    responce = _communicate(request, @@cookie)
    check_and_result_push_msg(responce)
  end

  # Private: Check the responce to a required fields. And formation of the resulting hash.
  #
  # responce - Result of _communicate method
  #
  # Returns:
  # {
  #   :n_raw_sms => n_raw_sms, - Number of SMS parts in message
  #   :credits => credits - Price for a single part
  # }
  #
  def check_and_result_push_msg(responce)
    data = responce[:data]
    unless (n_raw_sms = data['n_raw_sms']) && (credits = data['credits'])
      raise InterfaceError, "Could not find 'n_raw_sms' or 'credits' in successful push_msg response"
    end
    data
  end
end
