require File.dirname(__FILE__) + '/spec_helper'

describe SmsApi do
  describe 'Testing sms24x7 api calls' do
    it 'sending SMS' do

      phone = '79991234567' # your phone

      SmsApi.email.should match(/^([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})$/), 'We need your email'
      SmsApi.password.should_not eq(''), 'We need your password'
      phone.should_not eq(''), 'We need your phone number'

      sending_result = SmsApi.push_msg_nologin(phone, 'test passed',
                                               :sender_name => 'RSpec',
                                               :api => '1.1',
                                               :satellite_adv => 'IF_EXISTS')

      sending_result.should have_key('n_raw_sms')
      sending_result.should have_key('credits')
    end

    it 'sending multiple SMS' do
      SmsApi.email.should match(/^([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})$/), 'We need your email'
      SmsApi.password.should_not eq(''), 'We need your password'

      phones = %w(79991234567 79991234568)

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

      lambda {
        SmsApi.push_msg_nologin('79991234567', 'wrong')
      }.should raise_error(SmsApi::AuthError)
    end
  end
end
