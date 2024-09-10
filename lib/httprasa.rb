# lib/httprasa.rb

# Require core functionality
require_relative 'httprasa/core'
require_relative 'httprasa/exit_status'

# Main module for the Httprasa application
module Httprasa
  VERSION = '0.1.0'

  # Add any global configuration or initialization here
  def self.setup
    # Initialize any necessary components or configurations
  end
end

# Call setup method to initialize the application
Httprasa.setup