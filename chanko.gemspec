lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "chanko/version"

Gem::Specification.new do |gem|
  gem.name          = "chanko"
  gem.version       = Chanko::VERSION
  gem.authors       = ["MORITA shingo", "Ryo Nakamura"]
  gem.email         = ["tech@cookpad.com"]
  gem.description   = "Chanko is a Rails extension tool"
  gem.summary       = "Rails extension tool"
  gem.homepage      = "https://github.com/cookpad/chanko"

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]
  gem.required_ruby_version = '>= 2.6.0'

  gem.add_dependency "rails", ">= 5.0.0"
  gem.add_development_dependency "byebug"
  gem.add_development_dependency "coffee-rails", ">= 3.0.10"
  gem.add_development_dependency "jquery-rails"
  gem.add_development_dependency "pry"
  gem.add_development_dependency "pry-rails"
  gem.add_development_dependency "rspec-rails", ">= 3.0.0"
  gem.add_development_dependency "sass-rails", ">= 3.0.10"
  gem.add_development_dependency "simplecov"
  gem.add_development_dependency 'simplecov-lcov'
  gem.add_development_dependency "slim"
  gem.add_development_dependency "sqlite3"
  gem.add_development_dependency "thin"
  gem.add_development_dependency "uglifier"
end
