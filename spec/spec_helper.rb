$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'sms24x7'
require 'rspec'

SmsApi.setup do |config|
  config.email = 'your@email.com'
  config.password = 'your_password'
end
