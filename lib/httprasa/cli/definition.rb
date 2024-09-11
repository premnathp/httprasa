require_relative '../version'
require_relative 'arg_types'
require_relative 'options'

module Httprasa
  module CLI
    class Definition
      include Options

      def self.parser_spec
        spec = ParserSpec.new(
          'httprasa',
          description: "#{Httprasa::DESCRIPTION.strip} <https://github.com/yourusername/httprasa>",
          epilog: "For every --OPTION there is also a --no-OPTION that reverts OPTION to its default value.\n\n" \
                  "Suggestions and bug reports are greatly appreciated:\n" \
                  "    https://github.com/yourusername/httprasa/issues",
          source_file: __FILE__
        )

        positional_arguments = spec.add_group(
          'Positional arguments',
          description: "These arguments come after any flags and in the order they are listed here.\n" \
                       "Only URL is required."
        )

        positional_arguments.add_argument(
          'method',
          nargs: Qualifiers::OPTIONAL,
          help: "The HTTP method to be used for the request (GET, POST, PUT, DELETE, ...).\n\n" \
                "This argument can be omitted in which case HTTPie will use POST if there\n" \
                "is some data to be sent, otherwise GET:\n\n" \
                "    $ httprasa example.org               # => GET\n" \
                "    $ httprasa example.org hello=world   # => POST"
        )

        positional_arguments.add_argument(
          'url',
          help: "The request URL. Scheme defaults to 'http://' if the URL does not include one."
        )

        # Add more argument groups and options here...

        spec.finalize
      end

      def self.parser
        spec = parser_spec
        Options.to_option_parser(spec)
      end
    end
  end
end