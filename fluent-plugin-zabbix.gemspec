# -*- encoding: utf-8 -*-
# -*- mode:ruby -*-

Gem::Specification.new do |gem|
  gem.authors       = ["FUJIWARA Shunichiro"]
  gem.email         = ["fujiwara.shunichiro@gmail.com"]
  gem.description   = %q{Output data plugin to Zabbix}
  gem.summary       = %q{Output data plugin to Zabbix (like zabbix_sender)}
  gem.homepage      = "https://github.com/fujiwara/fluent-plugin-zabbix"

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "fluent-plugin-zabbix"
  gem.require_paths = ["lib"]
  gem.version       = "0.0.5"

  gem.add_runtime_dependency "fluentd", "~> 0.10"
  gem.add_runtime_dependency "zabbix", ">= 0.4"
  gem.add_development_dependency "rake", ">= 0.9.2"
  gem.add_development_dependency "glint", "= 0.0.2"
end
