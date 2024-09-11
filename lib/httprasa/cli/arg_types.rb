require 'optparse'
require 'io/console'

module Httprasa
  module CLI
    module ArgTypes
      SEPARATOR_CREDENTIALS = ':'
      VALID_SESSION_NAME_PATTERN = /^[a-zA-Z0-9_.-]+$/

      class KeyValueArg
        attr_reader :key, :value, :sep, :orig

        def initialize(key, value, sep, orig)
          @key = key
          @value = value
          @sep = sep
          @orig = orig
        end

        def ==(other)
          self.instance_variables.all? do |iv|
            self.instance_variable_get(iv) == other.instance_variable_get(iv)
          end
        end

        def to_s
          @orig
        end
      end

      class SessionNameValidator
        def initialize(error_message)
          @error_message = error_message
        end

        def call(value)
          if !value.include?(File::SEPARATOR) && !VALID_SESSION_NAME_PATTERN.match?(value)
            raise OptionParser::InvalidArgument, @error_message
          end
          value
        end
      end

      class Escaped < String
        def inspect
          "Escaped(#{super})"
        end
      end

      class KeyValueArgType
        def initialize(*separators)
          @separators = separators
          @special_characters = separators.join.chars.uniq
        end

        def call(s)
          tokens = tokenize(s)
          separators = @separators.sort_by(&:length).reverse

          tokens.each_with_index do |token, i|
            next if token.is_a?(Escaped)

            separators.each do |sep|
              pos = token.index(sep)
              if pos
                key = tokens[0...i].join + token[0...pos]
                value = token[(pos + sep.length)..-1] + tokens[(i + 1)..-1].join
                return KeyValueArg.new(key, value, sep, s)
              end
            end
          end

          raise OptionParser::InvalidArgument, "#{s.inspect} is not a valid value"
        end

        private

        def tokenize(s)
          tokens = ['']
          s.each_char.with_index do |char, i|
            if char == '\\'
              next_char = s[i + 1]
              if @special_characters.include?(next_char)
                tokens << Escaped.new(next_char) << ''
              else
                tokens.last << char << next_char
              end
            else
              tokens.last << char
            end
          end
          tokens
        end
      end

      module PromptMixin
        def prompt_password(prompt)
          print "http: #{prompt}: "
          begin
            STDIN.noecho(&:gets).chomp
          rescue Interrupt
            puts
            exit(0)
          end
        end
      end

      class SSLCredentials
        include PromptMixin

        attr_accessor :value

        def initialize(value)
          @value = value
        end

        def prompt_password(key_file)
          @value = prompt_password("passphrase for #{key_file}")
        end
      end

      class AuthCredentials < KeyValueArg
        include PromptMixin

        def has_password?
          !@value.nil?
        end

        def prompt_password(host)
          @value = prompt_password("password for #{@key}@#{host}")
        end
      end

      class AuthCredentialsArgType < KeyValueArgType
        def call(s)
          super
        rescue OptionParser::InvalidArgument
          AuthCredentials.new(s, nil, SEPARATOR_CREDENTIALS, s)
        end
      end

      def self.parse_auth
        AuthCredentialsArgType.new(SEPARATOR_CREDENTIALS)
      end

      def self.readable_file_arg(filename)
        File.open(filename, 'rb') { |f| f.read(1) }
        filename
      rescue SystemCallError => e
        raise OptionParser::InvalidArgument, "#{e.message}"
      end

      def self.parse_format_options(s, defaults)
        options = defaults ? defaults.dup : {}
        s.split(',').each do |option|
          path, value = option.downcase.split(':')
          section, key = path.split('.')

          parsed_value = case value
                         when 'true' then true
                         when 'false' then false
                         when /^\d+$/ then value.to_i
                         else value
                         end

          options[section] ||= {}
          if defaults && defaults.dig(section, key)
            unless parsed_value.is_a?(defaults[section][key].class)
              raise OptionParser::InvalidArgument, "Invalid value #{value.inspect} in #{option.inspect}"
            end
          end

          options[section][key] = parsed_value
        end
        options
      end

      def self.response_charset_type(encoding)
        ''.encode(encoding)
        encoding
      rescue Encoding::ConverterNotFoundError
        raise OptionParser::InvalidArgument, "#{encoding.inspect} is not a supported encoding"
      end

      def self.response_mime_type(mime_type)
        raise OptionParser::InvalidArgument, "#{mime_type.inspect} doesn't look like a mime type" unless mime_type.count('/') == 1
        mime_type
      end
    end
  end
end