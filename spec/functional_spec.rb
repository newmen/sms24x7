require File.dirname(__FILE__) + '/spec_helper'

describe SmsApi do
  describe 'Testing sms24x7 api calls' do
    it 'sending SMS' do
      email = 'your@email.com'
      password = 'your_password'
      phone = '79991234567' # your phone

      email.should match(/^([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})$/), 'We need your email'
      password.should_not eq(''), 'We need your password'
      phone.should_not eq(''), 'We need your phone number'

      sending_result = SmsApi.push_msg_nologin(email, password, phone, 'test passed',
                                               :sender_name => 'RSpec',
                                               :api => '1.1',
                                               :satellite_adv => 'IF_EXISTS')

      sending_result.should have_key('n_raw_sms')
      sending_result.should have_key('credits')
    end

    it 'incorrect email and password' do
      lambda {
        SmsApi.push_msg_nologin('test@test.tt', 'T_T', '79991234567', 'wrong')
      }.should raise_error(SmsApi::AuthError)
    end
  end
end
