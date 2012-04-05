# -*- encoding: utf-8 -*-
require File.expand_path('../lib/sms24x7/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Gleb Averchuk"]
  gem.email         = ["altermn@gmail.com"]
  gem.description   = %q{TODO: Sending SMS via sms24x7 API}
  gem.summary       = %q{TODO: Uses sms24x7 gateway for sending SMS}
  gem.homepage      = "https://github.com/newmen/sms24x7"

  gem.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  gem.files         = `git ls-files`.split("\n")
  gem.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  gem.name          = "sms24x7"
  gem.require_paths = ["lib"]
  gem.version       = SmsApi::VERSION

  gem.add_dependency 'curb-fu'
  gem.add_dependency 'json'
end
