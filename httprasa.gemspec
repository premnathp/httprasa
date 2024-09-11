# httprasa.gemspec
require_relative 'lib/httprasa/version'

Gem::Specification.new do |spec|
  spec.name          = "httprasa"
  spec.version       = Httprasa::VERSION
  spec.authors       = ["Your Name"]
  spec.email         = ["your.email@example.com"]

  spec.summary       = "A Ruby port of HTTPie"
  spec.description   = "A longer description of your gem"
  spec.homepage      = "https://github.com/yourusername/httprasa"
  spec.license       = "MIT"
  spec.required_ruby_version = Gem::Requirement.new(">= 2.7.0")

  spec.metadata["allowed_push_host"] = "https://rubygems.org"

  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "charlock_holmes", "~> 0.7.7"
  spec.add_development_dependency "rspec", "~> 3.0"
end