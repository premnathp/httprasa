require 'optparse'
require 'ostruct'
require 'uri'
require_relative '../constants'
require_relative 'arg_types'
require_relative '../request_items'

module Httprasa
  module CLI
    class ArgParser < OptionParser
      attr_reader :args

      def initialize
        super
        @args = OpenStruct.new(
          request_items: [],
          headers: {},
          data: nil,
          files: {},
          params: {},
          output_options: nil,
          verbose: false,
          json: false,
          form: false,
          multipart: false,
          auth: nil,
          default_scheme: 'http'
        )
        setup_options
      end

      def parse!(argv)
        super(argv) do |arg|
          @args.request_items << arg
        end
        process_args
        @args
      end

      private

      def setup_options
        on('-j', '--json', 'Data items are serialized as a JSON object') { @args.json = true }
        on('-f', '--form', 'Data items are serialized as form fields') { @args.form = true }
        on('-v', '--verbose', 'Verbose output') { @args.verbose = true }
        on('-a', '--auth USER[:PASS]', 'Authentication credentials') { |auth| @args.auth = auth }
        # Add more options as needed...
      end

      def process_args
        extract_url_and_method
        process_request_type
        process_url
        guess_method
        process_auth
        process_output_options
        parse_request_items
      end

      def extract_url_and_method
        if @args.request_items.first && @args.request_items.first =~ /^[A-Z]+$/
          @args.method = @args.request_items.shift
        end
        @args.url = @args.request_items.shift
      end

      def process_request_type
        @args.request_type = if @args.json
                               RequestType::JSON
                             elsif @args.form || @args.multipart
                               RequestType::FORM
                             else
                               RequestType::RAW
                             end
      end

      def process_url
        return if @args.url.nil?
        unless @args.url =~ URI::regexp
          @args.url = "#{@args.default_scheme}://#{@args.url}"
        end
      end

      def guess_method
        if @args.method.nil?
          @args.method = @args.data ? HTTP_POST : HTTP_GET
        end
      end

      def process_auth
        return unless @args.auth

        if @args.auth.is_a?(ArgTypes::AuthCredentials)
          if !@args.auth.has_password? && @args.auth_type != 'bearer'
            @args.auth.prompt_password(URI(@args.url).host)
          end
        else
          @args.auth = ArgTypes.parse_auth(@args.auth)
        end
      end

      def process_output_options
        if @args.verbose
          @args.output_options ||= OUTPUT_OPTIONS.join
        elsif @args.output_options.nil?
          @args.output_options = if @args.stdout_isatty
                                   OUTPUT_OPTIONS_DEFAULT
                                 else
                                   OUTPUT_OPTIONS_DEFAULT_STDOUT_REDIRECTED
                                 end
        end
      end

      def parse_request_items
        request_items = RequestItems.from_args(
          request_item_args: @args.request_items,
          request_type: @args.request_type
        )
        @args.headers.merge!(request_items.headers)
        @args.data = request_items.data
        @args.files.merge!(request_items.files)
        @args.params.merge!(request_items.params)
      end
    end
  end
end