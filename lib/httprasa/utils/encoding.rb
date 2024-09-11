# lib/httprasa/utils/encoding.rb
require 'charlock_holmes'

module Httprasa
  module Utils
    module Encoding
      UTF8 = 'UTF-8'.freeze
      TOO_SMALL_SEQUENCE = 512 # Mirroring charset_normalizer's constant

      def self.detect_encoding(content)
        return UTF8 if content.bytesize <= TOO_SMALL_SEQUENCE

        detection = CharlockHolmes::EncodingDetector.detect(content)
        detection[:encoding] || UTF8
      end

      def self.smart_decode(content, encoding = nil)
        encoding ||= detect_encoding(content)
        decoded = content.force_encoding(encoding).encode(UTF8, invalid: :replace, undef: :replace, replace: '')
        [decoded, encoding]
      end

      def self.smart_encode(content, encoding)
        content.encode(encoding, invalid: :replace, undef: :replace, replace: '')
      end
    end
  end
end