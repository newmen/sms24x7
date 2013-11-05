require File.dirname(__FILE__) + '/spec_helper'

describe SmsApi do
  describe 'Testing sms24x7 api calls' do
    def error_message(variable, filename, line_number = nil)
      msg = "Please setup your #{variable} in spec/#{filename}"
      msg << " at line ##{line_number}" if line_number
      msg
    end

    def check_email_and_password
      SmsApi.email.should_not be_nil, error_message('email', 'spec_helper.rb')
      SmsApi.email.should match(/^([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})$/), error_message('email', 'spec_helper.rb')

      SmsApi.password.should_not be_nil, error_message('password', 'spec_helper.rb')
      SmsApi.password.should_not eq(''), error_message('password', 'spec_helper.rb')
    end

    it 'sending SMS' do
      check_email_and_password

      phone = '' # <- enter here your phone number
      phone.should_not eq(''), error_message('phone number', 'functional_spec.rb', __LINE__ - 1)

      sending_result = SmsApi.push_msg_nologin(phone, 'test passed',
                                               :sender_name => 'RSpec',
                                               :api => '1.1',
                                               :satellite_adv => 'IF_EXISTS')

      sending_result.should have_key('n_raw_sms')
      sending_result.should have_key('credits')
    end

    it 'sending multiple SMS' do
      check_email_and_password

      phones = %w() # <- enter here a few of your phone numbers
      phones.should_not be_empty, error_message('phone numbers', 'functional_spec.rb', __LINE__ - 1)

      SmsApi.login do
        phones.each do |phone|
          sending_result = SmsApi.push_msg_nologin(phone, 'multiple SMS test passed')
          sending_result.should have_key('n_raw_sms')
          sending_result.should have_key('credits')
        end
      end

      SmsApi.cookie.should be_nil
    end

    it 'incorrect email and password' do
      SmsApi.setup do |config|
        config.email = 'test@test.tt'
        config.password = 'T_T'
      end

      expect {
        SmsApi.push_msg_nologin('79991234567', 'wrong')
      }.to raise_error(SmsApi::AuthError)
    end
  end
end
