# lib/httprasa/exit_status.rb

module Httprasa
    module ExitStatus
      SUCCESS = 0
      ERROR = 1
      ERROR_CTRL_C = 130
  
      def self.value_to_name(value)
        constants.find { |name| const_get(name) == value }
      end
    end
  end