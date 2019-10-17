# -*- encoding: utf-8 -*-
# -*- mode:ruby -*-

Gem::Specification.new do |gem|
  gem.authors       = ["FUJIWARA Shunichiro"]
  gem.email         = ["fujiwara.shunichiro@gmail.com"]
  gem.description   = %q{Output data plugin to Zabbix}
  gem.summary       = %q{Output data plugin to Zabbix (like zabbix_sender)}
  gem.homepage      = "https://github.com/fujiwara/fluent-plugin-zabbix"
  gem.license       = "Apache-2.0"

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "fluent-plugin-zabbix"
  gem.require_paths = ["lib"]
  gem.version       = "0.3.0"

  gem.add_runtime_dependency "fluentd", [">= 0.14.8", "< 2"]
  gem.add_runtime_dependency "yajl-ruby", "~> 1.0"
  gem.add_runtime_dependency "fluent-mixin-config-placeholders", "~> 0.3"
  gem.add_development_dependency "rake", ">= 0.9.2"
  gem.add_development_dependency "glint", "= 0.1.0"
  gem.add_development_dependency "test-unit", ">= 3.1.0"
end
