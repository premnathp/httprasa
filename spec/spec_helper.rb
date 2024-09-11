# spec/spec_helper.rb
require 'bundler/setup'
Bundler.require(:default, :development)

$LOAD_PATH.unshift(File.expand_path('../lib', __dir__))
require 'httprasa'
require 'climate_control'

RSpec.configure do |config|
  # ... (keep the existing RSpec configuration)
end