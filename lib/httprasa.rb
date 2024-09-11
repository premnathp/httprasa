# lib/httprasa.rb

require_relative 'httprasa/core'
require_relative 'httprasa/exit_status'
require_relative 'httprasa/config'
require_relative 'httprasa/version'
require_relative 'httprasa/utils/encoding'
require_relative 'httprasa/ui/palette'
require_relative 'httprasa/internal/daemon_runner'
require_relative 'httprasa/cli/definition'

# Main module for the Httprasa application
module Httprasa
  # Add any global configuration or initialization here
  def self.setup
    # Initialize any necessary components or configurations
  end
end

# Call setup method to initialize the application
Httprasa.setup