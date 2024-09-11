require 'ostruct'

module Httprasa
  module CLI
    module Options
      PARSER_SPEC_VERSION = '0.0.1a0'

      module Qualifiers
        OPTIONAL = :optional
        ZERO_OR_MORE = :zero_or_more
        ONE_OR_MORE = :one_or_more
        SUPPRESS = :suppress
      end

      class ParserSpec
        attr_reader :program, :description, :epilog, :groups, :man_page_hint, :source_file

        def initialize(program, description: nil, epilog: nil, man_page_hint: nil, source_file: nil)
          @program = program
          @description = description
          @epilog = epilog
          @groups = []
          @man_page_hint = man_page_hint
          @source_file = source_file
        end

        def finalize
          @description = @description&.strip
          @epilog = @epilog&.strip
          @groups.each(&:finalize)
          self
        end

        def add_group(name, **kwargs)
          group = Group.new(name, **kwargs)
          @groups << group
          group
        end

        def serialize
          {
            'name' => @program,
            'description' => @description,
            'groups' => @groups.map(&:serialize)
          }
        end
      end

      class Group
        attr_reader :name, :description, :is_mutually_exclusive, :arguments

        def initialize(name, description: '', is_mutually_exclusive: false)
          @name = name
          @description = description
          @is_mutually_exclusive = is_mutually_exclusive
          @arguments = []
        end

        def finalize
          @description = @description.strip if @description
        end

        def add_argument(*args, **kwargs)
          argument = Argument.new(args, kwargs)
          argument.post_init
          @arguments << argument
          argument
        end

        def serialize
          {
            'name' => @name,
            'description' => @description,
            'is_mutually_exclusive' => @is_mutually_exclusive,
            'args' => @arguments.map(&:serialize)
          }
        end
      end

      class Argument
        attr_reader :aliases, :configuration

        def initialize(aliases, configuration)
          @aliases = aliases
          @configuration = configuration
        end

        def post_init
          short_help = @configuration[:short_help]
          if short_help && !@configuration.key?(:help) && @configuration[:action] != :lazy_choices
            @configuration[:help] = "\n#{short_help}\n\n"
          end
        end

        def serialize(isolation_mode: false)
          config = @configuration.dup
          action = config.delete(:action)
          short_help = config.delete(:short_help)
          nested_options = config.delete(:nested_options)

          result = {}
          if @aliases.any?
            result['options'] = @aliases.dup
          else
            result['options'] = [config[:metavar]]
            result['is_positional'] = true
          end

          qualifiers = JSON_QUALIFIER_TO_OPTIONS[config[:nargs] || Qualifiers::SUPPRESS]
          result.merge!(qualifiers)

          description = config[:help]
          if description && description != Qualifiers::SUPPRESS
            result['short_description'] = short_help
            result['description'] = description
          end

          result['nested_options'] = nested_options if nested_options

          if config[:type]
            result['ruby_type_name'] = config[:type].name
          end

          JSON_DIRECT_MIRROR_OPTIONS.each do |key|
            result[key] = config[key] if config.key?(key) && config[key] != Qualifiers::SUPPRESS
          end

          result
        end

        def is_positional?
          @aliases.empty?
        end

        def is_hidden?
          @configuration[:help] == Qualifiers::SUPPRESS
        end

        def method_missing(method_name, *args)
          if @configuration.key?(method_name)
            @configuration[method_name]
          else
            super
          end
        end

        def respond_to_missing?(method_name, include_private = false)
          @configuration.key?(method_name) || super
        end
      end

      JSON_DIRECT_MIRROR_OPTIONS = %w[choices metavar]

      JSON_QUALIFIER_TO_OPTIONS = {
        Qualifiers::OPTIONAL => {'is_optional' => true},
        Qualifiers::ZERO_OR_MORE => {'is_optional' => true, 'is_variadic' => true},
        Qualifiers::ONE_OR_MORE => {'is_optional' => false, 'is_variadic' => true},
        Qualifiers::SUPPRESS => {}
      }

      def self.to_data(abstract_options)
        {
          'version' => PARSER_SPEC_VERSION,
          'spec' => abstract_options.serialize
        }
      end
    end
  end
end