# lib/httprasa/version.rb

module Httprasa
    VERSION = "0.1.0"
  
    def self.version
      VERSION
    end
  
    def self.user_agent
      "HTTPrasa/#{VERSION}"
    end
  
    # You can add more version-related methods if needed, for example:
    def self.major_version
      VERSION.split('.').first.to_i
    end
  
    def self.minor_version
      VERSION.split('.')[1].to_i
    end
  
    def self.patch_version
      VERSION.split('.').last.to_i
    end
end