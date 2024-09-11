require 'json'
require 'uri'
require_relative 'constants'
require_relative 'cli/arg_types'
require_relative 'utils'
require_relative 'dicts'
require_relative 'nested_json'

module Httprasa
  class RequestItems
    attr_reader :headers, :data, :files, :params, :multipart_data

    def self.from_args(request_item_args:, request_type: nil)
      new(request_item_args, request_type)
    end

    def initialize(request_item_args, request_type)
      @request_type = request_type
      @is_json = request_type.nil? || request_type == RequestType::JSON
      @headers = HTTPHeadersDict.new
      @data = @is_json ? RequestJSONDataDict.new : RequestDataDict.new
      @files = RequestFilesDict.new
      @params = RequestQueryParamsDict.new
      @multipart_data = MultipartRequestDataDict.new

      parse_items(request_item_args)
    end

    private

    def parse_items(items)
      json_item_args, other_item_args = items.partition { |arg| arg.sep.in?(Constants::SEPARATOR_GROUP_NESTED_JSON_ITEMS) }

      if @is_json && !json_item_args.empty?
        pairs = json_item_args.map { |arg| [arg.key, process_item(arg)] }
        nested_json = process_data_nested_json_embed_args(pairs)
        @data.update(nested_json)
      end

      other_item_args.each do |arg|
        value = process_item(arg)

        if arg.sep.in?(Constants::SEPARATORS_GROUP_MULTIPART)
          @multipart_data[arg.key] = value
        end

        target_dict = case arg.sep
                      when Constants::SEPARATOR_HEADER, Constants::SEPARATOR_HEADER_EMPTY, Constants::SEPARATOR_HEADER_EMBED
                        @headers
                      when Constants::SEPARATOR_QUERY_PARAM, Constants::SEPARATOR_QUERY_EMBED_FILE
                        @params
                      when Constants::SEPARATOR_FILE_UPLOAD
                        @files
                      else
                        @data
                      end

        if target_dict.is_a?(BaseMultiDict)
          target_dict.add(arg.key, value)
        else
          target_dict[arg.key] = value
        end
      end
    end

    def process_item(arg)
      case arg.sep
      when Constants::SEPARATOR_HEADER
        process_header_arg(arg)
      when Constants::SEPARATOR_HEADER_EMPTY
        process_empty_header_arg(arg)
      when Constants::SEPARATOR_HEADER_EMBED
        process_embed_header_arg(arg)
      when Constants::SEPARATOR_QUERY_PARAM
        process_query_param_arg(arg)
      when Constants::SEPARATOR_QUERY_EMBED_FILE
        process_embed_query_param_arg(arg)
      when Constants::SEPARATOR_FILE_UPLOAD
        process_file_upload_arg(arg)
      when Constants::SEPARATOR_DATA_STRING
        process_data_item_arg(arg)
      when Constants::SEPARATOR_DATA_EMBED_FILE_CONTENTS
        process_data_embed_file_contents_arg(arg)
      when *Constants::SEPARATOR_GROUP_NESTED_JSON_ITEMS
        process_data_nested_json_embed_args([[arg.key, arg.value]])
      when Constants::SEPARATOR_DATA_RAW_JSON
        convert_json_value_to_form_if_needed(process_data_raw_json_embed_arg(arg))
      when Constants::SEPARATOR_DATA_EMBED_RAW_JSON_FILE
        convert_json_value_to_form_if_needed(process_data_embed_raw_json_file_arg(arg))
      else
        raise ParseError, "Unknown separator: #{arg.sep}"
      end
    end

    def process_header_arg(arg)
      arg.value || nil
    end

    def process_empty_header_arg(arg)
      arg.value.empty? ? arg.value : raise(ParseError, "Invalid item #{arg.orig.inspect} (to specify an empty header use `Header;`)")
    end

    def process_embed_header_arg(arg)
      load_text_file(arg).chomp
    end

    def process_query_param_arg(arg)
      arg.value
    end

    def process_embed_query_param_arg(arg)
      load_text_file(arg).chomp
    end

    def process_file_upload_arg(arg)
      parts = arg.value.split(Constants::SEPARATOR_FILE_UPLOAD_TYPE)
      filename = parts[0]
      mime_type = parts[1] if parts.size > 1
      begin
        f = File.open(File.expand_path(filename), 'rb')
      rescue SystemCallError => e
        raise ParseError, "#{arg.orig.inspect}: #{e.message}"
      end
      [File.basename(filename), f, mime_type || Utils.get_content_type(filename)]
    end

    def process_data_item_arg(arg)
      arg.value
    end

    def process_data_embed_file_contents_arg(arg)
      load_text_file(arg)
    end

    def process_data_embed_raw_json_file_arg(arg)
      contents = load_text_file(arg)
      load_json(arg, contents)
    end

    def process_data_raw_json_embed_arg(arg)
      load_json(arg, arg.value)
    end

    def process_data_nested_json_embed_args(pairs)
      NestedJSON.interpret_nested_json(pairs)
    end

    def convert_json_value_to_form_if_needed(value)
      return value if @is_json

      case value
      when String, Integer, Float
        value.to_s
      else
        raise ParseError, 'Cannot use complex JSON value types with --form/--multipart.'
      end
    end

    def load_text_file(item)
      path = item.value
      File.read(File.expand_path(path)).encode('UTF-8')
    rescue SystemCallError => e
      raise ParseError, "#{item.orig.inspect}: #{e.message}"
    rescue Encoding::UndefinedConversionError
      raise ParseError, "#{item.orig.inspect}: cannot embed the content of #{item.value.inspect}, not a UTF-8 or ASCII-encoded text file"
    end

    def load_json(arg, contents)
      JSON.parse(contents, object_class: Utils::OrderedHash)
    rescue JSON::ParserError => e
      raise ParseError, "#{arg.orig.inspect}: #{e.message}"
    end
  end
end